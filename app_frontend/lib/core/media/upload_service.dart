import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/dio_provider.dart';
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_service.g.dart';

/// Sends bytes to a presigned target. Never carries our `Authorization` header.
// One method, but an interface on purpose: Dio and fake-backend implementations swap per mode.
// ignore: one_member_abstracts
abstract interface class ObjectUploader {
  Future<void> upload(
    PresignResult target,
    File file, {
    void Function(int sent, int total)? onProgress,
  });
}

/// Presigned POST (policy fields first, then `file`) or PUT, on the bare Dio (ARCHITECTURE §13).
class DioObjectUploader implements ObjectUploader {
  DioObjectUploader(this._dio);

  final Dio _dio;

  @override
  Future<void> upload(
    PresignResult target,
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      if (target.method == 'PUT') {
        final length = await file.length();
        await _dio.put<void>(
          target.url,
          data: file.openRead(),
          options: Options(headers: {...target.headers, Headers.contentLengthHeader: length}),
          onSendProgress: onProgress,
        );
        return;
      }
      final form = FormData.fromMap({
        ...target.fields,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'photo.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      await _dio.post<void>(target.url, data: form, onSendProgress: onProgress);
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

/// Fake S3 for fake mode: marks the key as uploaded on the fake backend.
class FakeObjectUploader implements ObjectUploader {
  FakeObjectUploader(this._backend);

  final FakeBackend _backend;

  @override
  Future<void> upload(
    PresignResult target,
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    if (_backend.offline) throw const SimulatedOfflineFailure();
    final total = file.existsSync() ? await file.length() : 0;
    for (var i = 1; i <= 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      onProgress?.call(total * i ~/ 4, total);
    }
    _backend.markUploaded(target.key);
  }
}

/// Presign at upload time (never at enqueue: the policy expires in 5 min), upload, and re-presign
/// once when the policy has expired (S3 403).
class UploadService {
  UploadService({required this.api, required this.uploader});

  final MutationApi api;
  final ObjectUploader uploader;

  /// Returns the object key.
  Future<String> upload({
    required File file,
    required String purpose,
    required String sha256,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (!file.existsSync()) throw const ValidationFailure([], code: 'media_missing');
    final length = await file.length();
    final body = {
      'purpose': purpose,
      'content_type': 'image/jpeg',
      'content_length': length,
      'sha256': sha256,
    };
    var target = await api.presign(body);
    try {
      await uploader.upload(target, file, onProgress: onProgress);
    } on ForbiddenFailure {
      target = await api.presign(body); // expired policy
      await uploader.upload(target, file, onProgress: onProgress);
    }
    return target.key;
  }
}

@Riverpod(keepAlive: true)
ObjectUploader objectUploader(Ref ref) => Env.isFake('citizen_reports') || Env.isFake('inspector')
    ? FakeObjectUploader(ref.watch(fakeBackendProvider))
    : DioObjectUploader(ref.watch(bareDioProvider));

@Riverpod(keepAlive: true)
UploadService uploadService(Ref ref) =>
    UploadService(api: ref.watch(mutationApiProvider), uploader: ref.watch(objectUploaderProvider));
