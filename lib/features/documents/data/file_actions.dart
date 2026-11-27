import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

enum FileSource { camera, gallery, files }

/// Picks a file to save, opens a saved file in the phone's viewer and
/// shares it (WhatsApp, Mail…). Tests replace it through `setupLocator`.
class FileActions {
  static const allowedExtensions = [
    'pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp', //
    'doc', 'docx', 'xls', 'xlsx', 'txt',
  ];

  /// Null when the user cancels.
  Future<XFile?> pick(FileSource source) async {
    switch (source) {
      case FileSource.camera:
      case FileSource.gallery:
        return ImagePicker().pickImage(
          source: source == FileSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 2400,
          maxHeight: 2400,
        );
      case FileSource.files:
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
        return files.isEmpty ? null : files.first.xFile;
    }
  }

  /// Returns an error message, or null when the file opened.
  Future<String?> open(String path) async {
    final result = await OpenFilex.open(path);
    return switch (result.type) {
      ResultType.done => null,
      ResultType.noAppToOpen => 'No app on this phone can open this file.',
      ResultType.fileNotFound => 'This file is missing from the phone.',
      _ => 'Could not open this file.',
    };
  }

  /// [origin] is where the share popover points on iPad.
  Future<void> share(String path, {required String name, Rect? origin}) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: name,
          sharePositionOrigin: origin,
        ),
      );
}
