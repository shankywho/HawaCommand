//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:hawa_api/src/auth/api_key_auth.dart';
import 'package:hawa_api/src/auth/basic_auth.dart';
import 'package:hawa_api/src/auth/bearer_auth.dart';
import 'package:hawa_api/src/auth/oauth.dart';
import 'package:hawa_api/src/api/alerts_api.dart';
import 'package:hawa_api/src/api/auth_api.dart';
import 'package:hawa_api/src/api/forecast_api.dart';
import 'package:hawa_api/src/api/grap_api.dart';
import 'package:hawa_api/src/api/inspections_api.dart';
import 'package:hawa_api/src/api/me_api.dart';
import 'package:hawa_api/src/api/open_data_api.dart';
import 'package:hawa_api/src/api/ops_api.dart';
import 'package:hawa_api/src/api/reports_api.dart';
import 'package:hawa_api/src/api/schools_api.dart';
import 'package:hawa_api/src/api/shifts_api.dart';
import 'package:hawa_api/src/api/sites_api.dart';
import 'package:hawa_api/src/api/tasks_api.dart';
import 'package:hawa_api/src/api/uploads_api.dart';

class HawaApi {
  static const String basePath = r'http://localhost:8000';

  final Dio dio;
  HawaApi({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : 
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Get AlertsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AlertsApi getAlertsApi() {
    return AlertsApi(dio);
  }

  /// Get AuthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthApi getAuthApi() {
    return AuthApi(dio);
  }

  /// Get ForecastApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ForecastApi getForecastApi() {
    return ForecastApi(dio);
  }

  /// Get GrapApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  GrapApi getGrapApi() {
    return GrapApi(dio);
  }

  /// Get InspectionsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  InspectionsApi getInspectionsApi() {
    return InspectionsApi(dio);
  }

  /// Get MeApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MeApi getMeApi() {
    return MeApi(dio);
  }

  /// Get OpenDataApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  OpenDataApi getOpenDataApi() {
    return OpenDataApi(dio);
  }

  /// Get OpsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  OpsApi getOpsApi() {
    return OpsApi(dio);
  }

  /// Get ReportsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ReportsApi getReportsApi() {
    return ReportsApi(dio);
  }

  /// Get SchoolsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SchoolsApi getSchoolsApi() {
    return SchoolsApi(dio);
  }

  /// Get ShiftsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ShiftsApi getShiftsApi() {
    return ShiftsApi(dio);
  }

  /// Get SitesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SitesApi getSitesApi() {
    return SitesApi(dio);
  }

  /// Get TasksApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TasksApi getTasksApi() {
    return TasksApi(dio);
  }

  /// Get UploadsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  UploadsApi getUploadsApi() {
    return UploadsApi(dio);
  }
}
