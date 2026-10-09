import 'package:flutter_test/flutter_test.dart';
import 'package:hawa_app/features/driver_route/domain/route_diff.dart';
import 'package:hawa_app/features/driver_route/domain/skip_reason.dart';

void main() {
  group('RouteDiff.between', () {
    test('same list → empty', () {
      expect(RouteDiff.between(['a', 'b'], ['a', 'b']).isEmpty, isTrue);
    });

    test('added, removed (incl. cancelled) and reordered', () {
      final d = RouteDiff.between(['a', 'b', 'c'], ['c', 'a', 'd', 'b'], cancelledAfter: {'b'});
      expect(d.added, {'d'});
      expect(d.removed, {'b'});
      expect(d.reordered, isTrue);
    });
  });

  group('SkipReason', () {
    test('only "other" needs a note; unknown wire values are tolerated', () {
      expect(SkipReason.other.needsNote, isTrue);
      expect(SkipReason.roadBlocked.needsNote, isFalse);
      expect(SkipReason.fromWire('teleported'), SkipReason.unknown);
      expect(SkipReason.choices, hasLength(6));
    });
  });
}
