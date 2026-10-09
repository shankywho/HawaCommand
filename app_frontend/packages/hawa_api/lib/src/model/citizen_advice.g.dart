// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citizen_advice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CitizenAdvice _$CitizenAdviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CitizenAdvice',
      json,
      ($checkedConvert) {
        final val = CitizenAdvice(
          altRoute: $checkedConvert(
              'alt_route',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'altRoute': 'alt_route'},
    );

Map<String, dynamic> _$CitizenAdviceToJson(CitizenAdvice instance) =>
    <String, dynamic>{
      if (instance.altRoute?.toJson() case final value?) 'alt_route': value,
    };
