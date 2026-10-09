# hawa_api.api.GrapApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**grapOutlook**](GrapApi.md#grapoutlook) | **GET** /v1/grap/outlook | GRAP outlook for a ward


# **grapOutlook**
> GrapOutlookOut grapOutlook(ward, days)

GRAP outlook for a ward

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getGrapApi();
final String ward = ward_example; // String | 
final int days = 56; // int | 

try {
    final response = api.grapOutlook(ward, days);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GrapApi->grapOutlook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **ward** | **String**|  | 
 **days** | **int**|  | [optional] 

### Return type

[**GrapOutlookOut**](GrapOutlookOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

