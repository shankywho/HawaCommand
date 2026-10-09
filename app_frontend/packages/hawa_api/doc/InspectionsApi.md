# hawa_api.api.InspectionsApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**inspectionsClose**](InspectionsApi.md#inspectionsclose) | **POST** /v1/inspections/{id}/close | Close with an outcome
[**inspectionsGet**](InspectionsApi.md#inspectionsget) | **GET** /v1/inspections/{id} | Inspector evidence bundle (proposed)
[**inspectionsList**](InspectionsApi.md#inspectionslist) | **GET** /v1/inspections | Inspections for the caller
[**inspectionsOnSite**](InspectionsApi.md#inspectionsonsite) | **POST** /v1/inspections/{id}/on-site | Mark on site (proposed)


# **inspectionsClose**
> InspectionCloseOut inspectionsClose(id, inspectionCloseIn, idempotencyKey)

Close with an outcome

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getInspectionsApi();
final String id = id_example; // String | 
final InspectionCloseIn inspectionCloseIn = ; // InspectionCloseIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.inspectionsClose(id, inspectionCloseIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling InspectionsApi->inspectionsClose: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **inspectionCloseIn** | [**InspectionCloseIn**](InspectionCloseIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**InspectionCloseOut**](InspectionCloseOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **inspectionsGet**
> InspectionDetailOut inspectionsGet(id)

Inspector evidence bundle (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getInspectionsApi();
final String id = id_example; // String | 

try {
    final response = api.inspectionsGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling InspectionsApi->inspectionsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**InspectionDetailOut**](InspectionDetailOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **inspectionsList**
> InspectionPage inspectionsList(status, limit, cursor)

Inspections for the caller

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getInspectionsApi();
final String status = status_example; // String | 
final int limit = 56; // int | 
final String cursor = cursor_example; // String | 

try {
    final response = api.inspectionsList(status, limit, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling InspectionsApi->inspectionsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] 
 **cursor** | **String**|  | [optional] 

### Return type

[**InspectionPage**](InspectionPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **inspectionsOnSite**
> InspectionCloseOut inspectionsOnSite(id, onSiteIn, idempotencyKey)

Mark on site (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getInspectionsApi();
final String id = id_example; // String | 
final OnSiteIn onSiteIn = ; // OnSiteIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.inspectionsOnSite(id, onSiteIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling InspectionsApi->inspectionsOnSite: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **onSiteIn** | [**OnSiteIn**](OnSiteIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**InspectionCloseOut**](InspectionCloseOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

