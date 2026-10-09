# hawa_api.api.AlertsApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**alertsAck**](AlertsApi.md#alertsack) | **POST** /v1/alerts/{id}/ack | Acknowledge an alert (proposed)
[**alertsGet**](AlertsApi.md#alertsget) | **GET** /v1/alerts/{id} | One alert
[**alertsList**](AlertsApi.md#alertslist) | **GET** /v1/alerts | Alerts addressed to the caller


# **alertsAck**
> AlertAckOut alertsAck(id, alertAckIn, idempotencyKey)

Acknowledge an alert (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAlertsApi();
final String id = id_example; // String | 
final AlertAckIn alertAckIn = ; // AlertAckIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.alertsAck(id, alertAckIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AlertsApi->alertsAck: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **alertAckIn** | [**AlertAckIn**](AlertAckIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**AlertAckOut**](AlertAckOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **alertsGet**
> AlertItem alertsGet(id)

One alert

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAlertsApi();
final String id = id_example; // String | 

try {
    final response = api.alertsGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AlertsApi->alertsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**AlertItem**](AlertItem.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **alertsList**
> AlertPage alertsList(from, limit, cursor)

Alerts addressed to the caller

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAlertsApi();
final String from = from_example; // String | ISO-8601 UTC timestamp
final int limit = 56; // int | 
final String cursor = cursor_example; // String | 

try {
    final response = api.alertsList(from, limit, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AlertsApi->alertsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **String**| ISO-8601 UTC timestamp | [optional] 
 **limit** | **int**|  | [optional] 
 **cursor** | **String**|  | [optional] 

### Return type

[**AlertPage**](AlertPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

