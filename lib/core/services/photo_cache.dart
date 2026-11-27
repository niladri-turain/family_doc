import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Keeps member photos on the phone after the first download, so they
/// still show without internet. A new photo gets a new URL, so a saved
/// file never goes stale.
class PhotoCache {
  PhotoCache(this._client);

  final http.Client _client;
  Directory? _dir;

  /// Downloads at most once per URL at a time.
  final _loading = <String, Future<File?>>{};

  /// The saved file, downloading it first if needed. Null when it isn't
  /// saved and can't be downloaded (offline).
  Future<File?> load(String url) =>
      _loading[url] ??= _load(url).whenComplete(() => _loading.remove(url));

  Future<File?> _load(String url) async {
    try {
      final file = await _fileFor(url);
      if (await file.exists() && await file.length() > 0) return file;
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      // Write next to it, then rename: never a half-written photo.
      final temp = File('${file.path}.part');
      await temp.writeAsBytes(response.bodyBytes, flush: true);
      return temp.rename(file.path);
    } catch (e) {
      debugPrint('Photo not available offline yet: $e');
      return null;
    }
  }

  Future<File> _fileFor(String url) async {
    final dir = _dir ??= await Directory(
      '${(await getApplicationSupportDirectory()).path}/photos',
    ).create(recursive: true);
    return File('${dir.path}/${_hash(url)}');
  }

  /// FNV-1a: a short, stable file name for the URL.
  static String _hash(String s) {
    var h = 0xcbf29ce484222325;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return h.toRadixString(16);
  }
}
