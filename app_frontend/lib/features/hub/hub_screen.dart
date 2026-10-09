import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/auth/role_widgets.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/lang_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Home after sign-in: greeting, backend status, and the three experiences.
class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final health = ref.watch(healthProvider);
    if (session == null) return const SizedBox.shrink();
    final tr = context.tr;
    final firstName = session.name.split(' ').first;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hawaSystemUi,
      child: Scaffold(
        backgroundColor: HawaColors.paper,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: HawaColors.teal,
            onRefresh: () => ref.refresh(healthProvider.future),
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
              children: [
                Row(
                  children: [
                    const HawaMark(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HawaCommand',
                            style: HawaText.sans(18, weight: FontWeight.w700),
                          ),
                          Text(
                            tr(
                              'दिल्ली की हवा · फ़ील्ड और समुदाय',
                              'Delhi air · field & community',
                              both: 'Delhi air · field & community',
                            ),
                            style: tr.style(12.5, color: HawaColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const LanguageButton(),
                    IconButton(
                      tooltip: tr('सेटिंग्स', 'Settings'),
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(LucideIcons.settings, size: 22),
                      color: HawaColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  tr.isEn ? 'Hello, $firstName' : 'नमस्ते, $firstName',
                  style: tr.style(
                    30,
                    weight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  tr(
                    'आज क्या करना है?',
                    'What do you need today?',
                    both: 'What do you need today?',
                  ),
                  style: tr.style(14, color: HawaColors.muted),
                ),
                const SizedBox(height: 16),
                _BackendCard(health: health),
                const SizedBox(height: 20),
                Text(
                  tr('आपके काम', 'Your tools'),
                  style: tr.style(13, color: HawaColors.muted),
                ),
                const SizedBox(height: 8),
                for (final role in AppRole.values) ...[
                  RoleCard(
                    role: role,
                    selected: role == session.role,
                    onTap: () async {
                      if (role != session.role) {
                        await ref.read(sessionProvider.notifier).switchRole(role);
                      }
                      if (context.mounted) context.go(role.homePath);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                Text(
                  tr(
                    '${session.name} के रूप में लॉगिन · इस फ़ोन पर डेमो खाता',
                    'Signed in as ${session.name} · demo account on this phone',
                    both: 'Signed in as ${session.name} · demo account on this phone',
                  ),
                  textAlign: TextAlign.center,
                  style: tr.style(12, color: HawaColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackendCard extends StatelessWidget {
  const _BackendCard({required this.health});

  final AsyncValue<HealthStatus> health;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final status = health.value;
    final loading = health.isLoading && status == null;
    final ok = status?.ok ?? false;
    final title = loading
        ? tr('बैकएंड जाँच रहे हैं…', 'Checking backend…')
        : ok
        ? tr('लाइव बैकएंड', 'Live backend')
        : tr('ऑफ़लाइन · डेमो डेटा', 'Offline · demo data');
    return HawaCard(
      onTap: () => context.push('/settings'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            loading ? LucideIcons.server : (ok ? LucideIcons.wifi : LucideIcons.wifiOff),
            size: 20,
            color: ok ? HawaColors.teal : HawaColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tr.style(15, weight: FontWeight.w600)),
                Text(
                  loading ? ' ' : (status?.detail ?? ''),
                  style: HawaText.mono(11.5, color: HawaColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SourcePill(live: ok),
        ],
      ),
    );
  }
}
