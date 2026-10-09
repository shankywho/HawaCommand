# hawa_api.api.ShiftsApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**shiftsEnd**](ShiftsApi.md#shiftsend) | **POST** /v1/shifts/{id}/end | End a shift (proposed)
[**shiftsLocations**](ShiftsApi.md#shiftslocations) | **POST** /v1/shifts/{id}/locations | Upload shift location pings (proposed)
[**shiftsStart**](ShiftsApi.md#shiftsstart) | **POST** /v1/shifts/{id}/start | Start a shift (proposed)


# **shiftsEnd**
> ShiftOut shiftsEnd(id, shiftActionIn, idempotencyKey)

End a shift (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getShiftsApi();
final String id = id_example; // String | 
final ShiftActionIn shiftActionIn = ; // ShiftActionIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.shiftsEnd(id, shiftActionIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ShiftsApi->shiftsEnd: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **shiftActionIn** | [**ShiftActionIn**](ShiftActionIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**ShiftOut**](ShiftOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **shiftsLocations**
> LocationBatchOut shiftsLocations(id, locationBatchIn, idempotencyKey)

Upload shift location pings (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getShiftsApi();
final String id = id_example; // String | 
final LocationBatchIn locationBatchIn = ; // LocationBatchIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.shiftsLocations(id, locationBatchIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ShiftsApi->shiftsLocations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **locationBatchIn** | [**LocationBatchIn**](LocationBatchIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**LocationBatchOut**](LocationBatchOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **shiftsStart**
> ShiftOut shiftsStart(id, shiftActionIn, idempotencyKey)

Start a shift (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getShiftsApi();
final String id = id_example; // String | 
final ShiftActionIn shiftActionIn = ; // ShiftActionIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.shiftsStart(id, shiftActionIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ShiftsApi->shiftsStart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **shiftActionIn** | [**ShiftActionIn**](ShiftActionIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**ShiftOut**](ShiftOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

