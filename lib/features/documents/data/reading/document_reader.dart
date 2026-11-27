import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'expiry_date_finder.dart';

/// What was read from a picked file.
class DocumentScan {
  const DocumentScan({required this.text, this.expiryDate});

  final String text;
  final DateTime? expiryDate;
}

/// Reads the text of a photo on the phone itself (Google ML Kit, no
/// internet) and finds the expiry date in it. Tests replace it through
/// `setupLocator`.
class DocumentReader {
  static const _images = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

  /// Null for files it can't read (PDF, Word…) or when reading fails.
  Future<DocumentScan?> read(XFile file) async {
    final name = file.name.isNotEmpty ? file.name : file.path;
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (!_images.contains(ext) || file.path.isEmpty) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      final text = result.text.trim();
      if (text.isEmpty) return null;
      return DocumentScan(text: text, expiryDate: ExpiryDateFinder.find(text));
    } catch (e) {
      debugPrint('Could not read text from $name: $e');
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
