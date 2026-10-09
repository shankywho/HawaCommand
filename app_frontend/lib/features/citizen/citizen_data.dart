import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/core/air.dart';

/// Where a Citizen Eyes report is in its lifecycle.
enum ReportStage {
  sent('Sent', 'भेजा'),
  verified('Verified', 'पुष्टि'),
  onTheWay('On the way', 'रास्ते में'),
  resolved('Resolved', 'हल');

  const ReportStage(this.label, this.labelHi);

  final String label;
  final String labelHi;
}

class CitizenReport {
  const CitizenReport({
    required this.id,
    required this.place,
    required this.caption,
    required this.sentAt,
    required this.stage,
    required this.confidence,
    required this.team,
    required this.etaMinutes,
    this.captionHi,
    this.photoPath,
    this.verifiedAt,
    this.dispatchedAt,
    this.resolvedAt,
  });

  final String id;
  final String place;
  final String caption;

  /// Hindi caption, only for the built-in example report.
  final String? captionHi;

  /// Local file path of the photo; `null` shows the sample pixel scene.
  final String? photoPath;
  final DateTime sentAt;
  final ReportStage stage;
  final double confidence;
  final String team;
  final int etaMinutes;
  final DateTime? verifiedAt;
  final DateTime? dispatchedAt;
  final DateTime? resolvedAt;

  bool reached(ReportStage s) => stage.index >= s.index;

  CitizenReport advance(DateTime at) {
    final next = ReportStage.values[(stage.index + 1).clamp(0, 3)];
    return CitizenReport(
      id: id,
      place: place,
      caption: caption,
      captionHi: captionHi,
      photoPath: photoPath,
      sentAt: sentAt,
      stage: next,
      confidence: confidence,
      team: team,
      etaMinutes: etaMinutes,
      verifiedAt: next == ReportStage.verified ? at : verifiedAt,
      dispatchedAt: next == ReportStage.onTheWay ? at : dispatchedAt,
      resolvedAt: next == ReportStage.resolved ? at : resolvedAt,
    );
  }
}

/// Picks the burning hotspot that the report is matched against.
Hotspot burningHotspot(List<Hotspot> hotspots) => hotspots.firstWhere(
  (h) => h.cause.toLowerCase() == 'burning',
  orElse: () => demoHotspots.first,
);

String inspectionTeam(Hotspot h) => h.assets.firstWhere(
  (a) => a.startsWith('I-'),
  orElse: () => 'I-3',
);

/// Holds the report thread shown on the Citizen Eyes screen.
///
/// The backend has no reports endpoint yet, so a new report is matched to the
/// nearest burning hotspot from `/v1/hotspots` and walks through the lifecycle
/// on a timer (Sent → Verified → On the way → Resolved).
class CitizenReportController extends Notifier<CitizenReport?> {
  final List<Timer> _timers = [];
  int _nextNumber = 132;

  @override
  CitizenReport? build() {
    ref.onDispose(_cancel);
    return null;
  }

  /// The already-resolved example report from the design (#C-131).
  CitizenReport exampleFrom(Hotspot hotspot) {
    final day = DateTime.now();
    DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
    return CitizenReport(
      id: '#C-131',
      place: hotspot.place,
      caption: 'Garbage burning behind the market',
      captionHi: 'मार्केट के पीछे कूड़ा जल रहा है',
      sentAt: at(9, 58),
      stage: ReportStage.resolved,
      confidence: hotspot.causeConf,
      team: inspectionTeam(hotspot),
      etaMinutes: 25,
      verifiedAt: at(9, 59),
      dispatchedAt: at(10, 2),
      resolvedAt: at(10, 42),
    );
  }

  void submit({
    required Hotspot hotspot,
    required String caption,
    String? photoPath,
  }) {
    _cancel();
    state = CitizenReport(
      id: '#C-${_nextNumber++}',
      place: hotspot.place,
      caption: caption,
      photoPath: photoPath,
      sentAt: DateTime.now(),
      stage: ReportStage.sent,
      confidence: hotspot.causeConf,
      team: inspectionTeam(hotspot),
      etaMinutes: 25,
    );
    for (final seconds in const [3, 7, 16]) {
      _timers.add(
        Timer(Duration(seconds: seconds), () {
          final current = state;
          if (current != null) state = current.advance(DateTime.now());
        }),
      );
    }
  }

  void _cancel() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}

final citizenReportProvider = NotifierProvider<CitizenReportController, CitizenReport?>(
  CitizenReportController.new,
);
