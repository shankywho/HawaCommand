# hawa_api.model.InspectionDetailOut

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
**causeLabel** | [**CauseLabel**](CauseLabel.md) |  | 
**causeConf** | **double** |  | 
**suspectPin** | [**GeoPoint**](GeoPoint.md) |  | 
**photos** | [**List&lt;EvidencePhoto&gt;**](EvidencePhoto.md) |  | 
**isSimulated** | **bool** |  | 
**taskId** | **String** |  | [optional] 
**reportId** | **String** |  | [optional] 
**hotspotId** | **String** |  | [optional] 
**siteId** | **String** |  | [optional] 
**placeName** | [**LocalizedText**](LocalizedText.md) |  | [optional] 
**suspectRadiusM** | **double** |  | [optional] 
**backTrajectory** | [**GeoLineString**](GeoLineString.md) |  | [optional] 
**spike** | [**SpikeEvidence**](SpikeEvidence.md) |  | [optional] 
**reporter** | [**Reporter**](Reporter.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | [optional] 
**reportedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


