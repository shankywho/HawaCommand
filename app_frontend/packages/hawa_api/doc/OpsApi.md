# hawa_api.api.OpsApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**opsHealthz**](OpsApi.md#opshealthz) | **GET** /healthz | Liveness


# **opsHealthz**
> Health opsHealthz()

Liveness

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getOpsApi();

try {
    final response = api.opsHealthz();
    print(response);
} catch on DioException (e) {
    print('Exception when calling OpsApi->opsHealthz: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Health**](Health.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

