import 'package:hawa_app/features/driver_route/data/task_event_applier.dart';
import 'package:hawa_app/features/driver_route/domain/auto_done_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_done_events.g.dart';

/// One-shot auto-done events for the overlay, haptics and the hero advance (ARCHITECTURE §4:
/// one-shot effects go through event providers, never state flags).
@riverpod
Stream<AutoDoneEvent> autoDoneEvents(Ref ref) => ref.watch(taskEventApplierProvider).autoDone;
