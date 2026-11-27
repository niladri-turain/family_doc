import 'dart:convert';
import 'dart:io';

import 'package:family_doc/features/documents/data/models/saved_document.dart';
import 'package:family_doc/features/documents/presentation/providers/document_provider.dart';
import 'package:family_doc/features/documents/presentation/widgets/document_thumbnail.dart';
import 'package:family_doc/features/documents/presentation/widgets/file_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_documents.dart';

/// Saved files live in a real temp folder so images can be decoded.
class _DiskStore extends MemoryDocumentStore {
  _DiskStore(this.dir);
  final Directory dir;

  @override
  Future<String> pathOf(SavedDocument document) async =>
      '${dir.path}/${document.storedName}';
}

SavedDocument _doc(String storedName) => SavedDocument(
  id: storedName,
  memberId: 1,
  categoryId: 1,
  customCategory: false,
  name: storedName,
  fileName: storedName,
  storedName: storedName,
  size: 70,
  createdAt: DateTime(2026),
);

// 1×1 PNG
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('thumb'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, SavedDocument document) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DocumentProvider(store: _DiskStore(dir)),
        child: MaterialApp(
          home: Center(child: DocumentThumbnail(document: document)),
        ),
      ),
    );
    // Let the file be read and decoded for real (stops once the preview is up).
    for (
      var i = 0;
      i < 30 && find.byType(FileBadge).evaluate().isNotEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  testWidgets('a saved photo shows a preview with its type', (tester) async {
    await tester.runAsync(
      () => File('${dir.path}/card.png').writeAsBytes(_png),
    );
    await show(tester, _doc('card.png'));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(FileBadge), findsNothing);
    expect(find.text('PNG'), findsOneWidget);
  });

  testWidgets('a PDF or a missing photo shows the type badge', (tester) async {
    await show(tester, _doc('marks.pdf'));
    expect(find.byType(FileBadge), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);

    await show(tester, _doc('gone.jpg'));
    expect(find.byType(FileBadge), findsOneWidget);
    expect(find.text('JPG'), findsOneWidget);
  });
}
