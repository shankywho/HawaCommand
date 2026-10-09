import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conflict_banner_bus.g.dart';

/// What the user is told after a conflict was resolved (OFFLINE_AND_SYNC §7).
enum ConflictKind {
  /// Manual done not needed: HawaTag already confirmed the stop.
  tagAlreadyDone,

  /// Skip not needed: the stop was completed by HawaTag.
  skipNotNeeded,

  /// The control room removed this stop from the route.
  stopRemoved,

  /// The inspection was already closed; the late evidence was attached.
  caseClosed,
}

class ConflictNotice {
  const ConflictNotice({required this.kind, required this.entityId, required this.at});

  final ConflictKind kind;
  final String entityId;
  final DateTime at;
}

/// Resolved-conflict notices for the UI. Each stays until dismissed.
@Riverpod(keepAlive: true)
class ConflictBannerBus extends _$ConflictBannerBus {
  @override
  List<ConflictNotice> build() => const [];

  void publish(ConflictNotice notice) {
    if (state.any((n) => n.kind == notice.kind && n.entityId == notice.entityId)) return;
    state = [...state, notice];
  }

  void dismiss(ConflictNotice notice) => state = [
    for (final n in state)
      if (!identical(n, notice)) n,
  ];
}
