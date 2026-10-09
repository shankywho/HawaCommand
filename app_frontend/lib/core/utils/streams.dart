import 'dart:async';

/// Emits [combine] of the latest values of [a] and [b] once both have emitted (like
/// rxdart's combineLatest2, without the dependency).
Stream<R> combineLatest2<A, B, R>(Stream<A> a, Stream<B> b, R Function(A, B) combine) {
  late StreamController<R> controller;
  StreamSubscription<A>? sa;
  StreamSubscription<B>? sb;
  A? lastA;
  B? lastB;
  var hasA = false;
  var hasB = false;
  void emit() {
    if (hasA && hasB) controller.add(combine(lastA as A, lastB as B));
  }

  controller = StreamController<R>(
    onListen: () {
      sa = a.listen((v) {
        lastA = v;
        hasA = true;
        emit();
      }, onError: controller.addError);
      sb = b.listen((v) {
        lastB = v;
        hasB = true;
        emit();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await sa?.cancel();
      await sb?.cancel();
    },
  );
  return controller.stream;
}
