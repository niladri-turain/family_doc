import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../categories/presentation/providers/category_provider.dart';
import '../../documents/data/file_actions.dart';
import '../../documents/data/models/saved_document.dart';
import '../../documents/presentation/providers/document_provider.dart';
import '../../documents/presentation/widgets/document_thumbnail.dart';
import '../../documents/presentation/widgets/expiry_widgets.dart';
import '../../family/presentation/providers/family_provider.dart';
import '../data/assistant_engine.dart';

/// Route argument for [AssistantScreen]: a question to ask right away
/// (e.g. from a reminder).
class AssistantArgs {
  const AssistantArgs({this.question});

  final String? question;
}

class _Message {
  const _Message.user(this.text)
    : fromUser = true,
      documents = const [],
      suggestions = const [];

  _Message.reply(AssistantReply reply)
    : fromUser = false,
      text = reply.text,
      documents = reply.documents,
      suggestions = reply.suggestions;

  final bool fromUser;
  final String text;
  final List<SavedDocument> documents;
  final List<String> suggestions;
}

/// Chat with the on-phone assistant: find any member's documents
/// ("Babar Aadhaar dao") and ask when they expire ("Amar RC kobe expire
/// hobe?"). Document cards open or share the file.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[];
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final args = ModalRoute.of(context)?.settings.arguments as AssistantArgs?;
    // Opened from a reminder before My Family loaded: names are needed.
    final family = context.read<FamilyProvider>();
    final categories = context.read<CategoryProvider>();
    await Future.wait([
      if (!family.hasLoaded) family.fetchMembers(),
      if (!categories.hasLoaded) categories.fetchCategories(),
    ]).catchError((_) => <void>[]);
    if (!mounted) return;
    final question = args?.question;
    if (question != null) {
      await _send(question);
    } else {
      await _reply('hi');
    }
  }

  /// Only documents of people in My Family: files left on the phone by a
  /// removed member (or another login) never show up.
  AssistantData get _data {
    final members = context.read<FamilyProvider>().members;
    final ids = {for (final m in members) m.id};
    return AssistantData(
      documents: [
        for (final d in context.read<DocumentProvider>().all)
          if (ids.contains(d.memberId)) d,
      ],
      members: members,
      categories: context.read<CategoryProvider>().categories,
    );
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _thinking) return;
    _input.clear();
    setState(() => _messages.add(_Message.user(question)));
    await _reply(question);
  }

  Future<void> _reply(String question) async {
    setState(() => _thinking = true);
    final reply = await sl<AssistantEngine>().answer(question, _data);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages.add(_Message.reply(reply));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _open(SavedDocument document) async {
    final path = await context.read<DocumentProvider>().pathOf(document);
    final error = await sl<FileActions>().open(path);
    if (error != null && mounted) _snack(error);
  }

  Future<void> _share(SavedDocument document, Rect? origin) async {
    final path = await context.read<DocumentProvider>().pathOf(document);
    try {
      await sl<FileActions>().share(path, name: document.name, origin: origin);
    } catch (_) {
      if (mounted) _snack('Could not share this file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.lg,
                  AppSizes.screenPadding,
                  AppSizes.lg,
                ),
                itemCount: _messages.length + (_thinking ? 1 : 0),
                itemBuilder: (context, i) => i == _messages.length
                    ? const _Typing()
                    : _message(_messages[i], last: i == _messages.length - 1),
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
    color: AppColors.white,
    padding: const EdgeInsets.fromLTRB(
      AppSizes.screenPadding,
      AppSizes.lg,
      AppSizes.screenPadding,
      AppSizes.md,
    ),
    child: Row(
      children: [
        const AppBackButton(),
        const SizedBox(width: AppSizes.md),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask Family Docs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Works on this phone · private',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _message(_Message m, {required bool last}) {
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: m.fromUser ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(m.fromUser ? 18 : 4),
          bottomRight: Radius.circular(m.fromUser ? 4 : 18),
        ),
        border: m.fromUser ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        m.text,
        style: AppTextStyles.body.copyWith(
          color: m.fromUser ? AppColors.white : AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: m.fromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          bubble,
          for (final d in m.documents) ...[
            const SizedBox(height: 8),
            _DocumentCard(
              document: d,
              owner: _ownerOf(d),
              onOpen: () => _open(d),
              onShare: (origin) => _share(d, origin),
            ),
          ],
          // Suggestions only under the latest answer.
          if (last && m.suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in m.suggestions)
                  ActionChip(
                    label: Text(s),
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppColors.primarySoft,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    onPressed: () => _send(s),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _ownerOf(SavedDocument d) {
    for (final m in context.read<FamilyProvider>().members) {
      if (m.id == d.memberId) {
        return m.isSelf ? '${m.fullName} (you)' : m.fullName;
      }
    }
    return '';
  }

  Widget _inputBar() => Container(
    color: AppColors.white,
    padding: EdgeInsets.fromLTRB(AppSizes.screenPadding, 10, AppSizes.sm, 10),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            // Plain text keyboard so its action key sends (a multi-line
            // field would otherwise insert a new line on Android).
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.send,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 4,
            onSubmitted: _send,
            style: AppTextStyles.fieldValue,
            decoration: InputDecoration(
              hintText: 'Ask me anything…',
              hintStyle: AppTextStyles.body,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          tooltip: 'Send',
          onPressed: () => _send(_input.text),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.send_rounded, color: AppColors.white),
        ),
      ],
    ),
  );
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

/// A document in the chat: preview, name, whose it is, expiry; tap opens.
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.owner,
    required this.onOpen,
    required this.onShare,
  });

  final SavedDocument document;
  final String owner;
  final VoidCallback onOpen;
  final ValueChanged<Rect?> onShare;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.85,
      ),
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                DocumentThumbnail(document: document, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                      ),
                      if (owner.isNotEmpty)
                        Text(
                          owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      if (document.expiryDate != null) ...[
                        const SizedBox(height: 4),
                        ExpiryLabel(document: document),
                      ],
                    ],
                  ),
                ),
                Builder(
                  builder: (buttonContext) => IconButton(
                    tooltip: 'Share ${document.name}',
                    onPressed: () {
                      final box =
                          buttonContext.findRenderObject() as RenderBox?;
                      onShare(
                        box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
