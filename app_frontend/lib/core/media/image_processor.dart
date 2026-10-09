import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hawa_app/core/utils/ids.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_processor.g.dart';

class ProcessedImage {
  const ProcessedImage({
    required this.id,
    required this.file,
    required this.sha256,
    required this.bytes,
    this.thumb,
  });

  final String id;
  final File file;
  final String sha256;
  final int bytes;
  final File? thumb;
}

/// Resize + JPEG re-encode with `keepExif: false` (ARCHITECTURE §13). Re-encoding drops all EXIF,
/// including GPS and device model; the output is checked and rejected if any EXIF survives.
class ImageProcessor {
  ImageProcessor({Future<Directory> Function()? mediaDir}) : _mediaDir = mediaDir ?? _defaultDir;

  final Future<Directory> Function() _mediaDir;

  static Future<Directory> _defaultDir() async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'media'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Long edge 1600 px, quality 80 (data saver: 1280 px, q70). Target ≤ 400 KB.
  Future<ProcessedImage> process(String inputPath, {bool dataSaver = false}) async {
    final dir = await _mediaDir();
    final id = newId();
    final out = p.join(dir.path, '$id.jpg');
    final longEdge = dataSaver ? 1280 : 1600;
    final quality = dataSaver ? 70 : 80;
    final bytes = await _encode(inputPath, out, longEdge: longEdge, quality: quality);
    if (hasExif(bytes)) {
      await File(out).delete();
      throw StateError('EXIF survived re-encoding');
    }
    final thumbPath = p.join(dir.path, '${id}_thumb.jpg');
    File? thumb;
    try {
      await _encode(out, thumbPath, longEdge: 320, quality: 70);
      thumb = File(thumbPath);
    } on Object {
      thumb = null;
    }
    return ProcessedImage(
      id: id,
      file: File(out),
      sha256: sha256.convert(bytes).toString(),
      bytes: bytes.length,
      thumb: thumb,
    );
  }

  /// 413 fallback: 1280 px, q70 next to the original.
  Future<File?> recompressSmaller(File original) async {
    final out = original.path.replaceFirst(RegExp(r'\.jpg$'), '_small.jpg');
    try {
      await _encode(original.path, out, longEdge: 1280, quality: 70);
      return File(out);
    } on Object {
      return null;
    }
  }

  Future<Uint8List> _encode(
    String input,
    String output, {
    required int longEdge,
    required int quality,
  }) async {
    final (w, h) = await _size(input);
    final scale = w == 0 || h == 0 ? 1.0 : longEdge / (w > h ? w : h);
    final targetW = scale < 1 ? (w * scale).round() : w;
    final targetH = scale < 1 ? (h * scale).round() : h;
    final result = await FlutterImageCompress.compressAndGetFile(
      input,
      output,
      minWidth: targetW == 0 ? longEdge : targetW,
      minHeight: targetH == 0 ? longEdge : targetH,
      quality: quality,
    );
    if (result == null) throw StateError('image compression failed');
    return result.readAsBytes();
  }

  static Future<(int, int)> _size(String path) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = (descriptor.width, descriptor.height);
    descriptor.dispose();
    buffer.dispose();
    return size;
  }

  /// True when a JPEG carries an APP1 `Exif\0\0` segment (GPS, Make, Model live there).
  static bool hasExif(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return false;
    var i = 2;
    while (i + 4 <= bytes.length) {
      if (bytes[i] != 0xFF) return false;
      final marker = bytes[i + 1];
      if (marker == 0xDA || marker == 0xD9) return false; // start of scan / end of image
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      if (marker == 0xE1 && i + 10 <= bytes.length) {
        const exif = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
        var match = true;
        for (var k = 0; k < exif.length; k++) {
          if (bytes[i + 4 + k] != exif[k]) {
            match = false;
            break;
          }
        }
        if (match) return true;
      }
      i += 2 + length;
    }
    return false;
  }
}

@Riverpod(keepAlive: true)
ImageProcessor imageProcessor(Ref ref) => ImageProcessor();
