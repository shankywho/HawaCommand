// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeFeatures _$MeFeaturesFromJson(Map<String, dynamic> json) => $checkedCreate(
      'MeFeatures',
      json,
      ($checkedConvert) {
        final val = MeFeatures(
          citizenEyes: $checkedConvert('citizen_eyes', (v) => v as bool?),
          schoolScheduler:
              $checkedConvert('school_scheduler', (v) => v as bool?),
          openData: $checkedConvert('open_data', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'citizenEyes': 'citizen_eyes',
        'schoolScheduler': 'school_scheduler',
        'openData': 'open_data'
      },
    );

Map<String, dynamic> _$MeFeaturesToJson(MeFeatures instance) =>
    <String, dynamic>{
      if (instance.citizenEyes case final value?) 'citizen_eyes': value,
      if (instance.schoolScheduler case final value?) 'school_scheduler': value,
      if (instance.openData case final value?) 'open_data': value,
    };
