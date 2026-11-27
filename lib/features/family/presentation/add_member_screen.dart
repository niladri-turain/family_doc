import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/image_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/family_member.dart';
import '../data/models/relation.dart';
import 'providers/family_provider.dart';
import 'widgets/member_avatar.dart';
import 'widgets/photo_source_sheet.dart';
import 'widgets/relation_chip.dart';

/// Add yourself (route argument `true`), add a family member (`false`), or
/// edit one (route argument: the [FamilyMember]).
/// POSTs or PATCHes /api/v1/family-members, then goes back.
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _dobText = TextEditingController();
  final _genderText = TextEditingController();

  late final Object? _argument = ModalRoute.of(context)?.settings.arguments;

  /// The member being edited, or null when adding.
  late final FamilyMember? _editing = _argument is FamilyMember
      ? _argument
      : null;

  /// Adding or editing the Self member (relation is locked to Self).
  late final bool _isSelf =
      _editing?.isSelf ??
      (_argument as bool?) ??
      !context.read<FamilyProvider>().hasSelf;

  Relation? _relation;
  DateTime? _dateOfBirth;
  Gender? _gender;
  File? _photo;

  /// Editing: the user removed the saved photo.
  bool _removePhoto = false;
  bool _prefilled = false;
  bool _askedLoginMobile = false;
  bool _preparingPhoto = false;

  String? _nameError;
  String? _relationError;
  String? _dobError;
  String? _genderError;
  String? _mobileError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isSelf) _relation = Relation.self;
    final m = _editing;
    if (m != null && !_prefilled) {
      _prefilled = true;
      _relation = m.relation;
      _name.text = m.fullName;
      _dateOfBirth = m.dateOfBirth;
      if (m.dateOfBirth != null) _dobText.text = _formatDob(m.dateOfBirth!);
      _gender = m.gender;
      _genderText.text = m.gender?.label ?? '';
      _mobile.text = _lastTen(m.mobile);
    }
    if (_isSelf && !_askedLoginMobile) {
      _askedLoginMobile = true;
      // After this frame: loading the profile notifies listeners.
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillLoginMobile());
    }
  }

  static String _lastTen(String? mobile) {
    final digits = (mobile ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// Self's number is the one they logged in with: taken from the login
  /// (or GET /users/me after a restart) and not editable.
  Future<void> _fillLoginMobile() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      try {
        await auth.loadProfile();
      } catch (_) {
        // Offline / expired: keep the saved number (editing) or leave empty.
      }
    }
    final mobile = _lastTen(auth.user?.mobile);
    if (mounted && mobile.isNotEmpty) setState(() => _mobile.text = mobile);
  }

  /// Saved photo still shown (editing, no new photo picked, not removed).
  String? get _savedPhotoUrl =>
      (_photo == null && !_removePhoto) ? _editing?.photoUrl : null;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _dobText.dispose();
    _genderText.dispose();
    super.dispose();
  }

  /// Self only when adding yourself; never offered twice.
  List<Relation> get _relations => _isSelf
      ? const [Relation.self]
      : Relation.values.where((r) => r != Relation.self).toList();

  // ───────────── Pickers ─────────────
  Future<void> _pickPhoto() async {
    FocusScope.of(context).unfocus();
    final action = await showPhotoSourceSheet(
      context,
      hasPhoto: _photo != null || _savedPhotoUrl != null,
    );
    if (action == null) return;
    if (action == PhotoAction.remove) {
      setState(() {
        _photo = null;
        if (_editing?.photoUrl != null) _removePhoto = true;
      });
      return;
    }
    setState(() => _preparingPhoto = true);
    try {
      final file = await sl<ImageService>().pickPhoto(
        fromCamera: action == PhotoAction.camera,
      );
      if (file != null) setState(() => _photo = file);
    } on PlatformException catch (e) {
      _snack(
        e.code.contains('denied')
            ? 'Please allow camera / photo access in Settings.'
            : "Couldn't open the ${action == PhotoAction.camera ? 'camera' : 'gallery'}.",
      );
    } catch (e) {
      _snack('Could not use this photo. Please choose another one.');
    } finally {
      if (mounted) setState(() => _preparingPhoto = false);
    }
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked == null) return;
    setState(() {
      _dateOfBirth = picked;
      _dobError = null;
      _dobText.text = _formatDob(picked);
    });
  }

  Future<void> _pickGender() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<Gender>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final g in Gender.values)
                ListTile(
                  title: Text(g.label, style: AppTextStyles.cardTitle),
                  trailing: g == _gender
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, g),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _gender = picked;
      _genderError = null;
      _genderText.text = picked.label;
    });
  }

  // ───────────── Save ─────────────
  bool _validate() {
    final name = _name.text.trim();
    final mobile = _mobile.text.trim();
    setState(() {
      _nameError = name.isEmpty
          ? 'Enter the full name'
          : (name.length > 100 ? 'Name is too long' : null);
      _relationError = _relation == null ? 'Choose a relation' : null;
      _dobError = _dateOfBirth == null ? 'Choose date of birth' : null;
      _genderError = _gender == null ? 'Choose gender' : null;
      _mobileError =
          !_isSelf &&
              mobile.isNotEmpty &&
              !RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)
          ? 'Enter a valid 10-digit mobile number'
          : null;
    });
    return [
      _nameError,
      _relationError,
      _dobError,
      _genderError,
      _mobileError,
    ].every((e) => e == null);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    final family = context.read<FamilyProvider>();
    final editing = _editing;
    try {
      if (editing != null) {
        await family.updateMember(
          editing,
          relation: _relation!,
          fullName: _name.text,
          dateOfBirth: _dateOfBirth!,
          gender: _gender!,
          mobile: _mobile.text.trim(),
          photo: _photo,
          removePhoto: _removePhoto && _photo == null,
        );
      } else {
        await family.addMember(
          relation: _relation!,
          fullName: _name.text,
          dateOfBirth: _dateOfBirth!,
          gender: _gender!,
          mobile: _mobile.text.trim(),
          photo: _photo,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _formatDob(DateTime d) =>
      '${_two(d.day)} / ${_two(d.month)} / ${d.year}';

  String get _title => _editing == null
      ? (_isSelf ? 'Add yourself' : 'Add member')
      : (_isSelf ? 'Edit my details' : 'Edit member');

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    final saving = context.watch<FamilyProvider>().isSaving;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.lg,
                AppSizes.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    _title,
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.xl,
                  AppSizes.screenPadding,
                  AppSizes.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _photoPicker()),
                    const SizedBox(height: 20),
                    Text('Relation', style: AppTextStyles.label),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in _relations)
                          RelationChip(
                            label: r.label,
                            selected: _relation == r,
                            onTap: _isSelf
                                ? null
                                : () => setState(() {
                                    _relation = r;
                                    _relationError = null;
                                  }),
                          ),
                      ],
                    ),
                    if (_relationError != null) _error(_relationError!),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Full name',
                      controller: _name,
                      hintText: 'e.g. Rahul Sharma',
                      textCapitalization: TextCapitalization.words,
                      errorText: _nameError,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Date of birth',
                            controller: _dobText,
                            hintText: 'DD / MM / YYYY',
                            readOnly: true,
                            onTap: _pickDob,
                            suffixIcon: Icons.calendar_today_outlined,
                            errorText: _dobError,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: AppTextField(
                            label: 'Gender',
                            controller: _genderText,
                            hintText: 'Select',
                            readOnly: true,
                            onTap: _pickGender,
                            suffixIcon: Icons.keyboard_arrow_down_rounded,
                            errorText: _genderError,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Mobile number',
                      optionalHint: _isSelf ? null : '(optional)',
                      controller: _mobile,
                      prefixText: '+91',
                      locked: _isSelf,
                      hintText: _isSelf ? 'Your login number' : 'Enter number',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      errorText: _mobileError,
                      onChanged: (_) => setState(() => _mobileError = null),
                    ),
                    if (_isSelf) ...[
                      const SizedBox(height: 6),
                      Text(
                        'The number you logged in with',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                0,
                AppSizes.screenPadding,
                AppSizes.lg,
              ),
              child: AppPrimaryButton(
                label: _editing == null ? 'Save member' : 'Save changes',
                isLoading: saving,
                onPressed: _preparingPhoto ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.error,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _photoPicker() {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Add photo',
          child: GestureDetector(
            onTap: _preparingPhoto ? null : _pickPhoto,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  MemberAvatar(
                    initials: FamilyMember.initialsOf(_name.text),
                    color: const CategoryColor(
                      AppColors.primary,
                      AppColors.primarySoft,
                    ),
                    photoFile: _photo,
                    photoUrl: _savedPhotoUrl,
                    size: 92,
                    circle: true,
                  ),
                  if (_preparingPhoto)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 15,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('Photo (optional)', style: AppTextStyles.caption),
      ],
    );
  }
}
