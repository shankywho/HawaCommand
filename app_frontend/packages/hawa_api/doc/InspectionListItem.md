# hawa_api.model.InspectionListItem

## Load the model package
```dart
import 'package:hawa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**status** | [**InspectionStatus**](InspectionStatus.md) |  | 
**origin** | [**InspectionOrigin**](InspectionOrigin.md) |  | 
**priority** | **int** |  | 
**target** | [**GeoPoint**](GeoPoint.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**isSimulated** | **bool** |  | 
**wardId** | **String** |  | [optional] 
**cellId** | **String** |  | [optional] 
**reportId** | **String** |  | [optional] 
**hotspotId** | **String** |  | [optional] 
**taskId** | **String** |  | [optional] 
**siteId** | **String** |  | [optional] 
**placeName** | [**LocalizedText**](LocalizedText.md) |  | [optional] 
**causeLabel** | [**CauseLabel**](CauseLabel.md) |  | [optional] 
**causeConf** | **double** |  | [optional] 
**evidenceSummary** | [**EvidenceSummary**](EvidenceSummary.md) |  | [optional] 
**assignedTeamAssetId** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


