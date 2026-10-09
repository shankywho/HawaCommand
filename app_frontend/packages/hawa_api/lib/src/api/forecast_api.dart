//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:hawa_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:hawa_api/src/model/forecast_cell_out.dart';
import 'package:hawa_api/src/model/problem.dart';

class ForecastApi {

  final Dio _dio;

  const ForecastApi(this._dio);

  /// 72 h forecast for a cell
  /// 
  ///
  /// Parameters:
  /// * [cellId] 
  /// * [pollutant] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [ForecastCellOut] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ForecastCellOut>> forecastGet({ 
    required String cellId,
    String? pollutant,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/forecast/{cell_id}'.replaceAll('{' r'cell_id' '}', cellId.toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (pollutant != null) r'pollutant': pollutant,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    ForecastCellOut? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<ForecastCellOut, ForecastCellOut>(rawData, 'ForecastCellOut', growable: true);

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<ForecastCellOut>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
