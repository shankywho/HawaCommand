# hawa_api.model.TaskItem

## Load the model package
```dart
import 'package:hawa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**kind** | [**TaskKind**](TaskKind.md) |  | 
**status** | [**TaskStatus**](TaskStatus.md) |  | 
**sequence** | **int** |  | 
**location** | [**GeoPoint**](GeoPoint.md) |  | 
**placeName** | [**LocalizedText**](LocalizedText.md) |  | 
**windowStart** | [**DateTime**](DateTime.md) |  | 
**windowEnd** | [**DateTime**](DateTime.md) |  | 
**version** | **int** |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**isSimulated** | **bool** |  | 
**planId** | **String** |  | [optional] 
**cellId** | **String** |  | [optional] 
**instructions** | [**LocalizedText**](LocalizedText.md) |  | [optional] 
**targetLitres** | **double** |  | [optional] 
**segmentLengthM** | **double** |  | [optional] 
**durationMin** | **int** |  | [optional] 
**arrivalRadiusM** | **double** |  | [optional] 
**causeLabel** | [**CauseLabel**](CauseLabel.md) |  | [optional] 
**causeConf** | **double** |  | [optional] 
**reasonText** | [**LocalizedText**](LocalizedText.md) |  | [optional] 
**completionSource** | [**InterventionSource**](InterventionSource.md) |  | [optional] 
**interventionId** | **String** |  | [optional] 
**litres** | **double** |  | [optional] 
**impactSummary** | [**ImpactSummary**](ImpactSummary.md) |  | [optional] 
**skipReason** | [**SkipReason**](SkipReason.md) |  | [optional] 
**inspectionId** | **String** |  | [optional] 
**origin** | [**InspectionOrigin**](InspectionOrigin.md) |  | [optional] 
**priority** | **int** |  | [optional] 
**hotspotId** | **String** |  | [optional] 
**reportId** | **String** |  | [optional] 
**siteId** | **String** |  | [optional] 
**suspectPin** | [**GeoPoint**](GeoPoint.md) |  | [optional] 
**history** | [**List&lt;TaskHistoryEntry&gt;**](TaskHistoryEntry.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


