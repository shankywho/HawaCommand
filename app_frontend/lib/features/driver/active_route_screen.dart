import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:hawacommand_app/core/config.dart';
import 'package:hawacommand_app/core/geo.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/features/driver/driver_data.dart';
import 'package:hawacommand_app/features/driver/route_screen.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/states.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Design screen 02 · Driver · spray auto-confirmed.
///
/// Polls `/v1/driver/route` while open. With a live backend the card turns
/// green as soon as the route reports a `lastSpray` from HawaTag. In demo
/// mode the spray is simulated a few seconds after the route starts.
class ActiveRouteScreen extends ConsumerStatefulWidget {
  const ActiveRouteScreen({super.key});

  @override
  ConsumerState<ActiveRouteScreen> createState() => _ActiveRouteScreenState();
}

class _ActiveRouteScreenState extends ConsumerState<ActiveRouteScreen> {
  Timer? _poll;
  Timer? _demoSpray;
  bool _demoConfirmed = false;
  bool _announced = false;

  String get _asset => ref.read(sessionProvider)?.assetId ?? 'T-12';

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(AppConfig.sprayPollInterval, (_) {
      ref.invalidate(driverRouteProvider(_asset));
    });
    _demoSpray = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _demoConfirmed = true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _demoSpray?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = ref.watch(sessionProvider)?.assetId ?? 'T-12';
    final routeAsync = ref.watch(driverRouteProvider(asset));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hawaSystemUi,
      child: Scaffold(
        backgroundColor: HawaColors.paper,
        body: SafeArea(
          bottom: false,
          child: switch (routeAsync) {
            AsyncData(:final value) => _buildBody(value),
            AsyncError(:final error) => ErrorView(
              message: HawaApi.describeError(error),
              onRetry: () => ref.invalidate(driverRouteProvider(asset)),
            ),
            _ => routeAsync.hasValue ? _buildBody(routeAsync.requireValue) : const LoadingView(),
          },
        ),
      ),
    );
  }

  Widget _buildBody(Sourced<DriverRoute> sourced) {
    final route = sourced.data;
    final spray = sourced.isLive ? route.lastSpray : (_demoConfirmed ? demoSpray : null);
    final confirmed = spray != null;
    if (confirmed && !_announced) {
      _announced = true;
      unawaited(HapticFeedback.heavyImpact());
    }

    final sprayedIndex = sourced.isLive ? route.sprayedIndex : 0;
    final sprayedStop = route.stops.isEmpty ? null : route.stops[sprayedIndex];
    final next = route.nextAfter(sprayedIndex);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    String? nextLine;
    if (next != null) {
      final from = sprayedStop?.point;
      final to = next.point;
      nextLine = from != null && to != null
          ? '${next.from} · ${formatKm(distanceKm(from, to))}'
          : next.from;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              AssetChip(route.asset),
              const SizedBox(width: 10),
              Text(
                '${context.tr.primary('स्टॉप', 'Stop')} '
                '${sprayedIndex + 1} / ${route.stops.length}',
                style: context.tr.style(14, color: HawaColors.muted2),
              ),
              const Spacer(),
              Text(
                context.tr.primary('रूट चालू', 'Route running'),
                style: context.tr.style(13, color: HawaColors.muted),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: confirmed
                ? _ConfirmedCard(
                    key: const ValueKey('confirmed'),
                    placeHi: spray.placeHi,
                    placeEn: sprayedStop?.placeEn ?? spray.placeHi,
                  )
                : _WaitingCard(
                    key: const ValueKey('waiting'),
                    placeHi: sprayedStop?.placeHi ?? '',
                    placeEn: sprayedStop?.placeEn ?? '',
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _SprayStats(spray: spray),
        ),
        if (next != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              context.tr(
                'अगला स्टॉप',
                'Next stop',
                both: 'अगला स्टॉप · Next',
              ),
              style: context.tr.style(13, color: HawaColors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: StopCard(
              stop: next,
              active: true,
              emphasised: true,
              trailingLine: nextLine,
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              context.tr('सभी स्टॉप पूरे', 'All stops done'),
              style: context.tr.style(15, weight: FontWeight.w600),
            ),
          ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + bottomInset.clamp(12, 40),
          ),
          child: BigActionButton(
            icon: LucideIcons.navigation,
            labelHi: 'रास्ता दिखाएँ',
            labelEn: next == null ? 'Navigate to depot' : 'Navigate to stop ${next.number}',
            background: HawaColors.ink,
            foreground: HawaColors.paper,
            englishOpacity: 0.8,
            shadow: false,
            onTap: () => _navigate(next),
          ),
        ),
      ],
    );
  }

  Future<void> _navigate(RouteStop? stop) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.tr('नक्शा नहीं खुल सका', 'Could not open maps');
    final point = stop?.point;
    final query = point != null
        ? '${point.latitude},${point.longitude}'
        : Uri.encodeComponent('${stop?.placeEn ?? 'depot'}, Delhi');
    final native = Uri.parse('google.navigation:q=$query&mode=d');
    final web = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(native)) {
        await launchUrl(native);
      } else {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({
    required this.placeHi,
    required this.placeEn,
    super.key,
  });

  final String placeHi;
  final String placeEn;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: HawaColors.teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: HawaColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 44,
              color: HawaColors.teal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr.primary('छिड़काव दर्ज ✓', 'Spray logged ✓'),
            textAlign: TextAlign.center,
            style: tr.style(
              28,
              weight: FontWeight.w700,
              height: 1.2,
              color: HawaColors.white,
            ),
          ),
          if (tr.isBoth) ...[
            const SizedBox(height: 10),
            Text(
              'Spray logged',
              style: HawaText.sans(
                17,
                weight: FontWeight.w600,
                color: HawaColors.white,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Opacity(
            opacity: 0.95,
            child: Text(
              tr.isEn
                  ? '$placeEn · logged automatically by HawaTag'
                  : '$placeHi · HawaTag ने अपने-आप दर्ज किया',
              textAlign: TextAlign.center,
              style: tr.style(14, height: 1.5, color: HawaColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatefulWidget {
  const _WaitingCard({
    required this.placeHi,
    required this.placeEn,
    super.key,
  });

  final String placeHi;
  final String placeEn;

  @override
  State<_WaitingCard> createState() => _WaitingCardState();
}

class _WaitingCardState extends State<_WaitingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: HawaColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HawaColors.teal, width: 2),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.06).animate(_pulse),
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: HawaColors.outgoing,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.droplets,
                size: 34,
                color: HawaColors.teal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr.primary('छिड़काव का इंतज़ार', 'Waiting for HawaTag'),
            textAlign: TextAlign.center,
            style: tr.style(28, weight: FontWeight.w700, height: 1.2),
          ),
          if (tr.isBoth) ...[
            const SizedBox(height: 10),
            Text(
              'Waiting for HawaTag',
              style: HawaText.sans(
                17,
                weight: FontWeight.w600,
                color: HawaColors.teal,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            tr.isEn
                ? '${widget.placeEn} · logged automatically when the pump starts'
                : '${widget.placeHi} · पंप चालू होते ही अपने-आप दर्ज होगा',
            textAlign: TextAlign.center,
            style: tr.style(14, height: 1.5, color: HawaColors.muted2),
          ),
        ],
      ),
    );
  }
}

class _SprayStats extends StatelessWidget {
  const _SprayStats({required this.spray});

  final LastSpray? spray;

  @override
  Widget build(BuildContext context) {
    final s = spray;
    final tr = context.tr;
    final litres = s == null ? '—' : NumberFormat('#,##0').format(s.litres);
    final minutes = s == null ? '—' : s.pumpMinutes.round().toString();
    final pump = s == null ? '—' : (s.pumpOn ? 'ON' : 'OFF');
    return Container(
      decoration: BoxDecoration(
        color: HawaColors.line,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HawaColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Stat(
                label: tr.primary('पानी', 'Water'),
                value: litres,
                unit: s == null ? null : 'L',
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              child: _Stat(
                label: tr.primary('पंप चालू', 'Pump on'),
                value: minutes,
                unit: s == null ? null : 'min',
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              child: _Stat(label: tr.primary('पंप', 'Pump'), value: pump),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HawaColors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.tr.style(12, color: HawaColors.muted)),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                text: value,
                style: HawaText.mono(20, weight: FontWeight.w600),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: HawaText.mono(12, color: HawaColors.muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
