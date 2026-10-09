import 'package:hawa_api/src/model/alert_ack_in.dart';
import 'package:hawa_api/src/model/alert_ack_out.dart';
import 'package:hawa_api/src/model/alert_item.dart';
import 'package:hawa_api/src/model/alert_page.dart';
import 'package:hawa_api/src/model/alert_subscription.dart';
import 'package:hawa_api/src/model/auth_user.dart';
import 'package:hawa_api/src/model/citizen_advice.dart';
import 'package:hawa_api/src/model/device_state.dart';
import 'package:hawa_api/src/model/evidence_photo.dart';
import 'package:hawa_api/src/model/evidence_summary.dart';
import 'package:hawa_api/src/model/forecast_cell_out.dart';
import 'package:hawa_api/src/model/forecast_daily.dart';
import 'package:hawa_api/src/model/forecast_point.dart';
import 'package:hawa_api/src/model/geo_line_string.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:hawa_api/src/model/geo_polygon.dart';
import 'package:hawa_api/src/model/grap_day.dart';
import 'package:hawa_api/src/model/grap_outlook_out.dart';
import 'package:hawa_api/src/model/health.dart';
import 'package:hawa_api/src/model/impact_summary.dart';
import 'package:hawa_api/src/model/indoor_outdoor_devices.dart';
import 'package:hawa_api/src/model/indoor_outdoor_out.dart';
import 'package:hawa_api/src/model/indoor_outdoor_point.dart';
import 'package:hawa_api/src/model/indoor_outdoor_summary.dart';
import 'package:hawa_api/src/model/inspection_close_in.dart';
import 'package:hawa_api/src/model/inspection_close_out.dart';
import 'package:hawa_api/src/model/inspection_detail_out.dart';
import 'package:hawa_api/src/model/inspection_list_item.dart';
import 'package:hawa_api/src/model/inspection_page.dart';
import 'package:hawa_api/src/model/lat_lon.dart';
import 'package:hawa_api/src/model/licence.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:hawa_api/src/model/location_batch_in.dart';
import 'package:hawa_api/src/model/location_batch_out.dart';
import 'package:hawa_api/src/model/location_ping.dart';
import 'package:hawa_api/src/model/logout_in.dart';
import 'package:hawa_api/src/model/me_features.dart';
import 'package:hawa_api/src/model/me_out.dart';
import 'package:hawa_api/src/model/me_patch_in.dart';
import 'package:hawa_api/src/model/on_site_in.dart';
import 'package:hawa_api/src/model/open_air_feature.dart';
import 'package:hawa_api/src/model/open_air_out.dart';
import 'package:hawa_api/src/model/open_air_properties.dart';
import 'package:hawa_api/src/model/otp_request_in.dart';
import 'package:hawa_api/src/model/otp_request_out.dart';
import 'package:hawa_api/src/model/otp_verify_in.dart';
import 'package:hawa_api/src/model/pm10_trend_point.dart';
import 'package:hawa_api/src/model/presign_in.dart';
import 'package:hawa_api/src/model/presign_out.dart';
import 'package:hawa_api/src/model/problem.dart';
import 'package:hawa_api/src/model/problem_field_error.dart';
import 'package:hawa_api/src/model/push_token_in.dart';
import 'package:hawa_api/src/model/push_token_out.dart';
import 'package:hawa_api/src/model/quantile_value.dart';
import 'package:hawa_api/src/model/quiet_hours.dart';
import 'package:hawa_api/src/model/refresh_in.dart';
import 'package:hawa_api/src/model/report_create_in.dart';
import 'package:hawa_api/src/model/report_create_out.dart';
import 'package:hawa_api/src/model/report_detail_out.dart';
import 'package:hawa_api/src/model/report_inspection.dart';
import 'package:hawa_api/src/model/report_list_item.dart';
import 'package:hawa_api/src/model/report_page.dart';
import 'package:hawa_api/src/model/report_timeline_entry.dart';
import 'package:hawa_api/src/model/report_verification.dart';
import 'package:hawa_api/src/model/reporter.dart';
import 'package:hawa_api/src/model/safe_window.dart';
import 'package:hawa_api/src/model/safe_window_out.dart';
import 'package:hawa_api/src/model/school_devices.dart';
import 'package:hawa_api/src/model/school_hours.dart';
import 'package:hawa_api/src/model/school_me_out.dart';
import 'package:hawa_api/src/model/school_now.dart';
import 'package:hawa_api/src/model/school_ref.dart';
import 'package:hawa_api/src/model/school_today.dart';
import 'package:hawa_api/src/model/series_point.dart';
import 'package:hawa_api/src/model/shift_action_in.dart';
import 'package:hawa_api/src/model/shift_out.dart';
import 'package:hawa_api/src/model/site_me_out.dart';
import 'package:hawa_api/src/model/site_ref.dart';
import 'package:hawa_api/src/model/site_score_component.dart';
import 'package:hawa_api/src/model/spike_evidence.dart';
import 'package:hawa_api/src/model/switch_role_in.dart';
import 'package:hawa_api/src/model/task_ack_in.dart';
import 'package:hawa_api/src/model/task_ack_out.dart';
import 'package:hawa_api/src/model/task_asset.dart';
import 'package:hawa_api/src/model/task_history_entry.dart';
import 'package:hawa_api/src/model/task_item.dart';
import 'package:hawa_api/src/model/task_route.dart';
import 'package:hawa_api/src/model/task_shift.dart';
import 'package:hawa_api/src/model/task_status_in.dart';
import 'package:hawa_api/src/model/task_status_out.dart';
import 'package:hawa_api/src/model/tasks_mine_out.dart';
import 'package:hawa_api/src/model/token_response.dart';
import 'package:hawa_api/src/model/ward_ref.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'AlertAckIn':
          return AlertAckIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AlertAckOut':
          return AlertAckOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AlertAudience':
          
          
        case 'AlertChannel':
          
          
        case 'AlertItem':
          return AlertItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AlertKind':
          
          
        case 'AlertPage':
          return AlertPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AlertStatus':
          
          
        case 'AlertSubscription':
          return AlertSubscription.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AqiCategory':
          
          
        case 'AssetType':
          
          
        case 'AuthUser':
          return AuthUser.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CauseLabel':
          
          
        case 'CitizenAdvice':
          return CitizenAdvice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClassroomAdvice':
          
          
        case 'DeviceState':
          return DeviceState.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceStatus':
          
          
        case 'EvidencePhoto':
          return EvidencePhoto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EvidenceSummary':
          return EvidenceSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForecastCellOut':
          return ForecastCellOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForecastDaily':
          return ForecastDaily.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForecastPoint':
          return ForecastPoint.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GeoLineString':
          return GeoLineString.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GeoPoint':
          return GeoPoint.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GeoPolygon':
          return GeoPolygon.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GrapDay':
          return GrapDay.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GrapOutlookOut':
          return GrapOutlookOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Health':
          return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImpactMethod':
          
          
        case 'ImpactSummary':
          return ImpactSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImpactVerdict':
          
          
        case 'IndoorOutdoorDevices':
          return IndoorOutdoorDevices.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IndoorOutdoorOut':
          return IndoorOutdoorOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IndoorOutdoorPoint':
          return IndoorOutdoorPoint.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IndoorOutdoorSummary':
          return IndoorOutdoorSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InspectionCloseIn':
          return InspectionCloseIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InspectionCloseOut':
          return InspectionCloseOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InspectionDetailOut':
          return InspectionDetailOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InspectionListItem':
          return InspectionListItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InspectionOrigin':
          
          
        case 'InspectionOutcome':
          
          
        case 'InspectionPage':
          return InspectionPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InspectionStatus':
          
          
        case 'InterventionSource':
          
          
        case 'Lang':
          
          
        case 'LatLon':
          return LatLon.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Licence':
          return Licence.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocalizedText':
          return LocalizedText.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocationBatchIn':
          return LocationBatchIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocationBatchOut':
          return LocationBatchOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocationPing':
          return LocationPing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LogoutIn':
          return LogoutIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MeFeatures':
          return MeFeatures.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MeOut':
          return MeOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MePatchIn':
          return MePatchIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OnSiteIn':
          return OnSiteIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OpenAirFeature':
          return OpenAirFeature.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OpenAirOut':
          return OpenAirOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OpenAirProperties':
          return OpenAirProperties.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OtpChannel':
          
          
        case 'OtpRequestIn':
          return OtpRequestIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OtpRequestOut':
          return OtpRequestOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OtpVerifyIn':
          return OtpVerifyIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Pm10TrendPoint':
          return Pm10TrendPoint.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Pollutant':
          
          
        case 'PresignIn':
          return PresignIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PresignOut':
          return PresignOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Problem':
          return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProblemFieldError':
          return ProblemFieldError.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PushPlatform':
          
          
        case 'PushTokenIn':
          return PushTokenIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PushTokenOut':
          return PushTokenOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'QuantileValue':
          return QuantileValue.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'QuietHours':
          return QuietHours.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RefreshIn':
          return RefreshIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportCategory':
          
          
        case 'ReportCreateIn':
          return ReportCreateIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportCreateOut':
          return ReportCreateOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportDetailOut':
          return ReportDetailOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportInspection':
          return ReportInspection.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportListItem':
          return ReportListItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportPage':
          return ReportPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportSource':
          
          
        case 'ReportStatus':
          
          
        case 'ReportTimelineEntry':
          return ReportTimelineEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportVerification':
          return ReportVerification.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Reporter':
          return Reporter.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SafeWindow':
          return SafeWindow.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SafeWindowLabel':
          
          
        case 'SafeWindowOut':
          return SafeWindowOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SchoolDevices':
          return SchoolDevices.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SchoolHours':
          return SchoolHours.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SchoolMeOut':
          return SchoolMeOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SchoolNow':
          return SchoolNow.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SchoolRef':
          return SchoolRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SchoolToday':
          return SchoolToday.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SeriesPoint':
          return SeriesPoint.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ShiftActionIn':
          return ShiftActionIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ShiftOut':
          return ShiftOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ShiftStatus':
          
          
        case 'SiteGrade':
          
          
        case 'SiteMeOut':
          return SiteMeOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteRef':
          return SiteRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteScoreComponent':
          return SiteScoreComponent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteType':
          
          
        case 'SkipReason':
          
          
        case 'SpikeEvidence':
          return SpikeEvidence.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SwitchRoleIn':
          return SwitchRoleIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskAckIn':
          return TaskAckIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskAckOut':
          return TaskAckOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskAsset':
          return TaskAsset.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskHistoryEntry':
          return TaskHistoryEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskItem':
          return TaskItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskKind':
          
          
        case 'TaskRoute':
          return TaskRoute.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskShift':
          return TaskShift.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskStatus':
          
          
        case 'TaskStatusIn':
          return TaskStatusIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskStatusOut':
          return TaskStatusOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TasksMineOut':
          return TasksMineOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TokenResponse':
          return TokenResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UploadPurpose':
          
          
        case 'UserRole':
          
          
        case 'WardRef':
          return WardRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }