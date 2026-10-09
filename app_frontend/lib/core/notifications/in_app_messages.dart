import 'package:hawa_app/core/notifications/push_payload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_messages.g.dart';

/// Foreground pushes shown as an in-app banner instead of a system notification
/// (ARCHITECTURE §10.2). The newest is shown; tapping routes like a notification tap.
@Riverpod(keepAlive: true)
class InAppMessages extends _$InAppMessages {
  @override
  List<PushPayload> build() => const [];

  void show(PushPayload payload) => state = [payload, ...state.take(2)];

  void dismiss(PushPayload payload) => state = [
    for (final p in state)
      if (!identical(p, payload)) p,
  ];
}
