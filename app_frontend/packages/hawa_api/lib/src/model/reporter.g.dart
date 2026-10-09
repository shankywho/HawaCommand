// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reporter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reporter _$ReporterFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Reporter',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['kind'],
        );
        final val = Reporter(
          kind: $checkedConvert('kind', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReporterToJson(Reporter instance) => <String, dynamic>{
      'kind': instance.kind,
    };
