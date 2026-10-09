# hawa_api.api.MeApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**meGet**](MeApi.md#meget) | **GET** /v1/me | Current user
[**meGetAlertSubscription**](MeApi.md#megetalertsubscription) | **GET** /v1/me/alert-subscription | Citizen alert area (proposed)
[**mePatch**](MeApi.md#mepatch) | **PATCH** /v1/me | Update language / notification prefs (proposed)
[**mePutAlertSubscription**](MeApi.md#meputalertsubscription) | **PUT** /v1/me/alert-subscription | Set citizen alert area (proposed)
[**mePutPushToken**](MeApi.md#meputpushtoken) | **PUT** /v1/me/push-token | Register a push token


# **meGet**
> MeOut meGet()

Current user

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getMeApi();

try {
    final response = api.meGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeApi->meGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MeOut**](MeOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **meGetAlertSubscription**
> AlertSubscription meGetAlertSubscription()

Citizen alert area (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getMeApi();

try {
    final response = api.meGetAlertSubscription();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeApi->meGetAlertSubscription: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AlertSubscription**](AlertSubscription.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mePatch**
> MeOut mePatch(mePatchIn, idempotencyKey)

Update language / notification prefs (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getMeApi();
final MePatchIn mePatchIn = ; // MePatchIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.mePatch(mePatchIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeApi->mePatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mePatchIn** | [**MePatchIn**](MePatchIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**MeOut**](MeOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mePutAlertSubscription**
> AlertSubscription mePutAlertSubscription(alertSubscription, idempotencyKey)

Set citizen alert area (proposed)

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getMeApi();
final AlertSubscription alertSubscription = ; // AlertSubscription | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.mePutAlertSubscription(alertSubscription, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeApi->mePutAlertSubscription: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **alertSubscription** | [**AlertSubscription**](AlertSubscription.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**AlertSubscription**](AlertSubscription.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mePutPushToken**
> PushTokenOut mePutPushToken(pushTokenIn)

Register a push token

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getMeApi();
final PushTokenIn pushTokenIn = ; // PushTokenIn | 

try {
    final response = api.mePutPushToken(pushTokenIn);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MeApi->mePutPushToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pushTokenIn** | [**PushTokenIn**](PushTokenIn.md)|  | 

### Return type

[**PushTokenOut**](PushTokenOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

