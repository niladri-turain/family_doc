import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/photo_cache.dart';

/// Member photo (from the server URL or a just-picked file), or initials.
/// Server photos are saved on the phone ([PhotoCache]) so they also show
/// without internet.
class MemberAvatar extends StatefulWidget {
  const MemberAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.photoUrl,
    this.photoFile,
    this.size = 50,
    this.circle = false,
  });

  final String initials;
  final CategoryColor color;
  final String? photoUrl;
  final File? photoFile;
  final double size;
  final bool circle;

  @override
  State<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<MemberAvatar> {
  Future<File?>? _saved;
  String? _url;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolve();
  }

  void _resolve() {
    final url = widget.photoUrl;
    if (url == _url) return;
    _url = url;
    _saved = (url != null && url.startsWith('http'))
        ? sl<PhotoCache>().load(url)
        : null;
  }

  String get initials => widget.initials;
  CategoryColor get color => widget.color;
  File? get photoFile => widget.photoFile;
  double get size => widget.size;
  bool get circle => widget.circle;

  @override
  Widget build(BuildContext context) {
    final cache = (size * 3).round();
    Widget child = _initials();
    if (photoFile != null) {
      child = Image.file(
        photoFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cache,
        errorBuilder: (_, _, _) => _initials(),
      );
    } else if (_saved != null) {
      child = FutureBuilder<File?>(
        future: _saved,
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (file == null) return _initials();
          return Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: cache,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _initials(),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(circle ? size / 2 : size * 0.32),
      child: Container(
        width: size,
        height: size,
        color: color.background,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _initials() => initials.isEmpty
      ? Icon(
          Icons.person_outline_rounded,
          size: size * 0.45,
          color: color.foreground,
        )
      : Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            color: color.foreground,
          ),
        );
}
