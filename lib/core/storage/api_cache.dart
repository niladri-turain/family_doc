import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// The last answer of each server call (members, categories, types,
/// profile), saved on the phone so the app still opens without internet.
/// [HiveApiCache] on the phone; tests pass [MemoryApiCache].
abstract class ApiCache {
  /// The saved JSON for [key], or null.
  Future<dynamic> read(String key);

  Future<void> write(String key, Object? data);

  /// On logout: the next user must not see these.
  Future<void> clear();
}

/// Hive box "api_cache": key → JSON text.
class HiveApiCache implements ApiCache {
  static const _boxName = 'api_cache';

  Box<String>? _box;

  Future<Box<String>> _openBox() async {
    final box = _box;
    if (box != null) return box;
    await Hive.initFlutter();
    return _box = await Hive.openBox<String>(_boxName);
  }

  @override
  Future<dynamic> read(String key) async {
    try {
      final text = (await _openBox()).get(key);
      return text == null ? null : jsonDecode(text);
    } catch (e) {
      debugPrint('Could not read saved $key: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? data) async {
    try {
      await (await _openBox()).put(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Could not save $key: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await (await _openBox()).clear();
    } catch (e) {
      debugPrint('Could not clear saved data: $e');
    }
  }
}

/// In memory (tests).
class MemoryApiCache implements ApiCache {
  final data = <String, String>{};

  @override
  Future<dynamic> read(String key) async =>
      data[key] == null ? null : jsonDecode(data[key]!);

  @override
  Future<void> write(String key, Object? value) async =>
      data[key] = jsonEncode(value);

  @override
  Future<void> clear() async => data.clear();
}
