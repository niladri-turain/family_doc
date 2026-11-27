/// "1.2 MB", "860 KB", "120 B".
String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    final mb = bytes / 1024 / 1024;
    return '${mb >= 10 ? mb.round() : mb.toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today", "Yesterday" or "12 Nov 2026".
String formatSavedDate(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final d = DateTime(date.year, date.month, date.day);
  final t = DateTime(today.year, today.month, today.day);
  final days = t.difference(d).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// "12 Mar 2027".
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// How soon a document expires, for labels and chat.
enum ExpiryStatus { expired, soon, later }

/// Within this many days counts as "expiring soon" (orange label, chat).
const expirySoonDays = 30;

ExpiryStatus expiryStatusOf(int days) => days < 0
    ? ExpiryStatus.expired
    : (days <= expirySoonDays ? ExpiryStatus.soon : ExpiryStatus.later);

/// "Expired 3 days ago", "Expires today", "Expires in 12 days",
/// "Expires 12 Mar 2027".
String expiryLabel(DateTime expiry, int days) {
  if (days < -1) return 'Expired ${-days} days ago';
  if (days == -1) return 'Expired yesterday';
  if (days == 0) return 'Expires today';
  if (days == 1) return 'Expires tomorrow';
  if (days <= expirySoonDays) return 'Expires in $days days';
  return 'Expires ${formatDate(expiry)}';
}
