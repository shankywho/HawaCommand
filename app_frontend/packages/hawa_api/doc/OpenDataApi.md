# hawa_api.api.OpenDataApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**openAir**](OpenDataApi.md#openair) | **GET** /open/v1/air | Coarse open air data


# **openAir**
> OpenAirOut openAir(bbox, includeSimulated)

Coarse open air data

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getOpenDataApi();
final String bbox = bbox_example; // String | 
final bool includeSimulated = true; // bool | 

try {
    final response = api.openAir(bbox, includeSimulated);
    print(response);
} catch on DioException (e) {
    print('Exception when calling OpenDataApi->openAir: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bbox** | **String**|  | [optional] 
 **includeSimulated** | **bool**|  | [optional] 

### Return type

[**OpenAirOut**](OpenAirOut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

