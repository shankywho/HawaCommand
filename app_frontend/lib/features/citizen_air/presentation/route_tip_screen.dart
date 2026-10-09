import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/features/citizen_air/application/air_near_me_controller.dart';

/// C8 Cleaner-route tip (`/citizen/route-tip`): the server-written tip from a traffic warning,
/// plus a way into the AI clean-route planner on the air map.
class RouteTipScreen extends ConsumerWidget {
  const RouteTipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tip = ref.watch(airNearMeControllerProvider).cached?.snapshot.altRoute;
    return Scaffold(
      appBar: AppBar(title: Text(l.routeTipTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tip == null)
            EmptyState(icon: Icons.alt_route, message: l.routeTipEmpty)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tip.of(context.lang), style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go(Routes.citizenMap),
            icon: const Icon(Icons.map_outlined),
            label: Text(l.airMapSearchHint),
          ),
        ],
      ),
    );
  }
}
