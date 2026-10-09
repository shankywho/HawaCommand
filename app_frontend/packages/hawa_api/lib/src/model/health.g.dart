// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Health',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['status'],
        );
        final val = Health(
          status: $checkedConvert('status', (v) => v as String),
          service: $checkedConvert('service', (v) => v as String?),
          version: $checkedConvert('version', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
      'status': instance.status,
      if (instance.service case final value?) 'service': value,
      if (instance.version case final value?) 'version': value,
    };
