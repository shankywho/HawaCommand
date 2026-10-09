import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/utils/aqi.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/confidence_chip.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/core/widgets/stale_banner.dart';
import 'package:hawa_app/features/school/application/school_controllers.dart';
import 'package:hawa_app/features/school/domain/school_models.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';

/// Advice copy (server-computed `ClassroomAdvice`; the app never derives it).
(IconData, String, String?) adviceCopy(ClassroomAdvice a, AppLocalizations l) => switch (a) {
  ClassroomAdvice.seal => (Icons.sensor_window_outlined, l.schoolShut, l.schoolShutWhy),
  ClassroomAdvice.ventilate => (Icons.air, l.schoolVentilate, l.schoolVentilateWhy),
  _ => (Icons.check_circle_outline, l.schoolNormal, null),
};

/// S1 Today (`/school`): "when is it safe outdoors": safe windows today/tomorrow with confidence,
/// the 8 AM value with its P10–P90 range, classroom advice, and the GRAP outlook.
class SchoolTodayScreen extends ConsumerWidget {
  const SchoolTodayScreen({this.date, super.key});

  /// From a `safe_window` push (`?date=`): scrolls the right day into view.
  final String? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final school = ref.watch(schoolInfoProvider).value;
    final today = ref.watch(serviceDateProvider);
    final tomorrow = IstTime.addDays(today, 1);
    final todayW = ref.watch(safeWindowDayProvider(today)).value;
    final tomorrowW = ref.watch(safeWindowDayProvider(tomorrow)).value;
    final io = ref.watch(indoorOutdoorProvider).value;
    final grap = ref.watch(grapOutlookProvider).value ?? const [];
    final error = ref.watch(schoolRefreshProvider);
    final fetchedAt = ref.watch(schoolFetchedAtProvider).value;

    if (school == null) {
      return Scaffold(
        appBar: ShellAppBar(title: l.schoolSafeTitle),
        body: const LoadingSkeleton(),
      );
    }
    final morning = todayW?.morning;
    final advice = todayW?.advice ?? io?.advice ?? ClassroomAdvice.unknown;
    final (adviceIcon, adviceTitle, adviceWhy) = adviceCopy(advice, l);
    final nextStage = grap.where((g) => g.stage >= 3).firstOrNull ?? grap.firstOrNull;

    Widget dayRow(String label, SafeWindowDay? d) {
      final windows = d?.safe ?? const <SafeWindow>[];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Text(label, style: text.titleSmall)),
            Expanded(
              child: d == null
                  ? Text(
                      l.schoolNoIssue,
                      style: text.bodyMedium?.copyWith(color: c.mutedForeground),
                    )
                  : windows.isEmpty
                  ? Text(l.schoolNone, style: text.bodyMedium?.copyWith(color: c.dangerText))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final w in windows) ...[
                          Text(
                            l.schoolWindow(
                              IstTime.time(w.start, context.lang),
                              IstTime.time(w.end, context.lang),
                              ConfidenceLevel.of(w.confidence).label(l).toLowerCase(),
                            ),
                            style: text.bodyLarge,
                          ),
                          if (w.label == 'borderline')
                            Text(
                              l.schoolBorderline,
                              style: text.bodySmall?.copyWith(color: c.warningText),
                            ),
                        ],
                        if (!d.isFinal)
                          Text(
                            l.schoolDraft,
                            style: text.bodySmall?.copyWith(color: c.mutedForeground),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: ShellAppBar(title: school.name.of(context.lang)),
      body: RefreshIndicator(
        onRefresh: ref.read(schoolRefreshProvider.notifier).refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (school.isSimulated) const SimulatedScreenChip(),
            FreshnessBanner(
              lastSuccess: fetchedAt,
              staleAfter: const Duration(hours: 1),
              error: error,
              onRetry: ref.read(schoolRefreshProvider.notifier).refresh,
            ),
            _Section(
              title: l.schoolSafeTitle,
              child: Column(
                children: [dayRow(l.schoolToday, todayW), dayRow(l.schoolTomorrow, tomorrowW)],
              ),
            ),
            if (morning != null && morning.p50 != null)
              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (morning.label == 'avoid') Text(l.schoolAssembly, style: text.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      morning.p10 != null && morning.p90 != null
                          ? l.schoolPm8(
                              Numbers.whole(morning.p50!),
                              Numbers.whole(morning.p10!),
                              Numbers.whole(morning.p90!),
                            )
                          : l.schoolPm8NoRange(
                              Numbers.whole(morning.p50!),
                              l.commonRangeUnavailable,
                            ),
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    ConfidenceChip(value: morning.confidence),
                  ],
                ),
              ),
            _Section(
              title: l.schoolClassroomsNow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(adviceIcon, color: c.brandText),
                      const SizedBox(width: 8),
                      Expanded(child: Text(adviceTitle, style: text.titleMedium)),
                    ],
                  ),
                  if ((todayW?.adviceReason ?? (adviceWhy == null ? null : 1)) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      todayW?.adviceReason?.of(context.lang) ?? adviceWhy!,
                      style: text.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go(Routes.schoolAir),
                        child: Text(l.schoolSeeIndoor),
                      ),
                      OutlinedButton(
                        onPressed: () => context.push(Routes.schoolForecast),
                        child: Text(l.schoolSeeForecast),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (nextStage != null && nextStage.stage > 0)
              _Section(
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: c.warningText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.schoolGrap(
                          grapRoman(nextStage.stage),
                          IstTime.weekdayOfDate(nextStage.date, context.lang),
                          Numbers.percent(nextStage.probability),
                        ),
                        style: text.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            if (io?.latest?.outdoor != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  '${l.schoolOutdoor}: ${Numbers.whole(io!.latest!.outdoor!)} µg/m³ · '
                  '${Aqi.category(Aqi.fromPm25(io.latest!.outdoor!)).label(l)}',
                  style: text.bodySmall?.copyWith(color: c.mutedForeground),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: context.hawaColors.mutedForeground),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    ),
  );
}
