# hawa_api.model.ReportDetailOut

## Load the model package
```dart
import 'package:hawa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**status** | [**ReportStatus**](ReportStatus.md) |  | 
**location** | [**GeoPoint**](GeoPoint.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**timeline** | [**List&lt;ReportTimelineEntry&gt;**](ReportTimelineEntry.md) |  | 
**isSimulated** | **bool** |  | 
**clientReportId** | **String** |  | [optional] 
**source_** | [**ReportSource**](ReportSource.md) |  | [optional] 
**accuracyM** | **double** |  | [optional] 
**wardId** | **String** |  | [optional] 
**cellId** | **String** |  | [optional] 
**placeName** | [**LocalizedText**](LocalizedText.md) |  | [optional] 
**note** | **String** |  | [optional] 
**lang** | [**Lang**](Lang.md) |  | [optional] 
**category** | [**ReportCategory**](ReportCategory.md) |  | [optional] 
**capturedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**photoUrl** | **String** |  | [optional] 
**verification** | [**ReportVerification**](ReportVerification.md) |  | [optional] 
**inspection** | [**ReportInspection**](ReportInspection.md) |  | [optional] 
**outcome** | [**InspectionOutcome**](InspectionOutcome.md) |  | [optional] 
**outcomeText** | **String** |  | [optional] 
**outcomeTextHi** | **String** |  | [optional] 
**rejectionReason** | **String** |  | [optional] 
**rejectionReasonHi** | **String** |  | [optional] 
**closedAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


