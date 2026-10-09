import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/localized_text.dart';

/// Proposed `ReportCategory`.
enum ReportCategory {
  burning('burning'),
  dust('dust'),
  other('other');

  const ReportCategory(this.wire);
  final String wire;
}

/// A row on C6: a server report or a local draft that is still waiting to send.
class ReportListItem {
  const ReportListItem({
    required this.key,
    required this.createdAt,
    required this.status,
    this.serverId,
    this.placeName,
    this.note,
    this.thumbnail,
    this.localPhotoPath,
    this.waiting = false,
    this.viaWhatsapp = false,
    this.isSimulated = false,
  });

  /// `client_report_id` (stable across draft → server).
  final String key;
  final String? serverId;
  final DateTime createdAt;
  final ReportStatus status;
  final LocalizedText? placeName;
  final String? note;

  /// `asset://…` or https URL from the server.
  final String? thumbnail;
  final String? localPhotoPath;

  /// Not sent yet (outbox).
  final bool waiting;
  final bool viaWhatsapp;
  final bool isSimulated;
}

class TimelineEntry {
  const TimelineEntry({required this.status, required this.at});

  final ReportStatus status;
  final DateTime at;
}

/// C7: status timeline and outcome.
class ReportDetail {
  const ReportDetail({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.timeline,
    this.placeName,
    this.photo,
    this.outcome,
    this.outcomeText,
    this.rejectionReason,
    this.isSimulated = false,
  });

  final String id;
  final DateTime createdAt;
  final ReportStatus status;
  final List<TimelineEntry> timeline;
  final LocalizedText? placeName;
  final String? photo;

  /// `closed_confirmed` | `closed_not_found` | `closed_unreachable` | null.
  final String? outcome;
  final LocalizedText? outcomeText;
  final LocalizedText? rejectionReason;
  final bool isSimulated;
}

/// A captured photo waiting for review (C4 → C5).
class ReportDraft {
  const ReportDraft({
    required this.clientReportId,
    required this.photoPath,
    required this.lat,
    required this.lon,
    required this.accuracyM,
    required this.capturedAt,
    this.coarse = false,
  });

  final String clientReportId;
  final String photoPath;
  final double lat;
  final double lon;
  final double accuracyM;
  final DateTime capturedAt;

  /// Only a last-known / coarse position was available.
  final bool coarse;
}
