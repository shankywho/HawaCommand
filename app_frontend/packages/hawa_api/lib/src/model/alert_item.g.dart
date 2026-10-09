// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertItem _$AlertItemFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AlertItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'audience',
            'kind',
            'status',
            'lang',
            'title',
            'body',
            'created_at',
            'is_simulated'
          ],
        );
        final val = AlertItem(
          id: $checkedConvert('id', (v) => v as String),
          audience: $checkedConvert(
              'audience',
              (v) => $enumDecode(_$AlertAudienceEnumMap, v,
                  unknownValue: AlertAudience.unknownDefaultOpenApi)),
          kind: $checkedConvert(
              'kind',
              (v) => $enumDecode(_$AlertKindEnumMap, v,
                  unknownValue: AlertKind.unknownDefaultOpenApi)),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$AlertStatusEnumMap, v,
                  unknownValue: AlertStatus.unknownDefaultOpenApi)),
          lang: $checkedConvert(
              'lang',
              (v) => $enumDecode(_$LangEnumMap, v,
                  unknownValue: Lang.unknownDefaultOpenApi)),
          title: $checkedConvert('title', (v) => v as String),
          body: $checkedConvert('body', (v) => v as String),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          channels: $checkedConvert(
              'channels',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => $enumDecode(_$AlertChannelEnumMap, e))
                  .toList()),
          pollutant: $checkedConvert(
              'pollutant',
              (v) => $enumDecodeNullable(_$PollutantEnumMap, v,
                  unknownValue: Pollutant.unknownDefaultOpenApi)),
          wardId: $checkedConvert('ward_id', (v) => v as String?),
          cellId: $checkedConvert('cell_id', (v) => v as String?),
          planId: $checkedConvert('plan_id', (v) => v as String?),
          taskId: $checkedConvert('task_id', (v) => v as String?),
          reportId: $checkedConvert('report_id', (v) => v as String?),
          schoolId: $checkedConvert('school_id', (v) => v as String?),
          deepLink: $checkedConvert('deep_link', (v) => v as String?),
          origin: $checkedConvert('origin', (v) => v as String?),
          args: $checkedConvert(
              'args',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as String),
                  )),
          sentAt: $checkedConvert(
              'sent_at', (v) => v == null ? null : DateTime.parse(v as String)),
          readAt: $checkedConvert(
              'read_at', (v) => v == null ? null : DateTime.parse(v as String)),
          ackedAt: $checkedConvert('acked_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          expiresAt: $checkedConvert('expires_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'isSimulated': 'is_simulated',
        'wardId': 'ward_id',
        'cellId': 'cell_id',
        'planId': 'plan_id',
        'taskId': 'task_id',
        'reportId': 'report_id',
        'schoolId': 'school_id',
        'deepLink': 'deep_link',
        'sentAt': 'sent_at',
        'readAt': 'read_at',
        'ackedAt': 'acked_at',
        'expiresAt': 'expires_at'
      },
    );

Map<String, dynamic> _$AlertItemToJson(AlertItem instance) => <String, dynamic>{
      'id': instance.id,
      'audience': _$AlertAudienceEnumMap[instance.audience]!,
      'kind': _$AlertKindEnumMap[instance.kind]!,
      'status': _$AlertStatusEnumMap[instance.status]!,
      'lang': _$LangEnumMap[instance.lang]!,
      'title': instance.title,
      'body': instance.body,
      'created_at': instance.createdAt.toIso8601String(),
      'is_simulated': instance.isSimulated,
      if (instance.channels?.map((e) => _$AlertChannelEnumMap[e]!).toList()
          case final value?)
        'channels': value,
      if (_$PollutantEnumMap[instance.pollutant] case final value?)
        'pollutant': value,
      if (instance.wardId case final value?) 'ward_id': value,
      if (instance.cellId case final value?) 'cell_id': value,
      if (instance.planId case final value?) 'plan_id': value,
      if (instance.taskId case final value?) 'task_id': value,
      if (instance.reportId case final value?) 'report_id': value,
      if (instance.schoolId case final value?) 'school_id': value,
      if (instance.deepLink case final value?) 'deep_link': value,
      if (instance.origin case final value?) 'origin': value,
      if (instance.args case final value?) 'args': value,
      if (instance.sentAt?.toIso8601String() case final value?)
        'sent_at': value,
      if (instance.readAt?.toIso8601String() case final value?)
        'read_at': value,
      if (instance.ackedAt?.toIso8601String() case final value?)
        'acked_at': value,
      if (instance.expiresAt?.toIso8601String() case final value?)
        'expires_at': value,
    };

const _$AlertAudienceEnumMap = {
  AlertAudience.school: 'school',
  AlertAudience.citizen: 'citizen',
  AlertAudience.driver: 'driver',
  AlertAudience.inspector: 'inspector',
  AlertAudience.officer: 'officer',
  AlertAudience.siteManager: 'site_manager',
  AlertAudience.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$AlertKindEnumMap = {
  AlertKind.pollutantWarning: 'pollutant_warning',
  AlertKind.safeWindow: 'safe_window',
  AlertKind.routeAssignment: 'route_assignment',
  AlertKind.inspectionTarget: 'inspection_target',
  AlertKind.grapOutlook: 'grap_outlook',
  AlertKind.reportOutcome: 'report_outcome',
  AlertKind.deviceHealth: 'device_health',
  AlertKind.routeChanged: 'route_changed',
  AlertKind.taskDoneAuto: 'task_done_auto',
  AlertKind.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$AlertStatusEnumMap = {
  AlertStatus.requested: 'requested',
  AlertStatus.queued: 'queued',
  AlertStatus.sent: 'sent',
  AlertStatus.delivered: 'delivered',
  AlertStatus.failed: 'failed',
  AlertStatus.read: 'read',
  AlertStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$LangEnumMap = {
  Lang.en: 'en',
  Lang.hi: 'hi',
  Lang.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$AlertChannelEnumMap = {
  AlertChannel.push: 'push',
  AlertChannel.whatsapp: 'whatsapp',
  AlertChannel.sms: 'sms',
  AlertChannel.email: 'email',
  AlertChannel.inApp: 'in_app',
  AlertChannel.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$PollutantEnumMap = {
  Pollutant.pm1: 'pm1',
  Pollutant.pm25: 'pm25',
  Pollutant.pm10: 'pm10',
  Pollutant.no2: 'no2',
  Pollutant.co: 'co',
  Pollutant.nh3: 'nh3',
  Pollutant.voc: 'voc',
  Pollutant.co2: 'co2',
  Pollutant.unknownDefaultOpenApi: 'unknown_default_open_api',
};
