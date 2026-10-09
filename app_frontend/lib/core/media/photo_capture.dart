import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_capture.g.dart';

/// Camera-only capture via the system camera intent (no gallery for evidence; ARCHITECTURE §13).
class PhotoCapture {
  PhotoCapture([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns the captured file path, or null when the user backed out.
  Future<String?> capture() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      requestFullMetadata: false,
    );
    return file?.path;
  }

  /// On low-RAM phones Android may kill the activity while the camera is open; the photo is
  /// recovered here on the next start and the draft resumes.
  Future<String?> retrieveLost() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    return response.file?.path;
  }
}

@Riverpod(keepAlive: true)
PhotoCapture photoCapture(Ref ref) => PhotoCapture();
