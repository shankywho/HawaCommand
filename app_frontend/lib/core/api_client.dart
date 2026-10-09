import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/core/config.dart';
import 'package:hawacommand_app/core/prefs.dart';

/// Where a piece of data on screen came from.
enum DataOrigin {
  /// Fetched from the HawaCommand backend just now.
  live,

  /// Bundled demo data (backend unreachable, or demo-only mode is on).
  demo,
}

/// A value plus its origin, so screens and Settings can be honest about it.
class Sourced<T> {
  const Sourced(this.data, this.origin, {this.error});

  final T data;
  final DataOrigin origin;

  /// Why live data was not used, when [origin] is [DataOrigin.demo].
  final String? error;

  bool get isLive => origin == DataOrigin.live;
}

/// Backend connection settings, persisted on the device.
class ConnectionSettings {
  const ConnectionSettings({required this.apiUrl, required this.demoOnly});

  final String apiUrl;
  final bool demoOnly;

  ConnectionSettings copyWith({String? apiUrl, bool? demoOnly}) => ConnectionSettings(
    apiUrl: apiUrl ?? this.apiUrl,
    demoOnly: demoOnly ?? this.demoOnly,
  );
}

class ConnectionSettingsController extends Notifier<ConnectionSettings> {
  @override
  ConnectionSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return ConnectionSettings(
      apiUrl: prefs.getString(PrefKeys.apiUrl) ?? AppConfig.defaultApiUrl,
      demoOnly: prefs.getBool(PrefKeys.demoOnly) ?? false,
    );
  }

  Future<void> setApiUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    await ref.read(sharedPrefsProvider).setString(PrefKeys.apiUrl, cleaned);
    state = state.copyWith(apiUrl: cleaned);
  }

  Future<void> setDemoOnly({required bool value}) async {
    await ref.read(sharedPrefsProvider).setBool(PrefKeys.demoOnly, value);
    state = state.copyWith(demoOnly: value);
  }
}

final connectionSettingsProvider =
    NotifierProvider<ConnectionSettingsController, ConnectionSettings>(
      ConnectionSettingsController.new,
    );

/// Thin JSON client for the HawaCommand REST API.
class HawaApi {
  HawaApi(this._settings)
    : _dio = Dio(
        BaseOptions(
          baseUrl: _settings.apiUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {'accept': 'application/json'},
        ),
      );

  final ConnectionSettings _settings;
  final Dio _dio;

  String get baseUrl => _settings.apiUrl;
  bool get demoOnly => _settings.demoOnly;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty response body');
    }
    return data;
  }

  /// Fetches [path] and maps it with [parse]; falls back to [demo] on any
  /// network, HTTP or parsing failure, or when demo-only mode is on.
  Future<Sourced<T>> fetchOrDemo<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parse,
    required T Function() demo,
    Map<String, dynamic>? query,
  }) async {
    if (demoOnly) {
      return Sourced(demo(), DataOrigin.demo, error: 'Demo-only mode is on');
    }
    try {
      final json = await getJson(path, query: query);
      return Sourced(parse(json), DataOrigin.live);
    } on Object catch (error) {
      return Sourced(demo(), DataOrigin.demo, error: describeError(error));
    }
  }

  static String describeError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status != null) return 'HTTP $status';
      return switch (error.type) {
        DioExceptionType.connectionTimeout => 'Connection timed out',
        DioExceptionType.receiveTimeout => 'Server did not answer in time',
        DioExceptionType.connectionError => 'Cannot reach server',
        _ => error.message ?? 'Network error',
      };
    }
    if (error is FormatException) return 'Unexpected response';
    return error.toString();
  }
}

final hawaApiProvider = Provider<HawaApi>(
  (ref) => HawaApi(ref.watch(connectionSettingsProvider)),
);

/// Result of `GET /healthz`.
class HealthStatus {
  const HealthStatus({required this.ok, required this.detail});

  final bool ok;
  final String detail;
}

final healthProvider = FutureProvider.autoDispose<HealthStatus>((ref) async {
  final api = ref.watch(hawaApiProvider);
  if (api.demoOnly) {
    return const HealthStatus(ok: false, detail: 'Demo-only mode is on');
  }
  try {
    final json = await api.getJson('/healthz');
    final ok = json['status'] == 'ok';
    return HealthStatus(
      ok: ok,
      detail: ok ? 'Connected to ${api.baseUrl}' : 'Unexpected /healthz reply',
    );
  } on Object catch (error) {
    return HealthStatus(ok: false, detail: HawaApi.describeError(error));
  }
}, retry: (retryCount, error) => null);
