import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/sync/stale_policy.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/features/site/data/site_repository_impl.dart';
import 'package:hawa_app/features/site/domain/site_score.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'site_score_controller.freezed.dart';
part 'site_score_controller.g.dart';

/// What the site screen renders (SCREENS M1, §0.1 states).
@freezed
abstract class SiteScoreState with _$SiteScoreState {
  const factory SiteScoreState({
    /// The cached site, null until the first successful fetch.
    SiteSnapshot? snapshot,

    /// The cache has been read at least once (null snapshot then means "nothing cached").
    @Default(false) bool cacheLoaded,
    @Default(false) bool refreshing,

    /// The last refresh failure (a typed `Failure`), cleared by a successful refresh.
    Object? error,
  }) = _SiteScoreState;

  const SiteScoreState._();

  /// `404`: no site is linked to this account.
  bool get noSite => error is NotFoundFailure;
}

/// Stale-while-revalidate: renders the cached site, refreshes on open and on every sync trigger.
@riverpod
class SiteScoreController extends _$SiteScoreController {
  /// OFFLINE_AND_SYNC §2: the site score is stale after 24 h.
  static const Duration staleAfter = StalePolicy.site;

  @override
  SiteScoreState build() {
    final repo = ref.watch(siteRepositoryProvider);
    final sub = repo.watch().listen(
      (snapshot) => state = state.copyWith(snapshot: snapshot, cacheLoaded: true),
      onError: (Object e) => state = state.copyWith(cacheLoaded: true, error: e),
    );
    ref
      ..onDispose(() => unawaited(sub.cancel()))
      ..listen(syncTriggersProvider, (_, _) => unawaited(refresh()));
    unawaited(Future.microtask(refresh));
    return const SiteScoreState();
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = state.copyWith(refreshing: true);
    Object? error;
    try {
      await ref.read(siteRepositoryProvider).refresh();
    } on Object catch (e) {
      error = e;
    }
    if (!ref.mounted) return;
    state = state.copyWith(refreshing: false, error: error);
  }
}
