import 'package:family_doc/features/assistant/data/assistant_engine.dart';
import 'package:family_doc/features/assistant/data/local_assistant.dart';
import 'package:family_doc/features/categories/data/models/document_category.dart';
import 'package:family_doc/features/documents/data/models/saved_document.dart';
import 'package:family_doc/features/family/data/models/family_member.dart';
import 'package:family_doc/features/family/data/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

SavedDocument doc(
  String id,
  int member,
  String name, {
  String? type,
  DateTime? expiry,
  String? text,
  int category = 1,
}) => SavedDocument(
  id: id,
  memberId: member,
  categoryId: category,
  customCategory: false,
  name: name,
  typeName: type,
  fileName: '$name.jpg',
  storedName: '$id/$name.jpg',
  size: 1000,
  createdAt: DateTime(2026, 1, int.parse(id)),
  expiryDate: expiry,
  text: text,
);

void main() {
  final now = DateTime(2026, 11, 27);
  final data = AssistantData(
    members: const [
      FamilyMember(id: 1, fullName: 'Niladri Roy', relation: Relation.self),
      FamilyMember(id: 2, fullName: 'Sunil Roy', relation: Relation.father),
      FamilyMember(id: 3, fullName: 'Rina Roy', relation: Relation.mother),
    ],
    categories: const [
      DocumentCategory(id: 1, name: 'Identity'),
      DocumentCategory(id: 2, name: 'Vehicle'),
      DocumentCategory(id: 3, name: 'Education'),
    ],
    documents: [
      doc(
        '1',
        1,
        'RC',
        type: 'Registration Certificate',
        category: 2,
        expiry: DateTime(2031, 3, 13),
        text: 'Registration No WB02AB1234',
      ),
      doc('2', 2, 'Aadhaar Card', type: 'Aadhaar'),
      doc('3', 3, 'Passport', expiry: DateTime(2026, 12, 10)),
      doc(
        '4',
        1,
        'Driving Licence',
        category: 2,
        expiry: DateTime(2025, 10, 10),
      ),
      doc('5', 1, 'Graduation Marksheet', category: 3),
    ],
  );

  Future<AssistantReply> ask(String q) =>
      const LocalAssistant().answer(q, data, now: now);
  List<String> ids(AssistantReply r) => [for (final d in r.documents) d.id];

  test('Banglish: when does my RC expire', () async {
    final r = await ask('amar rc kobe expire hobe?');
    expect(ids(r), ['1']);
    expect(r.text, 'Tomar RC 13 Mar 2031 e expire hobe (aar 1567 din baki).');
  });

  test('English: when does my RC expire', () async {
    final r = await ask('When does my RC expire?');
    expect(ids(r), ['1']);
    expect(r.text, 'Your RC expires on 13 Mar 2031 (in 1567 days).');
  });

  test('Bengali script', () async {
    final r = await ask('আমার আরসি কবে শেষ হবে');
    expect(ids(r), ['1']);
    expect(r.text, contains('13 Mar 2031'));
  });

  test("Father's Aadhaar, by relation or by name", () async {
    var r = await ask('babar aadhaar card dao');
    expect(ids(r), ['2']);
    expect(r.text, 'Ei nao Sunil Roy-er Aadhaar Card.');
    r = await ask("Show Sunil's adhar");
    expect(ids(r), ['2']);
    expect(r.text, "Here is Sunil Roy's Aadhaar Card.");
  });

  test('Expiring soon: expired and within 60 days, not later', () async {
    final r = await ask("What's expiring soon?");
    expect(ids(r), ['4', '3']);
    expect(r.text, contains('2 documents need attention'));
    expect(r.text, contains('Your Driving Licence expired on 10 Oct 2025'));
    expect(r.text, contains("Rina Roy's Passport expires on 10 Dec 2026"));
  });

  test("A member's documents", () async {
    final r = await ask('mayer sob document dekhao');
    expect(ids(r), ['3']);
    final mine = await ask('show my documents');
    expect(ids(mine), ['5', '4', '1']);
  });

  test('Not found in that member, and a missing relation', () async {
    var r = await ask('my passport');
    expect(r.documents, isEmpty);
    expect(r.text, contains('couldn\'t find "passport" in your documents'));
    r = await ask("wife's aadhaar");
    expect(r.documents, isEmpty);
    expect(r.text, contains("couldn't find your spouse in My Family"));
  });

  test('Typos, text read from the file, and no expiry date', () async {
    expect(ids(await ask('marksheat')), ['5']);
    expect(ids(await ask('WB02AB1234')), ['1']);
    final r = await ask('When does my marksheet expire?');
    expect(r.text, contains('has no expiry date saved'));
  });

  test('Greeting shows help with suggestions', () async {
    final r = await ask('hello');
    expect(r.documents, isEmpty);
    expect(r.suggestions, contains("What's expiring soon?"));
    expect(r.suggestions, contains("Show Baba's documents"));
  });

  test('"sob"/"all" lists documents, it does not mean expiring', () async {
    final r = await ask('Niladri er sob documents');
    expect(ids(r), ['5', '4', '1']);
    expect(r.text, 'Tomar 3 ta document:');
    expect(ids(await ask('all documents of Sunil')), ['2']);
  });

  test('Filler words do not break the search', () async {
    expect(ids(await ask('which documents expire this month')), ['4', '3']);
    expect(ids(await ask('amar rc er kagoj ta dao please')), ['1']);
  });

  test('Follow-up chips are in the user\'s voice', () async {
    var r = await ask('find my rc');
    expect(r.suggestions, ['When does my RC expire?']);
    r = await ask('amar rc dao');
    expect(r.suggestions, ['Amar RC kobe expire hobe?']);
    r = await ask("Rina's passport");
    expect(r.suggestions, ["When does Rina Roy's Passport expire?"]);
    // …and asking it works
    expect(ids(await ask(r.suggestions.single)), ['3']);
  });

  group('English questions', () {
    test('all documents', () async {
      expect(ids(await ask('Show all documents')), ['5', '4', '3', '2', '1']);
      expect(ids(await ask('list everything')), ['5', '4', '3', '2', '1']);
    });

    test(
      'days left, renewal, and "registration certificate" as one RC',
      () async {
        expect(
          (await ask('How many days left for my RC?')).text,
          'Your RC expires on 13 Mar 2031 (in 1567 days).',
        );
        expect(ids(await ask('When is my RC renewal due?')), ['1']);
        expect(ids(await ask('When will my registration certificate expire')), [
          '1',
        ]);
      },
    );

    test('has it expired? yes / no', () async {
      expect(
        (await ask('Is my driving licence expired?')).text,
        startsWith('Yes. Your Driving Licence expired on 10 Oct 2025'),
      );
      expect(
        (await ask('Is my RC expired?')).text,
        startsWith('No. Your RC expires on 13 Mar 2031'),
      );
      final r = await ask('Which documents have expired?');
      expect(ids(r), ['4']);
      expect(r.text, startsWith('1 document has expired:'));
    });

    test('this week / this month', () async {
      // The passport (13 days) is outside a week; the expired licence
      // still needs attention.
      final week = await ask('Is anything expiring this week?');
      expect(week.text, startsWith('1 document needs attention:'));
      expect(ids(week), ['4']);
      expect(ids(await ask('What expires this month?')), ['4', '3']);
    });

    test('plurals and thanks', () async {
      expect(ids(await ask('Send me my marksheets')), ['5']);
      final r = await ask('Thanks!');
      expect(r.text, startsWith("You're welcome!"));
      expect(r.documents, isEmpty);
    });
  });

  test('Short Banglish is answered in Banglish', () async {
    expect(
      (await ask('ki ki expire hocche?')).text,
      startsWith('2 ta document er meyad shesh hocche'),
    );
    expect((await ask('dhonnobad')).text, startsWith('Thik ache!'));
    expect(
      (await ask('amar marksheet gulo dao')).text,
      'Ei nao tomar Graduation Marksheet.',
    );
    expect((await ask('passport ar licence dao')).text, startsWith('Family te'));
  });
}
