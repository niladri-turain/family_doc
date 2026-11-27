import '../../categories/data/models/document_category.dart';
import '../../documents/data/models/saved_document.dart';
import '../../family/data/models/family_member.dart';

/// Everything the assistant may look at. It all stays on the phone.
class AssistantData {
  const AssistantData({
    required this.documents,
    required this.members,
    this.categories = const [],
  });

  final List<SavedDocument> documents;
  final List<FamilyMember> members;
  final List<DocumentCategory> categories;

  FamilyMember? memberOf(SavedDocument d) {
    for (final m in members) {
      if (m.id == d.memberId) return m;
    }
    return null;
  }

  String categoryOf(SavedDocument d) {
    for (final c in categories) {
      if (c.id == d.categoryId && c.isCustom == d.customCategory) {
        return c.name;
      }
    }
    return '';
  }
}

/// One answer: text, the documents it is about (shown as cards that open
/// or share the file) and follow-up questions to tap.
class AssistantReply {
  const AssistantReply({
    required this.text,
    this.documents = const [],
    this.suggestions = const [],
  });

  final String text;
  final List<SavedDocument> documents;
  final List<String> suggestions;
}

/// Answers a question about the family's documents. [LocalAssistant]
/// works offline on the phone; an on-device language model can implement
/// this too and use the same chat screen.
abstract class AssistantEngine {
  Future<AssistantReply> answer(
    String question,
    AssistantData data, {
    DateTime? now,
  });
}
