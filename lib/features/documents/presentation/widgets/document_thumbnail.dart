import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/saved_document.dart';
import '../providers/document_provider.dart';
import 'file_badge.dart';

/// A photo of the saved file (JPG, PNG, WEBP, HEIC) so documents are easy
/// to tell apart, with the file type in a small label. PDFs and other
/// files, and any image that can't be read, show the [FileBadge].
class DocumentThumbnail extends StatefulWidget {
  const DocumentThumbnail({super.key, required this.document, this.size = 46});

  final SavedDocument document;
  final double size;

  @override
  State<DocumentThumbnail> createState() => _DocumentThumbnailState();
}

class _DocumentThumbnailState extends State<DocumentThumbnail> {
  Future<String>? _path;
  String? _storedName;

  bool get _isImage =>
      FileBadge.images.contains(widget.document.extension.toLowerCase());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(DocumentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolve();
  }

  /// Looks the path up again only when the file moved (rename).
  void _resolve() {
    final name = widget.document.storedName;
    if (!_isImage || name == _storedName) return;
    _storedName = name;
    _path = context.read<DocumentProvider>().pathOf(widget.document);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final badge = FileBadge(extension: widget.document.extension, size: size);
    final path = _path;
    if (!_isImage || path == null) return badge;
    final ext = widget.document.extension.toLowerCase();
    final label = ext == 'jpeg' ? 'JPG' : ext.toUpperCase();

    return FutureBuilder<String>(
      future: path,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return badge;
        return SizedBox(
          width: size,
          height: size * 1.15,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(file),
              fit: BoxFit.cover,
              // Decode small: a 46 pt tile doesn't need the full photo.
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              gaplessPlayback: true,
              semanticLabel: '${widget.document.name} preview',
              // Badge until the photo is ready, and if it can't be read.
              frameBuilder: (context, child, frame, synchronous) =>
                  frame == null && !synchronous
                  ? badge
                  : Stack(
                      fit: StackFit.expand,
                      children: [child, _typeLabel(label, size)],
                    ),
              errorBuilder: (_, _, _) => badge,
            ),
          ),
        );
      },
    );
  }

  Widget _typeLabel(String label, double size) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: const Color(0x99000000),
      child: Text(
        label.length > 4 ? label.substring(0, 4) : label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size * 0.19,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    ),
  );
}
