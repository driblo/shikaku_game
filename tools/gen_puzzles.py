"""
Shikaku puzzle generator.
Usage: python tools/gen_puzzles.py
Outputs: assets/puzzles/{easy,medium,hard,expert}_pack.json
"""

import json
import random
import math
import os

DIFFICULTIES = {
    "easy":   {"rows": 5,  "cols": 5,  "count": 50, "par": 120, "min_area": 4, "max_area": 12},
    "medium": {"rows": 7,  "cols": 7,  "count": 50, "par": 240, "min_area": 4, "max_area": 20},
    "hard":   {"rows": 9,  "cols": 9,  "count": 50, "par": 480, "min_area": 4, "max_area": 36},
    "expert": {"rows": 11, "cols": 11, "count": 50, "par": 900, "min_area": 6, "max_area": 55},
}

ID_PREFIXES = {"easy": "e", "medium": "m", "hard": "h", "expert": "x"}


def valid_rect_area(w, h, rows, cols):
    return w * h


def can_express(area, rows, cols):
    for w in range(1, cols + 1):
        if area % w == 0:
            h = area // w
            if h <= rows:
                return True
    return False


def component_sizes(covered, rows, cols):
    """Return list of sizes of uncovered connected components."""
    visited = [[False] * cols for _ in range(rows)]
    sizes = []

    def bfs(sr, sc):
        size = 0
        queue = [(sr, sc)]
        visited[sr][sc] = True
        while queue:
            cr, cc = queue.pop()
            size += 1
            for nr, nc in ((cr - 1, cc), (cr + 1, cc), (cr, cc - 1), (cr, cc + 1)):
                if 0 <= nr < rows and 0 <= nc < cols and not covered[nr][nc] and not visited[nr][nc]:
                    visited[nr][nc] = True
                    queue.append((nr, nc))
        return size

    for r in range(rows):
        for c in range(cols):
            if not covered[r][c] and not visited[r][c]:
                sizes.append(bfs(r, c))
    return sizes


def generate_puzzle(rows, cols, min_area, max_area, rng):
    """
    Fills the grid by scanning top-left → bottom-right.
    Picks a random rectangle (weighted by area) subject to min_area / max_area.
    Returns None if we get stuck (caller should retry with different random state).
    Never falls back to small rectangles — enforces min_area strictly.
    """
    covered = [[False] * cols for _ in range(rows)]
    rectangles = []

    while True:
        # find first uncovered cell
        start = None
        for r in range(rows):
            for c in range(cols):
                if not covered[r][c]:
                    start = (r, c)
                    break
            if start:
                break
        if start is None:
            break

        r0, c0 = start

        # enumerate all axis-aligned rectangles anchored at top-left (r0, c0)
        all_rects = []
        for h in range(1, rows - r0 + 1):
            col_free = all(not covered[r0 + dh][c0] for dh in range(h))
            if not col_free:
                break
            for w in range(1, cols - c0 + 1):
                ok = True
                for dr in range(h):
                    for dc in range(w):
                        if covered[r0 + dr][c0 + dc]:
                            ok = False
                            break
                    if not ok:
                        break
                if not ok:
                    break
                area = w * h
                if not can_express(area, rows, cols):
                    continue
                all_rects.append((h, w, area))

        # filter to min/max area, also check no placement would strand a component < min_area
        candidates = []
        for h, w, area in all_rects:
            if area < min_area or area > max_area:
                continue
            # temporarily place and check connected components
            for dr in range(h):
                for dc in range(w):
                    covered[r0 + dr][c0 + dc] = True
            sizes = component_sizes(covered, rows, cols)
            for dr in range(h):
                for dc in range(w):
                    covered[r0 + dr][c0 + dc] = False
            if all(s == 0 or s >= min_area for s in sizes):
                candidates.append((h, w, area))

        if not candidates:
            return None  # stuck — caller retries

        # weight by area (prefer larger rectangles)
        weights = [c[2] for c in candidates]
        total = sum(weights)
        r_val = rng.random() * total
        chosen = candidates[-1]
        acc = 0
        for cand in candidates:
            acc += cand[2]
            if r_val <= acc:
                chosen = cand
                break

        h, w, _ = chosen
        r1, c1 = r0, c0
        r2, c2 = r0 + h - 1, c0 + w - 1

        for dr in range(h):
            for dc in range(w):
                covered[r1 + dr][c1 + dc] = True

        rectangles.append((r1, c1, r2, c2))

    return rectangles


def rect_to_clue(r1, c1, r2, c2, rows, cols, rng):
    """Pick a random interior cell of the rectangle as the clue position."""
    rr = rng.randint(r1, r2)
    cc = rng.randint(c1, c2)
    area = (r2 - r1 + 1) * (c2 - c1 + 1)
    return {"r": rr, "c": cc, "v": area}


def generate_pack(difficulty, cfg, seed=42):
    rows, cols = cfg["rows"], cfg["cols"]
    min_area, max_area = cfg["min_area"], cfg["max_area"]
    count, par = cfg["count"], cfg["par"]
    prefix = ID_PREFIXES[difficulty]
    rng = random.Random(seed)

    puzzles = []
    attempts = 0
    while len(puzzles) < count:
        attempts += 1
        if attempts > count * 200:
            raise RuntimeError(f"Too many attempts for {difficulty}")
        rects = generate_puzzle(rows, cols, min_area, max_area, rng)
        if rects is None:
            continue
        total = sum((r2 - r1 + 1) * (c2 - c1 + 1) for r1, c1, r2, c2 in rects)
        if total != rows * cols:
            continue
        n = len(puzzles) + 1
        clues = [rect_to_clue(*r, rows, cols, rng) for r in rects]
        puzzles.append({
            "id": f"{prefix}{n:02d}",
            "rows": rows,
            "cols": cols,
            "parSeconds": par,
            "clues": clues,
        })

    return {
        "packId": f"{difficulty}_v1",
        "difficulty": difficulty,
        "puzzles": puzzles,
    }


def validate_pack(pack):
    rows = pack["puzzles"][0]["rows"]
    cols = pack["puzzles"][0]["cols"]
    expected = rows * cols
    errors = []
    for p in pack["puzzles"]:
        total = sum(c["v"] for c in p["clues"])
        if total != expected:
            errors.append(f"{p['id']}: sum={total} expected={expected}")
        for c in p["clues"]:
            if not can_express(c["v"], rows, cols):
                errors.append(f"{p['id']}: clue v={c['v']} not expressible")
    return errors


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "puzzles")
    os.makedirs(out_dir, exist_ok=True)

    for diff, cfg in DIFFICULTIES.items():
        print(f"Generating {diff}...", end=" ", flush=True)
        pack = generate_pack(diff, cfg, seed=2025)
        errors = validate_pack(pack)
        if errors:
            print("ERRORS:")
            for e in errors:
                print("  ", e)
        else:
            counts = [len(p["clues"]) for p in pack["puzzles"]]
            print(
                f"{len(pack['puzzles'])} puzzles, "
                f"clues/puzzle: min={min(counts)} avg={sum(counts)//len(counts)} max={max(counts)}"
            )
        path = os.path.join(out_dir, f"{diff}_pack.json")
        with open(path, "w") as f:
            json.dump(pack, f, separators=(",", ":"))


if __name__ == "__main__":
    main()
