import '../../documents/data/models/saved_document.dart';
import '../../documents/presentation/document_format.dart';
import '../../family/data/models/family_member.dart';
import '../../family/data/models/relation.dart';
import 'assistant_engine.dart';

/// Answers on the phone, with no internet and no model download: it
/// understands English, Banglish ("babar aadhaar dao") and Bengali
/// ("আমার আরসি কবে শেষ হবে"), works out whose documents and which ones
/// are meant, and answers from the saved documents only, so it never
/// makes up a date.
class LocalAssistant implements AssistantEngine {
  const LocalAssistant();

  /// "Expiring soon" in chat: expired, or within this many days.
  static const soonDays = 60;

  @override
  Future<AssistantReply> answer(
    String question,
    AssistantData data, {
    DateTime? now,
  }) async => _Answer(question, data, now ?? DateTime.now()).reply();
}

// ───────────── Words ─────────────

const _relationWords = <Relation, Set<String>>{
  Relation.self: {
    'me', 'my', 'mine', 'i', 'myself', 'self', 'amar', 'amr', 'ami', //
    'amake', 'amay', 'nijer', 'mor',
  },
  Relation.father: {
    'baba',
    'father',
    'dad',
    'daddy',
    'papa',
    'bapi',
    'pita',
    'abba',
  },
  Relation.mother: {
    'ma',
    'maa',
    'mother',
    'mom',
    'mummy',
    'mum',
    'mamma',
    'mata',
    'amma',
  },
  Relation.spouse: {
    'wife',
    'husband',
    'spouse',
    'bou',
    'stri',
    'swami',
    'partner',
    'biwi',
  },
  Relation.son: {'son', 'chele', 'beta', 'putro'},
  Relation.daughter: {'daughter', 'meye', 'beti', 'kanya'},
};

const _expiryWords = {
  'expire', 'expires', 'expired', 'expiry', 'expiring', 'exp', 'validity', //
  'valid', 'renew', 'renewal', 'kobe', 'kbe', 'kobey', 'shesh', 'sesh',
  'meyad', 'meyaad', 'mead', 'deadline', 'date', 'last', 'till', 'until',
  'upto', 'end', 'ends', 'left', 'remaining', 'days', 'day', 'due', 'baki',
  'koto',
};

/// "Thanks", "ok": no search, just a friendly answer.
const _thanksWords = {
  'thanks', 'thank', 'thx', 'ty', 'ok', 'okay', 'great', 'nice', 'cool', //
  'dhonnobad', 'dhanyabad', 'accha', 'thik',
};

/// "Show all documents", "list everything", "sob document".
const _allWords = {'all', 'everything', 'sob', 'shob', 'every', 'list'};

/// Time words: "what's coming up". Not "all"/"sob", which only mean
/// every document ("Bikash er sob documents").
const _soonWords = {
  'soon', 'upcoming', 'next', 'coming', 'agami', 'shighroi', 'taratari', //
  'month', 'week', 'mash', 'shoptaho',
};

const _helpWords = {
  'hi',
  'hello',
  'hey',
  'help',
  'namaskar',
  'nomoskar',
  'hlw',
  'hii',
};

/// Words that carry no meaning for the search.
const _stopWords = {
  'the', 'a', 'an', 'of', 'for', 'is', 'are', 'to', 'please', 'pls', 'plz', //
  'can', 'you', 'document', 'documents', 'doc', 'docs', 'file', 'files',
  'ta', 'ti', 'gulo', 'guli', 'er', 'r', 's', 'ki', 'ache', 'achhe',
  'acche', 'ase', 'ekta', 'ei', 'oi', 'when', 'will', 'does', 'do', 'it',
  'its', 'what', 'whats', 'be', 'and', 'or', 'in', 'on', 'with', 'about',
  'tell', 'bolo', 'janao', 'jante', 'chai', 'kindly', 'card', 'copy',
  'find', 'show', 'give', 'send', 'open', 'dao', 'dau', 'dio', 'de',
  'dekhao', 'dekhaw', 'khujo', 'khuje', 'khujey', 'lagbe', 'ana', 'ano',
  'share', 'get', 'where', 'kothay', 'kothai', 'hobe', 'hbe', 'hoye',
  'geche', 'jabe', 'jbe', 'kore', 'kre', 'hocche', 'hochhe', 'hosse',
  'hoche', 'was', 'has', 'have', 'got', 'need', 'want', 'saved',
  'my', 'koto', 'din', 'baki', 'theke', 'kar', 'kader', 'family', 'sathe',
  'number', 'details', 'info', 'na', 'ar', 'aar', 'o', 'ke', 'te', 'e',
  'sob', 'shob', 'all', 'which', 'kon', 'kono', 'any', 'list', 'every',
  'this', 'that', 'these', 'those', 'there', 'how', 'many', 'much', 'am',
  'kagoj', 'kagaj', 'paper', 'papers', 'koro', 'korbe', 'dekhi',
  'anything', 'something', 'could', 'would', 'should',
  'yet', 'already', 'still', 'left', 'remaining', 'due', 'up',
};

/// One meaning, many spellings. Multi-word entries match as a phrase.
const _synonyms = <List<String>>[
  ['rc', 'registration certificate', 'vehicle registration', 'registration'],
  ['dl', 'driving', 'licence', 'license', 'driving licence'],
  ['aadhaar', 'aadhar', 'adhar', 'adhaar', 'uid', 'uidai'],
  ['pan', 'permanent account'],
  ['voter', 'epic', 'election'],
  ['passport'],
  ['insurance', 'policy', 'bima', 'beema'],
  ['marksheet', 'mark sheet', 'marks', 'result', 'grade'],
  ['puc', 'pollution'],
  ['birth', 'janma', 'jonmo'],
];

/// Bengali script → the Banglish word the rest of the code knows.
const _bengali = {
  'আমার': 'amar', 'আমি': 'ami', 'আমাকে': 'amake', 'নিজের': 'nijer', //
  'বাবা': 'baba', 'বাবার': 'baba', 'বাপি': 'bapi',
  'মা': 'ma', 'মায়ের': 'ma', 'মার': 'ma', 'মা’র': 'ma',
  'বউ': 'bou',
  'বউয়ের': 'bou',
  'বৌ': 'bou',
  'স্ত্রী': 'wife',
  'স্ত্রীর': 'wife',
  'স্বামী': 'swami', 'স্বামীর': 'swami',
  'ছেলে': 'chele', 'ছেলের': 'chele', 'মেয়ে': 'meye', 'মেয়ের': 'meye',
  'কবে': 'kobe', 'শেষ': 'shesh', 'মেয়াদ': 'meyad', 'এক্সপায়ার': 'expire',
  'দাও': 'dao', 'দেখাও': 'dekhao', 'খুঁজে': 'khuje', 'খোঁজো': 'khujo',
  'হবে': 'hobe', 'সব': 'sob', 'কি': 'ki', 'কী': 'ki', 'কোন': 'kon',
  'কোনো': 'kono', 'ডকুমেন্ট': 'document', 'কাগজ': 'document',
  'আরসি': 'rc', 'পাসপোর্ট': 'passport', 'লাইসেন্স': 'licence',
  'ড্রাইভিং': 'driving', 'আধার': 'aadhaar', 'প্যান': 'pan',
  'ভোটার': 'voter', 'মার্কশিট': 'marksheet', 'সার্টিফিকেট': 'certificate',
  'বীমা': 'insurance', 'ইন্সুরেন্স': 'insurance', 'জন্ম': 'birth',
  'শীঘ্রই': 'shighroi', 'তাড়াতাড়ি': 'taratari',
};

/// Banglish words that say "answer in Banglish".
const _banglishMarkers = {
  'amar', 'amr', 'ami', 'amake', 'nijer', 'babar', 'mayer', 'kobe', 'kbe', //
  'ache', 'achhe', 'dao', 'dau', 'dekhao', 'khujo', 'khuje', 'hobe', 'hbe',
  'gulo', 'shesh', 'sesh', 'meyad', 'jabe', 'kothay', 'kothai', 'lagbe',
  'chai', 'koto', 'baki', 'cheler', 'meyer', 'bouer', 'ta', 'ti', 'er',
  'ki', 'hocche', 'hochhe', 'hoche', 'hoyeche', 'hoyni', 'geche', 'kon',
  'kono', 'sob', 'shob', 'ekhon', 'kagoj', 'dhonnobad', 'dhanyabad', 'thik',
  'accha', 'koro', 'dekhi', 'diye', 'theke',
};

String _normalise(String s) => s.replaceAll('য়', 'য়').replaceAll('’', "'");

List<String> _tokens(String text) => _normalise(text)
    .toLowerCase()
    .split(RegExp(r"[^\p{L}\p{M}\p{N}]+", unicode: true))
    .where((t) => t.isNotEmpty)
    .map((t) => _bengali[t] ?? t)
    .toList();

/// "babar" → baba, "mayer" → ma, "rahuler" → rahul, "fathers" → father.
List<String> _bases(String t) => [
  t,
  if (t.length > 3 && t.endsWith('yer')) t.substring(0, t.length - 3),
  if (t.length > 3 && t.endsWith('er')) t.substring(0, t.length - 2),
  if (t.length > 2 && t.endsWith('r')) t.substring(0, t.length - 1),
  if (t.length > 3 && t.endsWith('s')) t.substring(0, t.length - 1),
];

int _distance(String a, String b) {
  if ((a.length - b.length).abs() > 1) return 2;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = [i, ...List.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      cur[j] = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

// ───────────── One answer ─────────────

class _Answer {
  _Answer(this.question, this.data, this.now)
    : tokens = _tokens(question),
      banglish =
          RegExp(r'[ঀ-৿]').hasMatch(question) ||
          _tokens(question).any(_banglishMarkers.contains);

  final String question;
  final AssistantData data;
  final DateTime now;
  final List<String> tokens;
  final bool banglish;

  /// Tokens used up by member detection.
  final _used = <String>{};

  String _t(String en, String bn) => banglish ? bn : en;

  AssistantReply reply() {
    if (tokens.isEmpty || tokens.every(_helpWords.contains)) return _help();
    if (tokens.any(_thanksWords.contains) &&
        tokens.every(
          (t) =>
              _thanksWords.contains(t) ||
              _stopWords.contains(t) ||
              _helpWords.contains(t),
        )) {
      return AssistantReply(
        text: _t(
          "You're welcome! Ask me about any document whenever you need it.",
          'Thik ache! Jokhon dorkar, jekono document er kotha jiggesh koro.',
        ),
      );
    }

    final (members, missing) = _members();
    if (members == null && missing != null) {
      return AssistantReply(
        text: _t(
          "I couldn't find your ${missing.label.toLowerCase()} in My Family. "
              'Add them there first.',
          'My Family te tomar ${_bnRelation(missing)} ke pelam na. '
              'Age okhane add koro.',
        ),
        suggestions: _suggestions(),
      );
    }
    final pool = members == null
        ? data.documents
        : data.documents.where((d) => members.contains(d.memberId)).toList();
    final expiry = tokens.any(_expiryWords.contains);
    final soon = tokens.any(_soonWords.contains);
    final groups = _searchGroups();

    if (groups.isEmpty) {
      if (_pastOnly) return _expired(pool, members);
      if (expiry || soon) return _expiring(pool, members);
      if (members != null || tokens.any(_allWords.contains)) {
        return _list(pool, members);
      }
      return _help();
    }

    final found = _match(pool, groups);
    if (found.isEmpty) {
      final words = tokens
          .where((t) => groups.any((g) => g.contains(t)))
          .join(' ');
      return AssistantReply(
        text: _t(
          'I couldn\'t find "$words" in ${_scope(members)}. '
              'Try another word, or upload it from a category.',
          '${_capital(_scopeBn(members))} "$words" khuje pelam na. '
              'Onno kono shobdo diye try koro, ba category theke upload koro.',
        ),
        suggestions: _suggestions(),
      );
    }
    return expiry ? _expiryOf(found) : _found(found, members);
  }

  /// "Which documents have expired?", "Is my RC expired?": asks about the
  /// past only, not what is coming up.
  bool get _pastOnly =>
      tokens.contains('expired') &&
      !tokens.any(
        (t) =>
            const {
              'expire',
              'expires',
              'expiring',
              'will',
              'when',
            }.contains(t) ||
            _soonWords.contains(t),
      );

  /// "this week" → 7 days, "this month" → 31, otherwise 60.
  int get _window {
    if (tokens.any(const {'week', 'shoptaho'}.contains)) return 7;
    if (tokens.any(const {'month', 'mash'}.contains)) return 31;
    return LocalAssistant.soonDays;
  }

  // ───── Who ─────

  /// Members asked about (null = everyone) and a relation asked about
  /// that isn't in the family.
  (Set<int>?, Relation?) _members() {
    final byName = <int>{};
    final byRelation = <int>{};
    Relation? missing;
    var self = false;

    for (final t in tokens) {
      for (final b in _bases(t)) {
        for (final m in data.members) {
          final names = m.fullName
              .toLowerCase()
              .split(RegExp(r'\s+'))
              .where((n) => n.length >= 3);
          if (names.contains(b)) {
            byName.add(m.id);
            _used.add(t);
          }
        }
        for (final entry in _relationWords.entries) {
          if (!entry.value.contains(b)) continue;
          _used.add(t);
          if (entry.key == Relation.self) {
            self = true;
            continue;
          }
          final ids = [
            for (final m in data.members)
              if (m.relation == entry.key) m.id,
          ];
          if (ids.isEmpty) missing ??= entry.key;
          byRelation.addAll(ids);
        }
      }
    }
    if (byName.isNotEmpty) return (byName, null);
    if (byRelation.isNotEmpty) return (byRelation, null);
    if (missing != null) return (null, missing);
    if (self) {
      final ids = {
        for (final m in data.members)
          if (m.isSelf) m.id,
      };
      return (ids.isEmpty ? null : ids, null);
    }
    return (null, null);
  }

  // ───── What ─────

  /// Each word still meaningful, with its other spellings.
  List<List<String>> _searchGroups() {
    final groups = <List<String>>[];
    // Phrases first: "registration certificate" is one thing (RC), not
    // "registration" + "certificate".
    final text = ' ${tokens.join(' ')} ';
    for (final g in _synonyms) {
      for (final phrase in g.where((w) => w.contains(' '))) {
        if (!text.contains(' $phrase ')) continue;
        _used.addAll(phrase.split(' '));
        if (!groups.any((x) => x.first == g.first)) groups.add(g);
      }
    }
    for (final t in tokens) {
      if (_used.contains(t) ||
          _stopWords.contains(t) ||
          _expiryWords.contains(t) ||
          _soonWords.contains(t) ||
          _helpWords.contains(t) ||
          _thanksWords.contains(t) ||
          _allWords.contains(t) ||
          _relationWords.values.any((w) => w.contains(t))) {
        continue;
      }
      // "certificates" → also "certificate"
      final singular = t.length > 4 && t.endsWith('s')
          ? t.substring(0, t.length - 1)
          : null;
      final synonyms = _synonyms.firstWhere(
        (g) => g.contains(t) || (singular != null && g.contains(singular)),
        orElse: () => [t, ?singular],
      );
      if (!groups.any((g) => g.first == synonyms.first)) groups.add(synonyms);
    }
    return groups;
  }

  static bool _has(String haystack, String word) {
    if (word.contains(' ')) return haystack.contains(word);
    final words = haystack.split(RegExp(r"[^\p{L}\p{N}]+", unicode: true));
    return words.any(
      (w) => w == word || (word.length >= 4 && w.startsWith(word)),
    );
  }

  List<SavedDocument> _match(
    List<SavedDocument> pool,
    List<List<String>> groups,
  ) {
    final scored = <(SavedDocument, int, int)>[];
    for (final d in pool) {
      final strong = '${d.name} ${d.typeName ?? ''}'.toLowerCase();
      final medium = '${data.categoryOf(d)} ${d.fileName}'.toLowerCase();
      final weak = (d.text ?? '').toLowerCase();
      var score = 0;
      var groupsHit = 0;
      for (final group in groups) {
        var best = 0;
        for (final word in group) {
          if (_has(strong, word)) {
            best = 3;
          } else if (_has(medium, word)) {
            best = best < 2 ? 2 : best;
          } else if (_has(weak, word)) {
            best = best < 1 ? 1 : best;
          }
        }
        // Typos: "pasport", "marksheat".
        if (best == 0 && group.first.length >= 5) {
          final words = strong.split(RegExp(r'\s+'));
          if (words.any(
            (w) => w.length >= 5 && _distance(w, group.first) <= 1,
          )) {
            best = 2;
          }
        }
        if (best > 0) groupsHit++;
        score += best;
      }
      if (groupsHit > 0) scored.add((d, groupsHit, score));
    }
    if (scored.isEmpty) return [];
    final most = scored.map((s) => s.$2).reduce((a, b) => a > b ? a : b);
    final best = scored.where((s) => s.$2 == most).toList()
      ..sort((a, b) {
        final byScore = b.$3.compareTo(a.$3);
        return byScore != 0
            ? byScore
            : b.$1.createdAt.compareTo(a.$1.createdAt);
      });
    return [for (final s in best.take(5)) s.$1];
  }

  // ───── Replies ─────

  AssistantReply _found(List<SavedDocument> docs, Set<int>? members) {
    final text = docs.length == 1
        ? _t('Here is ${_doc(docs.single)}.', 'Ei nao ${_docBn(docs.single)}.')
        : _t(
            'I found ${docs.length} documents in ${_scope(members)}:',
            members == null
                ? 'Family te ${docs.length} ta document pelam:'
                : '${_capital(_ownersBn(members))} ${docs.length} ta document '
                      'pelam:',
          );
    return AssistantReply(
      text: text,
      documents: docs,
      suggestions: [if (docs.first.expiryDate != null) _askExpiry(docs.first)],
    );
  }

  AssistantReply _expiryOf(List<SavedDocument> docs) {
    final lines = [
      for (final d in docs)
        if (_pastOnly && d.expiryDate != null)
          '${d.daysToExpiry(now)! < 0 ? _t('Yes.', 'Hya.') : _t('No.', 'Na.')} '
              '${_expiryLine(d)}'
        else
          _expiryLine(d),
    ];
    return AssistantReply(text: lines.join('\n'), documents: docs);
  }

  String _expiryLine(SavedDocument d) {
    final e = d.expiryDate;
    final days = d.daysToExpiry(now);
    if (e == null || days == null) {
      return _t(
        "${_capital(_doc(d))} has no expiry date saved. Add it from ⋮ → "
            'Add expiry date.',
        '${_capital(_docBn(d))} e kono expiry date dewa nei. ⋮ → '
            'Add expiry date theke diye dao.',
      );
    }
    final date = formatDate(e);
    if (days < 0) {
      return _t(
        '${_capital(_doc(d))} expired on $date (${-days} days ago). '
            'Renew it soon.',
        '${_capital(_docBn(d))} $date e expire hoye geche (${-days} din age). '
            'Taratari renew koro.',
      );
    }
    final when = switch (days) {
      0 => _t('today', 'aaj'),
      1 => _t('tomorrow', 'kal'),
      _ => _t('in $days days', 'aar $days din baki'),
    };
    return _t(
      '${_capital(_doc(d))} expires on $date ($when).',
      '${_capital(_docBn(d))} $date e expire hobe ($when).',
    );
  }

  AssistantReply _expiring(List<SavedDocument> pool, Set<int>? members) {
    final dated = pool.where((d) => d.expiryDate != null).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    if (dated.isEmpty) {
      return AssistantReply(
        text: _t(
          'None of ${_scope(members)} have an expiry date yet. Open a '
              'document\'s ⋮ → Add expiry date, and I\'ll remind you before '
              'it expires.',
          '${_capital(_scopeBn(members))} kono document e expiry date nei. '
              'Document er ⋮ → Add expiry date e dile ami age theke '
              'mone koriye debo.',
        ),
      );
    }
    final window = _window;
    final soon = dated.where((d) => d.daysToExpiry(now)! <= window).toList();
    if (soon.isEmpty) {
      final next = dated.firstWhere(
        (d) => d.daysToExpiry(now)! >= 0,
        orElse: () => dated.last,
      );
      return AssistantReply(
        text: _t(
          'Nothing expires in the next $window days. '
              'Next up: ${_expiryLine(next)}',
          'Samner $window diner moddhe kichu expire '
              'hocche na. Porer ta: ${_expiryLine(next)}',
        ),
        documents: [next],
      );
    }
    return AssistantReply(
      text: [
        _t(
          '${soon.length} ${soon.length == 1 ? 'document needs' : 'documents need'} attention:',
          '${soon.length} ta document er meyad shesh hocche:',
        ),
        for (final d in soon) '• ${_expiryLine(d)}',
      ].join('\n'),
      documents: soon,
    );
  }

  AssistantReply _expired(List<SavedDocument> pool, Set<int>? members) {
    final expired = pool.where((d) => (d.daysToExpiry(now) ?? 0) < 0).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    if (expired.isEmpty) {
      final upcoming = _expiring(pool, members);
      return AssistantReply(
        text:
            _t(
              'None of ${_scope(members)} have expired.',
              '${_capital(_scopeBn(members))} kono document expire hoyni.',
            ) +
            (upcoming.documents.isEmpty ? '' : '\n${upcoming.text}'),
        documents: upcoming.documents,
      );
    }
    return AssistantReply(
      text: [
        _t(
          '${expired.length} ${expired.length == 1 ? 'document has' : 'documents have'} expired:',
          '${expired.length} ta document expire hoye geche:',
        ),
        for (final d in expired) '• ${_expiryLine(d)}',
      ].join('\n'),
      documents: expired,
    );
  }

  AssistantReply _list(List<SavedDocument> pool, Set<int>? members) {
    if (pool.isEmpty) {
      return AssistantReply(
        text: _t(
          'No documents saved in ${_scope(members)} yet.',
          '${_capital(_scopeBn(members))} ekhono kono document save kora nei.',
        ),
        suggestions: _suggestions(),
      );
    }
    final newest = [...pool]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = newest.take(10).toList();
    return AssistantReply(
      text: _t(
        '${_capital(_scope(members))} (${pool.length}):',
        '${_capital(members == null ? 'family r' : _ownersBn(members))} '
            '${pool.length} ta document:',
      ),
      documents: shown,
    );
  }

  AssistantReply _help() => AssistantReply(
    text: _t(
      'Hi! I can find your family\'s documents and tell you when they '
          'expire. Everything stays on this phone. Try one of these:',
      'Hi! Ami tomar family r document khuje dite pari ar kobe expire '
          'hobe bolte pari. Sob kichu ei phone ei thake. Eguli try koro:',
    ),
    suggestions: _suggestions(),
  );

  List<String> _suggestions() {
    final father = data.members.any((m) => m.relation == Relation.father);
    final mother = data.members.any((m) => m.relation == Relation.mother);
    return [
      _t("What's expiring soon?", 'Ki ki expire hocche?'),
      _t('Show my documents', 'Amar sob document dekhao'),
      if (father) _t("Show Baba's documents", 'Babar document dekhao'),
      if (!father && mother) _t("Show Ma's documents", 'Mayer document dekhao'),
      _t('When does my RC expire?', 'Amar RC kobe expire hobe?'),
    ];
  }

  /// A follow-up the user taps, so in their voice: "my", "amar".
  String _askExpiry(SavedDocument d) {
    final m = _member(d.memberId);
    final self = m == null || m.isSelf;
    return _t(
      'When does ${self ? 'my' : "${m.fullName}'s"} ${d.name} expire?',
      '${self ? 'Amar' : '${m.fullName}-er'} ${d.name} kobe expire hobe?',
    );
  }

  // ───── Names ─────

  FamilyMember? _member(int id) {
    for (final m in data.members) {
      if (m.id == id) return m;
    }
    return null;
  }

  String _owner(SavedDocument d) {
    final m = _member(d.memberId);
    if (m == null) return 'the';
    return m.isSelf ? 'your' : "${m.fullName}'s";
  }

  String _ownerBn(SavedDocument d) {
    final m = _member(d.memberId);
    if (m == null) return '';
    return m.isSelf ? 'tomar' : '${m.fullName}-er';
  }

  String _doc(SavedDocument d) => '${_owner(d)} ${d.name}';

  String _docBn(SavedDocument d) => '${_ownerBn(d)} ${d.name}'.trim();

  String _scope(Set<int>? ids) {
    if (ids == null || ids.isEmpty) return "your family's documents";
    if (ids.length > 1) {
      return '${ids.map(_member).whereType<FamilyMember>().map((m) => m.isSelf ? 'your' : m.fullName).join(' and ')} documents';
    }
    final m = _member(ids.single);
    if (m == null) return 'the documents';
    return m.isSelf ? 'your documents' : "${m.fullName}'s documents";
  }

  /// "tomar", "Sunil Roy-er", "tomar ar Sunil Roy-er".
  String _ownersBn(Set<int> ids) => ids
      .map(_member)
      .whereType<FamilyMember>()
      .map((m) => m.isSelf ? 'tomar' : '${m.fullName}-er')
      .join(' ar ');

  String _scopeBn(Set<int>? ids) {
    if (ids == null || ids.isEmpty) return 'family r document e';
    final names = ids
        .map(_member)
        .whereType<FamilyMember>()
        .map((m) => m.isSelf ? 'tomar' : '${m.fullName}-er')
        .join(' ar ');
    return '$names document e';
  }

  static String _bnRelation(Relation r) => switch (r) {
    Relation.father => 'Baba',
    Relation.mother => 'Ma',
    Relation.spouse => 'jibonsathi',
    Relation.son => 'chele',
    Relation.daughter => 'meye',
    _ => r.label.toLowerCase(),
  };

  static String _capital(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
