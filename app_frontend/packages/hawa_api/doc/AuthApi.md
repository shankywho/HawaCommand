# hawa_api.api.AuthApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authLogout**](AuthApi.md#authlogout) | **POST** /v1/auth/logout | Revoke the refresh family
[**authOtpRequest**](AuthApi.md#authotprequest) | **POST** /v1/auth/otp/request | Request an OTP
[**authOtpVerify**](AuthApi.md#authotpverify) | **POST** /v1/auth/otp/verify | Verify an OTP
[**authRefresh**](AuthApi.md#authrefresh) | **POST** /v1/auth/refresh | Rotate tokens
[**authSwitchRole**](AuthApi.md#authswitchrole) | **POST** /v1/auth/switch-role | Reissue tokens for another role


# **authLogout**
> authLogout(logoutIn)

Revoke the refresh family

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAuthApi();
final LogoutIn logoutIn = ; // LogoutIn | 

try {
    api.authLogout(logoutIn);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authLogout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logoutIn** | [**LogoutIn**](LogoutIn.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authOtpRequest**
> OtpRequestOut authOtpRequest(otpRequestIn)

Request an OTP

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAuthApi();
final OtpRequestIn otpRequestIn = ; // OtpRequestIn | 

try {
    final response = api.authOtpRequest(otpRequestIn);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authOtpRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **otpRequestIn** | [**OtpRequestIn**](OtpRequestIn.md)|  | 

### Return type

[**OtpRequestOut**](OtpRequestOut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authOtpVerify**
> TokenResponse authOtpVerify(otpVerifyIn)

Verify an OTP

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAuthApi();
final OtpVerifyIn otpVerifyIn = ; // OtpVerifyIn | 

try {
    final response = api.authOtpVerify(otpVerifyIn);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authOtpVerify: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **otpVerifyIn** | [**OtpVerifyIn**](OtpVerifyIn.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authRefresh**
> TokenResponse authRefresh(refreshIn)

Rotate tokens

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAuthApi();
final RefreshIn refreshIn = ; // RefreshIn | 

try {
    final response = api.authRefresh(refreshIn);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authRefresh: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshIn** | [**RefreshIn**](RefreshIn.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authSwitchRole**
> TokenResponse authSwitchRole(switchRoleIn)

Reissue tokens for another role

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getAuthApi();
final SwitchRoleIn switchRoleIn = ; // SwitchRoleIn | 

try {
    final response = api.authSwitchRole(switchRoleIn);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authSwitchRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **switchRoleIn** | [**SwitchRoleIn**](SwitchRoleIn.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

