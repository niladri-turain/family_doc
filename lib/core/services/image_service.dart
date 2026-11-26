import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks a photo from the camera or gallery and makes sure it is a
/// JPEG / PNG / WebP of at most 2 MB, which is what the server accepts.
class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int maxBytes = 2 * 1024 * 1024; // 2 MB
  static const _accepted = {'jpg', 'jpeg', 'png', 'webp'};

  /// Returns the photo ready to upload, or null if the user cancelled.
  Future<File?> pickPhoto({required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return null;
    return prepareForUpload(File(picked.path));
  }

  /// Keeps the file if it is already accepted and ≤ 2 MB; otherwise converts
  /// it to JPEG and lowers quality / size until it is ≤ 2 MB.
  Future<File> prepareForUpload(File source) async {
    final size = await source.length();
    final ext = source.path.split('.').last.toLowerCase();
    if (size <= maxBytes && _accepted.contains(ext)) return source;

    final bytes = await _compressBelowLimit(source.path);
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(bytes, flush: true);
    debugPrint('📷 Photo optimised: ${_mb(size)} → ${_mb(bytes.length)}');
    return out;
  }

  Future<Uint8List> _compressBelowLimit(String path) async {
    const sides = [2048, 1600, 1280, 1024, 800];
    const qualities = [88, 78, 68, 58, 48];
    Uint8List? last;
    for (final side in sides) {
      for (final quality in qualities) {
        final out = await FlutterImageCompress.compressWithFile(
          path,
          minWidth: side,
          minHeight: side,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        if (out == null) continue;
        last = out;
        if (out.length <= maxBytes) return out;
      }
    }
    if (last == null) {
      throw Exception('Could not read this photo. Please choose another one.');
    }
    return last;
  }

  static String _mb(int bytes) =>
      '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}
