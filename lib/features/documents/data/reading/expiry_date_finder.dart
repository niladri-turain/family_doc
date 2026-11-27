/// Finds a document's expiry date in text read from it (OCR):
/// "Valid Till: 12/03/2031", "Date of Expiry 05 JUN 2030",
/// "Validity (NT) 2031-03-12", "Valid from 01-01-2024 to 31-12-2024"…
///
/// A date on (or right below) an expiry word wins; otherwise the latest
/// future date, if any. Birth / issue dates alone never count.
class ExpiryDateFinder {
  const ExpiryDateFinder._();

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
    'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static final _expiryWords = RegExp(
    r'valid\s*(?:till|until|upto|up\s*to|thru|through)|validity|expir|'
    r'\bexp\b|\bexp\.|date\s*of\s*expiry|end\s*date|policy\s*end|'
    r'renewal\s*date|due\s*date|valid\s*to',
    caseSensitive: false,
  );

  static final _notExpiryWords = RegExp(
    r'birth|\bdob\b|d\.o\.b|issue|\bdoi\b|registration\s*date|reg\.?\s*date|'
    r'date\s*of\s*reg',
    caseSensitive: false,
  );

  // 12/03/2031, 12-03-2031, 12.03.2031, 12/03/31
  static final _dmy = RegExp(
    r'\b(\d{1,2})[/\-. ](\d{1,2})[/\-. ](\d{4}|\d{2})\b',
  );
  // 2031-03-12, 2031/03/12
  static final _ymd = RegExp(r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b');
  // 12 MAR 2031, 12-Mar-2031, 12 March, 2031
  static final _dMonY = RegExp(
    r'\b(\d{1,2})[\s\-/.]*([A-Za-z]{3,9})[\s\-/.,]*(\d{4})\b',
  );
  // MAR 12, 2031
  static final _monDY = RegExp(r'\b([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})\b');

  static DateTime? find(String text, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    DateTime? fromKeyword;
    final others = <DateTime>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final dates = datesIn(line);
      final isExpiryLine = _expiryWords.hasMatch(line);
      if (isExpiryLine) {
        // Date on the same line (last one: "valid from A to B" → B),
        // else on the next line (labels above values on cards).
        final candidates = dates.isNotEmpty
            ? dates
            : (i + 1 < lines.length ? datesIn(lines[i + 1]) : <DateTime>[]);
        if (candidates.isNotEmpty) {
          final date = candidates.last;
          if (fromKeyword == null || date.isAfter(fromKeyword)) {
            fromKeyword = date;
          }
          continue;
        }
      }
      if (!_notExpiryWords.hasMatch(line)) others.addAll(dates);
    }
    if (fromKeyword != null) return fromKeyword;

    final future =
        others
            .where(
              (d) => d.isAfter(DateTime(today.year, today.month, today.day)),
            )
            .toList()
          ..sort();
    return future.isEmpty ? null : future.last;
  }

  /// Every date written in [line], left to right.
  static List<DateTime> datesIn(String line) {
    final found = <(int, DateTime)>[];
    void add(int at, int y, int m, int d) {
      if (y < 100) y += 2000;
      if (y < 1900 || y > 2200 || m < 1 || m > 12 || d < 1 || d > 31) return;
      final date = DateTime(y, m, d);
      if (date.month != m) return; // 31/02 etc.
      found.add((at, date));
    }

    for (final m in _ymd.allMatches(line)) {
      add(m.start, int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    }
    for (final m in _dmy.allMatches(line)) {
      if (found.any((f) => f.$1 <= m.start && m.start < f.$1 + 10)) continue;
      add(m.start, int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
    }
    for (final m in _dMonY.allMatches(line)) {
      final month = _monthOf(m[2]!);
      if (month != null) {
        add(m.start, int.parse(m[3]!), month, int.parse(m[1]!));
      }
    }
    for (final m in _monDY.allMatches(line)) {
      final month = _monthOf(m[1]!);
      if (month != null) {
        add(m.start, int.parse(m[3]!), month, int.parse(m[2]!));
      }
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final f in found) f.$2];
  }

  static int? _monthOf(String word) {
    final w = word.toLowerCase();
    return _months[w] ?? (w.length >= 3 ? _months[w.substring(0, 3)] : null);
  }
}
