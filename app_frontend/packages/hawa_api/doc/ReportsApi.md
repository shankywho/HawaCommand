# hawa_api.api.ReportsApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**reportsCreate**](ReportsApi.md#reportscreate) | **POST** /v1/reports | Citizen Eyes report (JSON after presign)
[**reportsGet**](ReportsApi.md#reportsget) | **GET** /v1/reports/{id} | One report
[**reportsMine**](ReportsApi.md#reportsmine) | **GET** /v1/reports/mine | The caller&#39;s reports


# **reportsCreate**
> ReportCreateOut reportsCreate(reportCreateIn, idempotencyKey)

Citizen Eyes report (JSON after presign)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getReportsApi();
final ReportCreateIn reportCreateIn = ; // ReportCreateIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.reportsCreate(reportCreateIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->reportsCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reportCreateIn** | [**ReportCreateIn**](ReportCreateIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**ReportCreateOut**](ReportCreateOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportsGet**
> ReportDetailOut reportsGet(id)

One report

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getReportsApi();
final String id = id_example; // String | 

try {
    final response = api.reportsGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->reportsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**ReportDetailOut**](ReportDetailOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportsMine**
> ReportPage reportsMine(limit, cursor)

The caller's reports

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getReportsApi();
final int limit = 56; // int | 
final String cursor = cursor_example; // String | 

try {
    final response = api.reportsMine(limit, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->reportsMine: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] 
 **cursor** | **String**|  | [optional] 

### Return type

[**ReportPage**](ReportPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

