import 'dart:async';

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

class _ProfileDetailsPageState extends State<ProfileDetailsPage>
    with WidgetsBindingObserver {
  late final ProfileDetailsController _controller;
  late final bool _ownsController;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ProfileDetailsController();
    _controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final resendAt =
          _controller.profile?.emailVerificationResendAvailableAtUtc;
      if (mounted &&
          resendAt != null &&
          resendAt.isAfter(DateTime.now().toUtc())) {
        setState(() {});
      }
    });
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

  Future<void> _requestEmailVerification() async {
    final authenticated = await runProtectedProfileAction(
      context,
      _controller.requestEmailVerification,
    );
    if (!authenticated && mounted) {
      leavePrivateArea(context);
      return;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = switch (_controller.verificationRequestStatus) {
      EmailVerificationRequestStatus.sent => l10n.verificationEmailSent,
      _ => switch (_controller.verificationRequestFailure) {
        EmailVerificationRequestFailure.rateLimited =>
          l10n.verificationEmailRateLimited,
        _ => l10n.verificationEmailRequestFailed,
      },
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _controller.status == ProfileLoadStatus.ready) {
      unawaited(_load(refresh: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
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
        verificationRequestStatus: _controller.verificationRequestStatus,
        onRequestEmailVerification: _requestEmailVerification,
        onRefresh: () => _load(refresh: true),
      ),
    };
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.profile,
    required this.verificationRequestStatus,
    required this.onRequestEmailVerification,
    required this.onRefresh,
  });

  final UserProfileDto profile;
  final EmailVerificationRequestStatus verificationRequestStatus;
  final VoidCallback onRequestEmailVerification;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String optional(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? l10n.notAdded : trimmed;
    }

    final resendAt = profile.emailVerificationResendAvailableAtUtc;
    final remainingSeconds = resendAt == null
        ? 0
        : resendAt.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 3600);
    final isSending =
        verificationRequestStatus == EmailVerificationRequestStatus.sending;
    final hasRequested =
        verificationRequestStatus == EmailVerificationRequestStatus.sent ||
        resendAt != null;

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
          if (!profile.isEmailVerified) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('verify-email-button'),
              onPressed: isSending || remainingSeconds > 0
                  ? null
                  : onRequestEmailVerification,
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.mark_email_read_outlined),
              label: Text(
                isSending
                    ? l10n.sendingVerificationEmail
                    : remainingSeconds > 0
                    ? l10n.resendVerificationEmailIn(remainingSeconds)
                    : hasRequested
                    ? l10n.resendVerificationEmail
                    : l10n.verifyEmail,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
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
