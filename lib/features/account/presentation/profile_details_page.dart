import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/features/account/models/profile_models.dart';
import 'package:thuraya/features/account/presentation/profile_controllers.dart';
import 'package:thuraya/features/account/presentation/widgets/profile_page_support.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key, this.controller});

  final ProfileDetailsController? controller;

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  late final ProfileDetailsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ProfileDetailsController();
    _controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load({bool refresh = false}) async {
    final authenticated = await runProtectedProfileAction(
      context,
      () => _controller.load(refresh: refresh),
    );
    if (!authenticated && mounted) leavePrivateArea(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('profile-details-page'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfilePageHeader(
              title: l10n.profileDetailsTitle,
              subtitle: l10n.profileDetailsSubtitle,
            ),
            Expanded(child: _body(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    return switch (_controller.status) {
      ProfileLoadStatus.idle ||
      ProfileLoadStatus.loading => const ProfileLoadingSkeleton(),
      ProfileLoadStatus.error => ProfileErrorState(onRetry: _load),
      ProfileLoadStatus.ready => _DetailsContent(
        profile: _controller.profile!,
        onRefresh: () => _load(refresh: true),
      ),
    };
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.profile, required this.onRefresh});

  final UserProfileDto profile;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String optional(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? l10n.notAdded : trimmed;
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey('profile-details-content'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Center(
            child: Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                profileInitials(profile.name),
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.panelBorder),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: l10n.nameLabel,
                  value: profile.name,
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: l10n.phoneLabel,
                  value: optional(profile.phoneNumber),
                  leftToRight: profile.phoneNumber?.trim().isNotEmpty == true,
                ),
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: l10n.emailLabel,
                  value: optional(profile.email),
                  leftToRight: profile.email?.trim().isNotEmpty == true,
                ),
                _DetailRow(
                  icon: profile.isEmailVerified
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  label: l10n.emailVerificationLabel,
                  value: profile.isEmailVerified
                      ? l10n.emailVerified
                      : l10n.emailUnverified,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              l10n.memberSince(profile.createdAtUtc.toLocal().year),
              style: AppTextStyles.cardMetadata,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.leftToRight = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool leftToRight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.panelBorder)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDF7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.cardMetadata),
              const SizedBox(height: 3),
              Directionality(
                textDirection: leftToRight
                    ? TextDirection.ltr
                    : Directionality.of(context),
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.homeCardTitle,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
