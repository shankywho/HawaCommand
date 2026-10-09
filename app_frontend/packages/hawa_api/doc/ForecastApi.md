# hawa_api.api.ForecastApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**forecastGet**](ForecastApi.md#forecastget) | **GET** /v1/forecast/{cell_id} | 72 h forecast for a cell


# **forecastGet**
> ForecastCellOut forecastGet(cellId, pollutant)

72 h forecast for a cell

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getForecastApi();
final String cellId = cellId_example; // String | 
final String pollutant = pollutant_example; // String | 

try {
    final response = api.forecastGet(cellId, pollutant);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ForecastApi->forecastGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cellId** | **String**|  | 
 **pollutant** | **String**|  | [optional] 

### Return type

[**ForecastCellOut**](ForecastCellOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

