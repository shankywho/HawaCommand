# hawa_api.api.UploadsApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**uploadsPresign**](UploadsApi.md#uploadspresign) | **POST** /v1/uploads/presign | Presign an upload


# **uploadsPresign**
> PresignOut uploadsPresign(presignIn)

Presign an upload

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getUploadsApi();
final PresignIn presignIn = ; // PresignIn | 

try {
    final response = api.uploadsPresign(presignIn);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UploadsApi->uploadsPresign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **presignIn** | [**PresignIn**](PresignIn.md)|  | 

### Return type

[**PresignOut**](PresignOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

