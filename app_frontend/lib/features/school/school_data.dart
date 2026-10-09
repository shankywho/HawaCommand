import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/core/api_client.dart';

/// A school alert from `GET /v1/alerts` (audience `School`).
class SchoolAlert {
  const SchoolAlert({
    required this.id,
    required this.sentAt,
    required this.chip,
    required this.message,
    required this.detail,
    required this.detailHi,
    required this.messageHi,
  });

  factory SchoolAlert.fromJson(Map<String, dynamic> json) {
    final message = json['message'] as String? ?? '';
    final lead = (json['leadTimeH'] as num?)?.toDouble();
    final delivered = json['delivered'] as String?;
    final drafted = json['draftedBy'] as String?;
    final detail = [
      'Main pollutant: PM2.5.',
      if (lead != null) 'Sent ${lead.toStringAsFixed(1)} h before the peak.',
      if (delivered != null) 'Delivery: $delivered.',
      if (drafted != null) 'Drafted by the $drafted agent.',
    ].join(' ');
    final detailHi = [
      'मुख्य प्रदूषक: PM2.5।',
      if (lead != null) 'पीक से ${lead.toStringAsFixed(1)} घंटे पहले भेजा गया।',
      if (delivered != null) 'डिलीवरी: $delivered।',
      if (drafted != null) '$drafted एजेंट ने लिखा।',
    ].join(' ');
    return SchoolAlert(
      id: json['id'] as String? ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      chip: chipFor(message),
      message: message,
      detail: detail,
      detailHi: detailHi,
      messageHi: json['messageHi'] as String?,
    );
  }

  final String id;
  final DateTime sentAt;

  /// Pixel label above the message, e.g. `AQI ~380 · 8 AM`.
  final String chip;
  final String message;
  final String detail;
  final String detailHi;
  final String? messageHi;

  /// Builds the chip from the alert text, e.g. `PM2.5 ~380 · 8 AM`.
  static String chipFor(String message) {
    final level = RegExp(
      r'(\d{2,3})\s*(?:ug/m3|µg/m³|ug/m³)',
    ).firstMatch(message);
    final at = RegExp(r'at (\d{1,2}):(\d{2})').firstMatch(message);
    final parts = <String>[
      if (level != null) 'PM2.5 ~${level.group(1)}',
      if (at != null) _clock(int.parse(at.group(1)!), int.parse(at.group(2)!)),
    ];
    return parts.isEmpty ? 'AIR ALERT' : parts.join(' · ');
  }

  static String _clock(int hour, int minute) {
    final suffix = hour < 12 ? 'AM' : 'PM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return minute == 0 ? '$h $suffix' : '$h:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

/// Design screen 03 content, used when the backend is unreachable.
final demoSchoolAlert = SchoolAlert(
  id: 'alt-demo',
  sentAt: DateTime(2026, 11, 11, 19),
  chip: 'AQI ~380 · 8 AM',
  message:
      'AQI near your school will reach ~380 at 8 AM. Hold assembly indoors. '
      'Safest outdoor window: 12:30–2:00 PM.',
  detail:
      'Main pollutant: PM2.5. Keep classroom windows shut until 11 AM. '
      'Forecast confidence 0.81.',
  detailHi:
      'मुख्य प्रदूषक: PM2.5। कक्षा की खिड़कियाँ सुबह 11 बजे तक बंद रखें। '
      'पूर्वानुमान भरोसा 0.81।',
  messageHi:
      'आपके स्कूल के पास कल सुबह 8 बजे AQI लगभग 380 तक पहुँचेगा। प्रार्थना सभा '
      'अंदर करें। बाहर के लिए सबसे सुरक्षित समय: दोपहर 12:30–2:00।',
);

final schoolAlertProvider = FutureProvider.autoDispose<Sourced<SchoolAlert>>(
  (ref) => ref
      .watch(hawaApiProvider)
      .fetchOrDemo(
        '/v1/alerts',
        parse: (json) {
          final items = (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();
          final school = items.firstWhere(
            (a) => (a['audience'] as String?)?.toLowerCase() == 'school',
            orElse: () => throw const FormatException('No school alert'),
          );
          return SchoolAlert.fromJson(school);
        },
        demo: () => demoSchoolAlert,
      ),
  retry: (retryCount, error) => null,
);

/// A message the principal sent in this thread (kept on the device).
class SentReply {
  const SentReply(this.text, this.at, {this.fromSystem = false});

  final String text;
  final DateTime at;

  /// An automatic acknowledgement from HawaCommand (incoming bubble).
  final bool fromSystem;
}

class SchoolRepliesController extends Notifier<List<SentReply>> {
  @override
  List<SentReply> build() => const [];

  void send(String text) => state = [...state, SentReply(text, DateTime.now())];

  void acknowledge(String text) =>
      state = [...state, SentReply(text, DateTime.now(), fromSystem: true)];
}

final schoolRepliesProvider = NotifierProvider<SchoolRepliesController, List<SentReply>>(
  SchoolRepliesController.new,
);
