import 'dart:math';

/// Exponential backoff with full jitter (OFFLINE_AND_SYNC §5.4): base 2 s, cap 15 min.
/// A server `Retry-After` longer than the jittered delay wins.
Duration nextDelay(int attempts, {Duration? retryAfter, Random? rng}) {
  const base = Duration(seconds: 2);
  const cap = Duration(minutes: 15);
  final exp = base * pow(2, min(attempts, 10)).toInt();
  final ceiling = exp > cap ? cap : exp;
  final jittered = Duration(milliseconds: (rng ?? Random()).nextInt(ceiling.inMilliseconds + 1));
  return retryAfter != null && retryAfter > jittered ? retryAfter : jittered;
}
