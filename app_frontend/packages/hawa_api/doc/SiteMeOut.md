# hawa_api.model.SiteMeOut

## Load the model package
```dart
import 'package:hawa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**siteId** | **String** |  | 
**type** | [**SiteType**](SiteType.md) |  | 
**name** | **String** |  | 
**grade** | [**SiteGrade**](SiteGrade.md) |  | 
**isSimulated** | **bool** |  | 
**wardId** | **String** |  | [optional] 
**placeName** | [**LocalizedText**](LocalizedText.md) |  | [optional] 
**gradeSince** | [**DateTime**](DateTime.md) |  | [optional] 
**score** | **double** |  | [optional] 
**violations** | **int** |  | [optional] 
**flags30d** | **int** |  | [optional] 
**lastInspectionAt** | [**DateTime**](DateTime.md) |  | [optional] 
**pm10Trend** | [**List&lt;Pm10TrendPoint&gt;**](Pm10TrendPoint.md) |  | [optional] 
**components** | [**List&lt;SiteScoreComponent&gt;**](SiteScoreComponent.md) |  | [optional] 
**tips** | [**List&lt;LocalizedText&gt;**](LocalizedText.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


