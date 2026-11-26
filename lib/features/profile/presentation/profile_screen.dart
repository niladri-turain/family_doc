import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../family/presentation/providers/family_provider.dart';
import '../../family/presentation/widgets/member_avatar.dart';
import 'widgets/profile_menu_tile.dart';

/// Profile: photo (Self member's photo, else default), phone number from
/// /users/me, Delete member, Log out and the app version.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _version;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final family = context.read<FamilyProvider>();
    if (!family.hasLoaded) family.fetchMembers();
    try {
      await auth.loadProfile();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _logout(askFirst: false, expired: true);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _logout({bool askFirst = true, bool expired = false}) async {
    if (askFirst) {
      final ok = await showAppConfirmDialog(
        context,
        title: 'Log out?',
        message: 'You will need your mobile number to log in again.',
        confirmLabel: 'Log out',
        icon: Icons.logout_rounded,
      );
      if (!ok || !mounted) return;
    }
    final auth = context.read<AuthProvider>();
    final family = context.read<FamilyProvider>();
    setState(() => _loggingOut = true);
    await auth.logout();
    family.clear();
    if (!mounted) return;
    if (expired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
        ),
      );
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
  }

  /// "+919876543210" → "+91 98765 43210"
  static String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();
    final self = family.self;
    final phone = auth.user?.mobile;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.lg,
            AppSizes.screenPadding,
            AppSizes.xl,
          ),
          children: [
            Text('Profile', style: AppTextStyles.title.copyWith(fontSize: 24)),
            const SizedBox(height: 20),

            // ── Header card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  self != null
                      ? MemberAvatar(
                          initials: self.initials,
                          color: const CategoryColor(
                            AppColors.primary,
                            AppColors.primarySoft,
                          ),
                          photoUrl: self.photoUrl,
                          size: 88,
                          circle: true,
                        )
                      : const _DefaultAvatar(size: 88),
                  const SizedBox(height: 14),
                  Text(
                    self?.fullName ?? 'My profile',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_iphone_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        if (phone != null)
                          Text(
                            _formatPhone(phone),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else if (auth.isLoadingProfile)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          Text(
                            '—',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Menu ──
            Text('Family', style: AppTextStyles.label),
            const SizedBox(height: 10),
            if (self != null) ...[
              ProfileMenuTile(
                icon: Icons.edit_outlined,
                title: 'Edit my details',
                subtitle: 'Name, photo, date of birth, mobile',
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.editMember,
                  arguments: self,
                ),
              ),
              const SizedBox(height: 10),
            ],
            ProfileMenuTile(
              icon: Icons.person_remove_outlined,
              title: 'Delete member',
              subtitle: family.hasLoaded
                  ? '${family.members.length} ${family.members.length == 1 ? 'member' : 'members'} in your family'
                  : 'Remove someone from your family',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.deleteMembers),
            ),
            const SizedBox(height: 24),
            Text('Account', style: AppTextStyles.label),
            const SizedBox(height: 10),
            ProfileMenuTile(
              icon: Icons.logout_rounded,
              title: 'Log out',
              danger: true,
              loading: _loggingOut,
              onTap: _loggingOut ? null : () => _logout(),
            ),
            const SizedBox(height: 32),
            Text(
              _version == null ? '' : 'Version $_version',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grey person icon in a circle, shown when there is no profile photo.
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: AppColors.primary.withValues(alpha: 0.6),
      ),
    );
  }
}
