# hawa_api.model.AlertItem

## Load the model package
```dart
import 'package:hawa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**audience** | [**AlertAudience**](AlertAudience.md) |  | 
**kind** | [**AlertKind**](AlertKind.md) |  | 
**status** | [**AlertStatus**](AlertStatus.md) |  | 
**lang** | [**Lang**](Lang.md) |  | 
**title** | **String** |  | 
**body** | **String** |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**isSimulated** | **bool** |  | 
**channels** | [**List&lt;AlertChannel&gt;**](AlertChannel.md) |  | [optional] 
**pollutant** | [**Pollutant**](Pollutant.md) |  | [optional] 
**wardId** | **String** |  | [optional] 
**cellId** | **String** |  | [optional] 
**planId** | **String** |  | [optional] 
**taskId** | **String** |  | [optional] 
**reportId** | **String** |  | [optional] 
**schoolId** | **String** |  | [optional] 
**deepLink** | **String** |  | [optional] 
**origin** | **String** |  | [optional] 
**args** | **Map&lt;String, String&gt;** |  | [optional] 
**sentAt** | [**DateTime**](DateTime.md) |  | [optional] 
**readAt** | [**DateTime**](DateTime.md) |  | [optional] 
**ackedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**expiresAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


