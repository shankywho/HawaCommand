/// A stop completed by HawaTag (WS `task.done` with `source=hawatag`): big tick, haptics, the hero
/// advances (SCREENS D1).
class AutoDoneEvent {
  const AutoDoneEvent({required this.taskId, required this.sequence, this.litres});

  final String taskId;
  final int sequence;
  final double? litres;
}
