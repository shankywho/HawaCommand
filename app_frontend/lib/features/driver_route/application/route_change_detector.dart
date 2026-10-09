import 'package:hawa_app/features/driver_route/domain/route_diff.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_change_detector.g.dart';

/// The last route change to announce ("Route changed: 1 added, 1 removed"), until dismissed.
@Riverpod(keepAlive: true)
class RouteChangeNotice extends _$RouteChangeNotice {
  @override
  RouteDiff? build() => null;

  void show(RouteDiff diff) {
    if (!diff.isEmpty) state = diff;
  }

  void dismiss() => state = null;
}
