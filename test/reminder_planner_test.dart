import 'package:family_doc/features/documents/data/models/saved_document.dart';
import 'package:family_doc/features/reminders/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

SavedDocument doc(String id, DateTime? expiry) => SavedDocument(
  id: id,
  memberId: 1,
  categoryId: 1,
  customCategory: false,
  name: 'RC $id',
  fileName: 'rc.jpg',
  storedName: '$id/rc.jpg',
  size: 1,
  createdAt: DateTime(2026),
  expiryDate: expiry,
);

void main() {
  final now = DateTime(2026, 11, 27, 12);

  test('30, 7, 1 day before and on the day at 10 am, only ahead', () {
    final plan = ReminderPlanner.plan(
      [doc('1', DateTime(2026, 12, 4)), doc('2', null)],
      ownerOf: (_) => "Sunil Roy's",
      now: now,
    );
    // 30 days before (4 Nov) is past; the 7-day one is 27 Nov 10 am, past.
    expect(plan.map((r) => r.at), [
      DateTime(2026, 12, 3, 10),
      DateTime(2026, 12, 4, 10),
    ]);
    expect(plan.first.title, 'RC 1 expires tomorrow');
    expect(
      plan.first.body,
      "Sunil Roy's RC 1 is valid until 4 Dec 2026. Renew it in time.",
    );
  });

  test('soonest first, capped for iOS', () {
    final docs = [
      for (var i = 0; i < 30; i++) doc('$i', DateTime(2027, 1, 1 + i)),
    ];
    final plan = ReminderPlanner.plan(docs, ownerOf: (_) => '', now: now);
    expect(plan, hasLength(ReminderPlanner.maxPending));
    expect(plan.first.at.isBefore(plan.last.at), isTrue);
    expect(plan.first.body, startsWith('RC 0 is valid until'));
  });
}
