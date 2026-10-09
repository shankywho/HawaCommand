import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/error_view.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/core/widgets/stale_banner.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';
import 'package:hawa_app/features/site/application/site_score_controller.dart';
import 'package:hawa_app/features/site/domain/site_score.dart';
import 'package:hawa_app/features/site/presentation/widgets/grade_badge.dart';
import 'package:hawa_app/features/site/presentation/widgets/pm10_trend_chart.dart';
import 'package:hawa_app/features/site/presentation/widgets/site_labels.dart';

/// M1 Site score (`/site`, site manager, read-only VISION screen).
class SiteScoreScreen extends ConsumerWidget {
  const SiteScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(siteScoreControllerProvider);
    final controller = ref.read(siteScoreControllerProvider.notifier);
    final snapshot = s.snapshot;

    final Widget body;
    if (snapshot != null) {
      body = Column(
        children: [
          if (s.refreshing) const LinearProgressIndicator(minHeight: 2),
          FreshnessBanner(
            lastSuccess: snapshot.fetchedAt,
            staleAfter: SiteScoreController.staleAfter,
            error: s.error,
            onRetry: controller.refresh,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: _SiteBody(site: snapshot.site),
            ),
          ),
        ],
      );
    } else if (s.error != null && !s.refreshing && s.cacheLoaded) {
      body = s.noSite
          ? EmptyState(
              icon: Icons.apartment,
              message: l.siteNone,
              action: OutlinedButton.icon(
                onPressed: controller.refresh,
                icon: const Icon(Icons.refresh),
                label: Text(l.commonRetry),
              ),
            )
          : ErrorView(error: s.error!, onRetry: controller.refresh);
    } else {
      body = const LoadingSkeleton();
    }

    return Scaffold(
      appBar: ShellAppBar(title: l.siteTitle),
      body: body,
    );
  }
}

class _SiteBody extends StatelessWidget {
  const _SiteBody({required this.site});

  final SiteScore site;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.lang;
    final theme = Theme.of(context);
    final c = context.hawaColors;
    final place = site.placeName?.of(lang);
    final trend = site.trendWithValues;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (site.isSimulated) const SimulatedScreenChip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place == null ? site.siteId : '${site.siteId}, $place',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${site.type.label(l)} · ${site.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: c.mutedForeground),
                  ),
                  if (site.isSimulated) const SimulatedBadge(),
                ],
              ),
            ],
          ),
        ),
        _Section(
          child: Row(
            children: [
              GradeBadge(grade: site.grade),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gradeLine(l, site, lang), style: theme.textTheme.titleMedium),
                    if (site.score != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l.siteScore(site.score!.round().toString()),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.siteTrend, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (trend.length < 2)
                Text(l.siteNoTrend, style: theme.textTheme.bodyMedium)
              else ...[
                Pm10TrendChart(points: trend, summary: _summary(l, trend)),
                const SizedBox(height: 8),
                Text(_summary(l, trend), style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        _Note(icon: Icons.trending_up, text: l.siteIncentive),
        _Note(icon: Icons.info_outline, text: l.siteNotLegal, muted: true),
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Fact(
                icon: Icons.fact_check,
                text: site.lastInspectionAt == null
                    ? l.siteNoInspection
                    : l.siteLastInspection(IstTime.shortDate(site.lastInspectionAt!, lang)),
              ),
              if (site.violations != null)
                _Fact(icon: Icons.gavel, text: l.siteViolations('${site.violations}')),
              if (site.flags30d != null)
                _Fact(icon: Icons.flag_outlined, text: l.siteFlags('${site.flags30d}')),
            ],
          ),
        ),
        if (site.components.isNotEmpty)
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.siteBreakdown, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final comp in site.components)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(_localized(l, comp.label, lang) ?? comp.name)),
                        const SizedBox(width: 12),
                        Text(
                          _number(comp.value),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (site.tips.isNotEmpty)
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.siteTips, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final tip in site.tips)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20, color: c.brandText),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_localized(l, tip, lang)!)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _summary(AppLocalizations l, List<SitePm10Point> trend) =>
      l.siteTrendSummary('${trend.first.pm10P50!.round()}', '${trend.last.pm10P50!.round()}');

  /// Server text in the UI language; English-only text is marked "(in English)".
  static String? _localized(AppLocalizations l, LocalizedText? t, String lang) {
    if (t == null) return null;
    final text = t.of(lang);
    return t.isEnglishFallback(lang) ? '$text ${l.commonInEnglish}' : text;
  }

  static String _number(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.outdoor ? c.ink : c.border, width: c.borderWidth),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.muted = false});

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: muted ? c.mutedForeground : c.foreground,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: muted ? c.mutedForeground : c.brandText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.hawaColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
