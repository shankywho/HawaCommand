# hawa_api.api.SchoolsApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**schoolsIndoorOutdoor**](SchoolsApi.md#schoolsindooroutdoor) | **GET** /v1/schools/{id}/indoor-outdoor | HawaPod-S pair readings
[**schoolsMe**](SchoolsApi.md#schoolsme) | **GET** /v1/schools/me | The caller&#39;s school
[**schoolsSafeWindow**](SchoolsApi.md#schoolssafewindow) | **GET** /v1/schools/{id}/safe-window | Safe outdoor windows for a day


# **schoolsIndoorOutdoor**
> IndoorOutdoorOut schoolsIndoorOutdoor(id, from, to, interval)

HawaPod-S pair readings

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getSchoolsApi();
final String id = id_example; // String | 
final String from = from_example; // String | ISO-8601 UTC timestamp
final String to = to_example; // String | ISO-8601 UTC timestamp
final String interval = interval_example; // String | 

try {
    final response = api.schoolsIndoorOutdoor(id, from, to, interval);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolsApi->schoolsIndoorOutdoor: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **from** | **String**| ISO-8601 UTC timestamp | [optional] 
 **to** | **String**| ISO-8601 UTC timestamp | [optional] 
 **interval** | **String**|  | [optional] 

### Return type

[**IndoorOutdoorOut**](IndoorOutdoorOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **schoolsMe**
> SchoolMeOut schoolsMe()

The caller's school

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getSchoolsApi();

try {
    final response = api.schoolsMe();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolsApi->schoolsMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SchoolMeOut**](SchoolMeOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **schoolsSafeWindow**
> SafeWindowOut schoolsSafeWindow(id, date)

Safe outdoor windows for a day

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getSchoolsApi();
final String id = id_example; // String | 
final String date = date_example; // String | IST service date YYYY-MM-DD

try {
    final response = api.schoolsSafeWindow(id, date);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolsApi->schoolsSafeWindow: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **date** | **String**| IST service date YYYY-MM-DD | [optional] 

### Return type

[**SafeWindowOut**](SafeWindowOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

