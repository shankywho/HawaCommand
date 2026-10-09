// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_field_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProblemFieldError _$ProblemFieldErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProblemFieldError',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['pointer', 'code'],
        );
        final val = ProblemFieldError(
          pointer: $checkedConvert('pointer', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
          detail: $checkedConvert('detail', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ProblemFieldErrorToJson(ProblemFieldError instance) =>
    <String, dynamic>{
      'pointer': instance.pointer,
      'code': instance.code,
      if (instance.detail case final value?) 'detail': value,
    };
