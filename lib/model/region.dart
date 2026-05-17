class Region {
  final int r1, c1, r2, c2;

  const Region({
    required this.r1,
    required this.c1,
    required this.r2,
    required this.c2,
  });

  int get area => (r2 - r1 + 1) * (c2 - c1 + 1);

  bool contains(int r, int c) => r >= r1 && r <= r2 && c >= c1 && c <= c2;

  bool overlaps(Region o) =>
      r1 <= o.r2 && r2 >= o.r1 && c1 <= o.c2 && c2 >= o.c1;
}
