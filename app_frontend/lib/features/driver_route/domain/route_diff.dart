/// What changed between two versions of a route (re-plans at 08:00 / 11:00 / 14:00 IST).
class RouteDiff {
  const RouteDiff({this.added = const {}, this.removed = const {}, this.reordered = false});

  /// Pure diff of two ordered task-id lists (cancelled stops count as removed).
  factory RouteDiff.between(
    List<String> before,
    List<String> after, {
    Set<String> cancelledAfter = const {},
  }) {
    final b = before.toSet();
    final a = after.where((id) => !cancelledAfter.contains(id)).toSet();
    final added = a.difference(b);
    final removed = b.difference(a);
    final keptBefore = before.where(a.contains).toList();
    final keptAfter = after.where((id) => b.contains(id) && !cancelledAfter.contains(id)).toList();
    var reordered = false;
    for (var i = 0; i < keptBefore.length && i < keptAfter.length; i++) {
      if (keptBefore[i] != keptAfter[i]) {
        reordered = true;
        break;
      }
    }
    return RouteDiff(added: added, removed: removed, reordered: reordered);
  }

  final Set<String> added;
  final Set<String> removed;
  final bool reordered;

  bool get isEmpty => added.isEmpty && removed.isEmpty && !reordered;
}
