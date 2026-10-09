import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/core/widgets/status_pill.dart';
import 'package:hawa_app/features/citizen_reports/application/reports_controllers.dart';
import 'package:hawa_app/features/citizen_reports/domain/citizen_report.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';

/// C6 My reports (`/citizen/reports`): server reports merged with unsent drafts.
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reports = ref.watch(myReportsProvider);
    return Scaffold(
      appBar: ShellAppBar(title: l.myReportsTitle),
      body: reports.when(
        loading: () => const LoadingSkeleton(),
        error: (_, _) => EmptyState(icon: Icons.cloud_off, message: l.commonSomethingWrong),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.photo_camera_outlined,
                message: l.myReportsEmpty,
                action: FilledButton(
                  onPressed: () => context.go(Routes.reportCapture),
                  child: Text(l.airReport),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myReportsProvider),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ReportTile(item: items[i]),
                ),
              ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.item});

  final ReportListItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final thumb = item.thumbnail;
    Widget image;
    if (thumb != null && thumb.startsWith('asset://')) {
      image = Image.asset(
        thumb.substring('asset://'.length),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
      );
    } else if (thumb != null && thumb.startsWith('http')) {
      image = Image.network(
        thumb,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(c),
      );
    } else {
      image = _placeholder(c);
    }
    return ListTile(
      onTap: item.serverId == null ? null : () => context.push(Routes.report(item.serverId!)),
      leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
      title: Text(
        '${IstTime.shortDate(item.createdAt, context.lang)} ${IstTime.time(item.createdAt, context.lang)}'
        '${item.placeName == null ? '' : ' · ${item.placeName!.of(context.lang)}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (item.waiting)
              StatusPill(icon: Icons.schedule, label: l.myReportsWaiting, tone: StatusTone.warning)
            else
              StatusPill(
                icon: item.status.icon,
                label: item.status.label(l),
                tone: StatusTone.brand,
              ),
            if (item.viaWhatsapp)
              StatusPill(icon: Icons.chat_outlined, label: l.myReportsViaWhatsapp),
            if (item.isSimulated) const SimulatedBadge(),
          ],
        ),
      ),
      trailing: item.serverId == null ? null : const Icon(Icons.chevron_right),
    );
  }

  Widget _placeholder(HawaColors c) => Container(
    width: 56,
    height: 56,
    color: c.muted,
    child: Icon(Icons.photo_outlined, color: c.mutedForeground),
  );
}
