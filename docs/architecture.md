# Shikaku — Architecture & Development Plan

## 0. Assumptions (state-and-proceed)

| Dimension | Decision | Rationale |
|---|---|---|
| Genre | Puzzle / logic (turn-based, no real-time loop) | Shikaku is a static-grid Nikoli puzzle |
| Engine | **Flutter** (Dart) | Your existing mobile stack; ideal for grid + custom-paint UI, no physics needed |
| Platform | iOS + Android (single codebase) | Flutter cross-platform |
| Team | Solo | Architecture kept lean, no over-engineering |
| Monetization | Premium-feel, **ad-free**, optional donation | Aligns with mandatory "Support our work" page |
| Multiplayer | None (optional async leaderboard later) | Single-player logic puzzle |

Redirect me if engine ≠ Flutter; the system design below is mostly engine-agnostic but folder layout and library picks are Flutter-specific.

---

## 1. Game definition (grounding the model)

Shikaku: an `R×C` grid; some cells hold a number. The player partitions the **entire** grid into axis-aligned rectangles such that:

1. Every rectangle contains exactly **one** numbered cell.
2. A rectangle's area (cell count) equals its number.
3. Rectangles don't overlap and cover every cell.

A valid puzzle has **exactly one** solution. This single constraint — uniqueness — is the hardest engineering problem in the project and drives the generator/solver design.

---

## 2. Architecture pattern

Per the puzzle-genre playbook: **MVC + Command pattern**, expressed in Flutter idiom as:

- **Model**: pure Dart, zero Flutter imports — `Board`, `Region`, `Puzzle`, solver, generator. Fully unit-testable, runnable in an isolate.
- **ViewModel**: `ChangeNotifier` (or Riverpod `Notifier`) holding the live puzzle state, exposing intent methods (`beginDrag`, `commitRect`, `undo`, `hint`).
- **View**: `CustomPainter`-based board widget + screen scaffolding. Stateless beyond the VM.
- **Command stack**: every board mutation is a `Command` (do/undo) — backbone of undo/redo, replay, and hint application.

No continuous game loop. The "loop" is event-driven: gesture → command → model recompute → targeted repaint. Flag: do **not** spin a `Ticker`/render loop for a static puzzle — it wastes battery for zero benefit.

---

## 3. Core systems

### 3.1 Board & Region model
- `Board`: `R×C`, two parallel maps — `cellToRegionId[r][c]` and `regions: Map<int, Region>`.
- `Region`: `id`, anchor `(r,c)` of its number, `value`, rect bounds. Invariant checks: single anchor, area == value, no overlap, full coverage.
- `Puzzle`: immutable givens (grid size + clue positions/values) + cached canonical solution.

### 3.2 Generator (hardest component)
1. Random rectangle partition of the full grid (recursive split or greedy fill with backtracking).
2. Place one clue per rectangle (random interior cell, value = area).
3. Run the solver to count solutions; **accept only if exactly one**.
4. If non-unique, perturb (merge/resplit adjacent rectangles) and retry; cap attempts, fall back to a new seed.
5. Difficulty rating = function of solver's deduction depth (forced-move chains vs. required guesses) and clue density.

Runs in a **background isolate** (`compute()`), never on the UI thread. Used both at build time (to bake puzzle packs) and optionally on-device for an "endless" mode.

### 3.3 Solver / validator
A single backtracking / exact-cover solver serves three roles:
- Generator uniqueness check (count solutions, early-exit at 2).
- Live validation of the player's partition (win detection).
- Hint engine: find the next forced placement the solver would deduce.

### 3.4 Input system
- `GestureDetector` `onPanStart/Update/End`. Drag begins on (or near) a clue, drags to opposite corner, snaps to grid.
- Live overlay rectangle with state colors: valid / overlapping / wrong-area / no-clue / multi-clue.
- Tap a finished region to clear it. Long-press = quick-clear.
- Touch targets respect grid scaling; tested on small screens.

### 3.5 Screen / scene management
State machine, not ad-hoc navigation:

```
Boot(splash) → MainMenu → LevelSelect → Game ⇄ Pause
                                   └→ Win → (next | LevelSelect)
                  └→ Settings → {Language, Support, OSS Licenses}
```

Flutter `Navigator` with named/typed routes; `Game ⇄ Pause` overlays without tearing down board state.

### 3.6 Save / persistence
- **Volatile**: in-progress region layout per active puzzle (resume mid-puzzle).
- **Persistent**: completion + star/best-time per puzzle id, unlocked episodes, settings, chosen locale.
- Storage: `shared_preferences` for settings/locale; a versioned JSON file via `path_provider` for progress (`saveVersion` field for migrations). `sqflite` only if puzzle count grows large. Save on `commitRect`, `undo`, and on `AppLifecycleState.paused`.

### 3.7 Audio
- Single `AudioService`; pooled SFX (place, clear, win, error). Optional ambient track on its own channel with independent mute.
- Honor system mute and audio interruptions (call/notification) — pause/resume via lifecycle observer.

### 3.8 Data / config
- Puzzle packs as bundled JSON assets, **lazy-loaded per episode** (don't load all packs into memory — the standard puzzle pitfall).
- Pack schema:
```json
{
  "packId": "ep1",
  "difficulty": "easy",
  "puzzles": [
    { "id": "ep1_p1", "rows": 7, "cols": 7,
      "clues": [{"r":0,"c":1,"v":4}, {"r":2,"c":5,"v":6}],
      "parSeconds": 90 }
  ]
}
```
- Difficulty/balance lives in data, never hardcoded.

### 3.9 Progression & hints
- `ProgressionManager`: stars (e.g. by time/no-hint), episode unlock gate, completion %.
- `HintManager`: reveals one solver-deduced region; cooldown or capped count per puzzle (currency-free to start).

---

## 4. Folder structure (Flutter)

```
lib/
├── main.dart                 # bootstrap, locale init, NO immersive mode
├── app.dart                  # MaterialApp, routes, localization delegates
├── core/
│   ├── events.dart           # lightweight event bus / typed callbacks
│   ├── service_locator.dart
│   └── lifecycle_observer.dart
├── model/                    # pure Dart, no Flutter imports
│   ├── board.dart
│   ├── region.dart
│   ├── puzzle.dart
│   ├── generator.dart        # runs in isolate
│   ├── solver.dart
│   └── commands/             # Command pattern (PlaceRect, ClearRect …)
├── services/
│   ├── puzzle_repository.dart  # loads/caches packs (lazy per episode)
│   ├── save_service.dart
│   ├── audio_service.dart
│   └── progression_service.dart
├── viewmodel/
│   ├── game_view_model.dart    # ChangeNotifier + command stack
│   └── settings_view_model.dart
├── ui/
│   ├── screens/              # splash, menu, level_select, game,
│   │                         #   pause, win, settings, support, licenses
│   ├── board/
│   │   ├── board_painter.dart   # CustomPainter, wrapped in RepaintBoundary
│   │   └── board_widget.dart    # GestureDetector + painter
│   └── widgets/              # reusable: language_picker, etc.
├── l10n/                     # app_en.arb … app_vi.arb  (25 files)
└── assets/
    └── puzzles/              # ep1.json, ep2.json, …

l10n.yaml                     # arb-dir, template, output config
pubspec.yaml                  # generate: true; deps below
```

---

## 5. Core classes (single responsibility)

| Class | Responsibility |
|---|---|
| `Board` | Grid state, region map, invariant checks |
| `Region` | One rectangle: bounds, clue, area validation |
| `Puzzle` | Immutable givens + cached solution |
| `ShikakuSolver` | Deduce / count solutions, next-forced-move for hints |
| `ShikakuGenerator` | Produce unique-solution puzzles (isolate) |
| `Command` (+ subclasses) | Reversible board mutation |
| `CommandStack` | Undo/redo history |
| `GameViewModel` | Orchestrates input intent → command → notify |
| `PuzzleRepository` | Lazy pack loading + cache |
| `SaveService` | Versioned persistence |
| `ProgressionService` | Stars, unlocks, stats |
| `HintManager` | Hint gating + solver query |
| `AudioService` | Pooled SFX/music, interruption handling |
| `BoardPainter` | Pure render of board + drag overlay |

---

## 6. Data flow — one player move

```
Pan gesture (drag a clue to a corner)
        │
        ▼
BoardWidget → GameViewModel.commitRect(rect)
        │
        ▼
PlaceRectCommand.execute()  →  Board mutate  →  invariant check
        │                                          │
        ▼                                          ▼
CommandStack.push()                       if board complete:
        │                                  ShikakuSolver.validate() → Win
        ▼
notifyListeners()  →  RepaintBoundary(BoardPainter) repaints only the board
        │
        ▼
SaveService.persist()  (debounced)  +  AudioService.play(place)
```

Heavy work (generate/validate full solve) is dispatched to an isolate so the gesture stays at 60 fps.

---

## 7. Mandatory features — wiring (all six apply)

1. **Localization, 25 locales** — `lib/l10n/app_<code>.arb` for: ar, bn, zh, cs, en, fr, de, hi, hu, id, it, ja, ko, mr, fa, pl, pt, ru, sk, es, ta, tr, uk, ur, vi. `en` is source of truth; missing keys fall back to en. Language picker lists **native names, alphabetical by English name**. RTL handled for ar/fa/ur via Flutter `Directionality` (automatic with `supportedLocales`).
2. **i18n scaffolded day one** — `intl` + `flutter_localizations`, `generate: true`, `l10n.yaml` configured before any screen is built. Every visible string goes through `AppLocalizations.of(context)!`; zero inline strings, even placeholders. Device-locale detect on first launch → nearest supported → persisted override in Settings.
3. **Never true fullscreen** — `main.dart` must **not** call `SystemChrome.setEnabledSystemUIMode(immersive/immersiveSticky/leanBack)`. Use edge-to-edge with `SafeArea`; board draws under bars with proper insets, system bottom bar stays visible and tappable on every screen including Game.
4. **"Support our work" in Settings** — Settings row label = `settingsSupportLink` ("Support our work") → pushes a `SupportScreen` (in-app route, not browser/modal) whose body = `supportHeadline` ("Support our work to keep this app without ads"), with the donation mechanism below it. Both strings pre-translated for all 25 locales (use the skill's `support-strings.md` table verbatim).
5. **Splash with slogan** — real native splash via `flutter_native_splash` (not a Dart-rendered first frame). Shows logo **plus slogan**. Slogan (English / `en` source): **"Shikaku no ads game"**. Stored as l10n key `splashSlogan`, must be translated for all 25 locales (still routed through the l10n layer even though short); on-screen 1–2 s. Note: `flutter_native_splash` renders a static image at the OS level, so the localized slogan is shown either by (a) baking the English slogan into the native splash asset and showing the localized `splashSlogan` on the first Dart frame for non-en devices, or (b) keeping the native splash logo-only and rendering the localized slogan immediately on handoff. Recommend (b) for clean per-locale text.
6. **OSS licenses sub-page** — nearly free in Flutter: Settings row `settingsOpenSourceLicenses` ("Open source licenses") calls `showLicensePage(context: context, applicationName: 'Shikaku')`; Flutter auto-aggregates from `pubspec.lock`, works offline. Entry label + page title localized; license bodies stay English.

`pubspec.yaml` deps to commit on day one: `flutter_localizations`, `intl`, `flutter_native_splash`, `shared_preferences`, `path_provider`, plus state mgmt (`flutter_riverpod` or built-in `ChangeNotifier`) and `audioplayers`/`just_audio`.

---

## 8. Mobile-specific concerns

- **Frame rate / battery**: event-driven repaint only; `RepaintBoundary` around the board so menus/HUD don't repaint on drag. No render loop. This is a low-power game by nature — keep it that way.
- **Memory**: lazy-load packs per episode; release non-active packs. Trivial RAM budget for a grid puzzle — main risk is loading all puzzles at once (don't).
- **Lifecycle**: `WidgetsBindingObserver`; on `paused` immediately persist in-progress layout and pause audio; resume restores exact board, not a restart.
- **Isolates**: generation and full-grid uniqueness solving go through `compute()` — never block the UI thread, especially on budget Android devices.
- **Platform**: test rectangle-drag touch targets on small/old devices; verify RTL mirroring on ar/fa/ur; AAB for Play Store, real-device test (not just emulator).

---

## 9. Monetization architecture

Premium-feel, **no ads** (consistent with feature #4). Simplest viable: free with an optional one-tap donation / "buy me a coffee" or a single non-consumable IAP "supporter pack" (extra puzzle packs / cosmetic board themes). If IAP: thin `EntitlementService`, restore-purchases support, store-difference abstraction (e.g. `in_app_purchase` plugin). No server, no economy, no real-money loop to validate — keep it minimal.

---

## 10. Risks & tradeoffs

| Risk | Mitigation |
|---|---|
| **Unique-solution generation is genuinely hard** | Generate → solver-verify-unique → perturb-retry; bake curated packs offline so shipping isn't blocked on a perfect runtime generator |
| Solver performance on large grids | Constraint-propagation + early exit at 2 solutions; cap grid size per difficulty; isolate execution |
| Drag UX ambiguity (overlaps, mis-snaps) | Live color-coded overlay + commit-only-on-valid; cheap undo |
| i18n retrofit pain | Scaffolded before first screen (non-negotiable per feature #2) |
| Save schema churn | `saveVersion` field + migration step from day one |
| Over-engineering a simple game | No DI framework, no ECS, no game loop — MVC + Command only |

**Deferrable**: on-device endless generator (ship with baked packs first), async leaderboard, board themes/IAP, daily-puzzle mode.

---

## 11. Build phases

1. **Scaffold**: project, `l10n.yaml`, 25 ARB stubs, native splash, Settings shell (Language / Support / OSS rows), no-immersive bootstrap, lifecycle observer. *(Mandatory features land here, before gameplay.)*
2. **Model + solver**: `Board`/`Region`/`Puzzle`, backtracking solver with uniqueness count, full unit tests.
3. **Generator** (isolate) → bake a small validated pack; difficulty rating.
4. **Board UI**: `CustomPainter` + gesture drawing, command stack, undo/redo.
5. **Game flow**: level select, win detection, stars, progression, save/resume.
6. **Polish**: hints, audio, haptics, themes; pseudo-localization pass to catch hardcoded strings; on-device endless mode (optional).

---

## 12. Mandatory features check

```
Mandatory features check:
- [x] Localization scaffolded (25 locales, alphabetical, RTL for ar/fa/ur)
- [x] Strings go through translation layer (intl/ARB, en source of truth)
- [x] System bottom bar stays visible (no immersive/fullscreen; edge-to-edge + SafeArea)
- [x] Settings → "Support our work" link wired up (in-app SupportScreen, fixed strings)
- [x] Splash screen shows slogan — "Shikaku no ads game" (key: splashSlogan, translate to all 25)
- [x] Settings → "Open source licenses" sub-page (Flutter showLicensePage, auto-generated)
```

---

**No blockers.** Slogan locked ("Shikaku no ads game" → `splashSlogan`, pending translation to the other 24 locales). All six mandatory features are specced into Phase 1; ready to build.
