# hawa_api.api.TasksApi

## Load the API package
```dart
import 'package:hawa_api/api.dart';
```

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**tasksAck**](TasksApi.md#tasksack) | **POST** /v1/tasks/{id}/ack | Acknowledge a task
[**tasksGet**](TasksApi.md#tasksget) | **GET** /v1/tasks/{id} | One task
[**tasksMine**](TasksApi.md#tasksmine) | **GET** /v1/tasks/mine | Today&#39;s tasks for the caller
[**tasksUpdateStatus**](TasksApi.md#tasksupdatestatus) | **POST** /v1/tasks/{id}/status | Field status update


# **tasksAck**
> TaskAckOut tasksAck(id, taskAckIn, idempotencyKey)

Acknowledge a task

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getTasksApi();
final String id = id_example; // String | 
final TaskAckIn taskAckIn = ; // TaskAckIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.tasksAck(id, taskAckIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TasksApi->tasksAck: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **taskAckIn** | [**TaskAckIn**](TaskAckIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**TaskAckOut**](TaskAckOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **tasksGet**
> TaskItem tasksGet(id)

One task

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getTasksApi();
final String id = id_example; // String | 

try {
    final response = api.tasksGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TasksApi->tasksGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**TaskItem**](TaskItem.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **tasksMine**
> TasksMineOut tasksMine(date)

Today's tasks for the caller

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getTasksApi();
final String date = date_example; // String | IST service date YYYY-MM-DD

try {
    final response = api.tasksMine(date);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TasksApi->tasksMine: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **String**| IST service date YYYY-MM-DD | [optional] 

### Return type

[**TasksMineOut**](TasksMineOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **tasksUpdateStatus**
> TaskStatusOut tasksUpdateStatus(id, taskStatusIn, idempotencyKey)

Field status update

### Example
```dart
import 'package:hawa_api/api.dart';

final api = HawaApi().getTasksApi();
final String id = id_example; // String | 
final TaskStatusIn taskStatusIn = ; // TaskStatusIn | 
final String idempotencyKey = idempotencyKey_example; // String | UUIDv7 op id; stable across retries

try {
    final response = api.tasksUpdateStatus(id, taskStatusIn, idempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TasksApi->tasksUpdateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **taskStatusIn** | [**TaskStatusIn**](TaskStatusIn.md)|  | 
 **idempotencyKey** | **String**| UUIDv7 op id; stable across retries | [optional] 

### Return type

[**TaskStatusOut**](TaskStatusOut.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

