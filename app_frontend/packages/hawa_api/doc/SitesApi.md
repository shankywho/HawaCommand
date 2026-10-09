# hawa_api.api.SitesApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**sitesMe**](SitesApi.md#sitesme) | **GET** /v1/sites/me | The caller&#39;s site


# **sitesMe**
> SiteMeOut sitesMe()

The caller's site

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getSitesApi();

try {
    final response = api.sitesMe();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SitesApi->sitesMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SiteMeOut**](SiteMeOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

