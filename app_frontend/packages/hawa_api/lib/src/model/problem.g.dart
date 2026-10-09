// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Problem _$ProblemFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Problem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['type', 'title', 'status', 'code'],
        );
        final val = Problem(
          type: $checkedConvert('type', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          status: $checkedConvert('status', (v) => (v as num).toInt()),
          code: $checkedConvert('code', (v) => v as String),
          detail: $checkedConvert('detail', (v) => v as String?),
          instance: $checkedConvert('instance', (v) => v as String?),
          requestId: $checkedConvert('request_id', (v) => v as String?),
          errors: $checkedConvert(
              'errors',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      ProblemFieldError.fromJson(e as Map<String, dynamic>))
                  .toList()),
          currentVersion:
              $checkedConvert('current_version', (v) => (v as num?)?.toInt()),
          allowed: $checkedConvert('allowed',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          retryAfter:
              $checkedConvert('retry_after', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'requestId': 'request_id',
        'currentVersion': 'current_version',
        'retryAfter': 'retry_after'
      },
    );

Map<String, dynamic> _$ProblemToJson(Problem instance) => <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'status': instance.status,
      'code': instance.code,
      if (instance.detail case final value?) 'detail': value,
      if (instance.instance case final value?) 'instance': value,
      if (instance.requestId case final value?) 'request_id': value,
      if (instance.errors?.map((e) => e.toJson()).toList() case final value?)
        'errors': value,
      if (instance.currentVersion case final value?) 'current_version': value,
      if (instance.allowed case final value?) 'allowed': value,
      if (instance.retryAfter case final value?) 'retry_after': value,
    };
