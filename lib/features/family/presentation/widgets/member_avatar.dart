import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Member photo (from the server URL or a just-picked file), or initials.
class MemberAvatar extends StatelessWidget {
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
    } else if (photoUrl != null && photoUrl!.startsWith('http')) {
      child = Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cache,
        errorBuilder: (_, _, _) => _initials(),
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
