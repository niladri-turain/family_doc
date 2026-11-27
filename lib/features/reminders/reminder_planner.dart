import '../documents/data/models/saved_document.dart';
import '../documents/presentation/document_format.dart';

/// One notification to show at [at].
class PlannedReminder {
  const PlannedReminder({
    required this.at,
    required this.title,
    required this.body,
    required this.documentId,
  });

  final DateTime at;
  final String title;
  final String body;
  final String documentId;
}

/// Works out the expiry reminders: 30, 7 and 1 day before and on the day,
/// at 10 am, only those still ahead. Pure, so it is easy to test.
class ReminderPlanner {
  const ReminderPlanner._();

  static const daysBefore = [30, 7, 1, 0];
  static const hour = 10;

  /// iOS keeps at most 64 pending notifications; the soonest win.
  static const maxPending = 60;

  /// [ownerOf] gives "your" / "Baba's (Sunil Roy)"-style owner text.
  static List<PlannedReminder> plan(
    List<SavedDocument> documents, {
    required String Function(SavedDocument) ownerOf,
    DateTime? now,
  }) {
    final from = now ?? DateTime.now();
    final planned = <PlannedReminder>[];
    for (final d in documents) {
      final e = d.expiryDate;
      if (e == null) continue;
      for (final before in daysBefore) {
        final day = DateTime(e.year, e.month, e.day - before, hour);
        if (!day.isAfter(from)) continue;
        final when = switch (before) {
          0 => 'expires today',
          1 => 'expires tomorrow',
          _ => 'expires in $before days',
        };
        planned.add(
          PlannedReminder(
            at: day,
            documentId: d.id,
            title: '${d.name} $when',
            body:
                '${_capital('${ownerOf(d)} ${d.name}'.trim())} is valid '
                'until ${formatDate(e)}. Renew it in time.',
          ),
        );
      }
    }
    planned.sort((a, b) => a.at.compareTo(b.at));
    return planned.take(maxPending).toList();
  }

  static String _capital(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
