import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/gen/app_localizations.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/features/driver_route/domain/asset_summary.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:url_launcher/url_launcher.dart';

/// Copy helpers shared by D1–D6 (pure functions of the stop and the localizations).
abstract final class DriverText {
  static String window(Stop s, AppLocalizations l, String lang) =>
      l.driverArriveWindow(IstTime.time(s.windowStart, lang), IstTime.time(s.windowEnd, lang));

  /// "Spray about 600 L along 800 m" etc., by task kind and asset type.
  static String whatToDo(Stop s, AppLocalizations l, {AssetSummary? asset}) {
    final metres = Numbers.whole(s.segmentLengthM ?? 0);
    if (asset?.type == 'smog_gun' && s.durationMin != null) {
      return l.driverDoSmogGun('${s.durationMin}');
    }
    return switch (s.kind) {
      TaskKind.spray => l.driverDoSpray(Numbers.whole(s.targetLitres ?? 0), metres),
      TaskKind.sweep => l.driverDoSweep(metres),
      TaskKind.inspect => l.driverDoInspect,
      _ => s.instructions?.en ?? s.kind.label(l),
    };
  }

  static IconData kindIcon(Stop s) => switch (s.kind) {
    TaskKind.spray => Icons.water_drop_outlined,
    TaskKind.sweep => Icons.cleaning_services_outlined,
    TaskKind.inspect => Icons.search,
    _ => Icons.place_outlined,
  };

  /// The done line: by HawaTag (with litres), manual (lower evidence) or GPS.
  static String? doneLine(Stop s, AppLocalizations l) {
    if (!s.shownStatus.isCompleted) return null;
    if (s.doneByTag) {
      return s.litres == null
          ? l.driverDoneByTag
          : l.driverDoneByTagLitres(Numbers.whole(s.litres!));
    }
    if (s.completionSource == InterventionSource.manual || s.lowerEvidence) {
      return l.driverDoneManual;
    }
    if (s.completionSource == InterventionSource.gpsInferred) return l.driverDoneGps;
    return s.shownStatus.label(l);
  }

  /// Google Maps turn-by-turn, else the web directions URL.
  static Future<bool> navigate(GeoPoint to) async {
    final lat = to.lat.toStringAsFixed(6);
    final lon = to.lon.toStringAsFixed(6);
    final intent = Uri.parse('google.navigation:q=$lat,$lon&mode=d');
    try {
      if (await launchUrl(intent)) return true;
    } on Object {
      // Fall through to the web URL (no Google Maps app).
    }
    return launchUrl(
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lon',
        'travelmode': 'driving',
      }),
      mode: LaunchMode.externalApplication,
    );
  }
}
