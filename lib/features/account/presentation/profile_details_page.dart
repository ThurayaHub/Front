import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
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
      final profile = _controller.profile;
      final resendTimes = [
        profile?.emailVerificationResendAvailableAtUtc,
        profile?.pendingEmailChange?.resendAvailableAtUtc,
        profile?.pendingPhoneChange?.resendAvailableAtUtc,
      ];
      if (mounted &&
          resendTimes.any(
            (value) => value?.isAfter(DateTime.now().toUtc()) == true,
          )) {
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
    if (!authenticated && mounted) {
      leavePrivateArea(context);
      return;
    }
    final profile = _controller.profile;
    if (mounted && profile != null) {
      await AuthScope.read(context).updateCachedUser(
        name: profile.name,
        email: profile.email,
        phoneNumber: profile.phoneNumber,
      );
    }
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

  Future<void> _editName() async {
    final l10n = AppLocalizations.of(context);
    final value = await _showTextEditor(
      title: l10n.editNameTitle,
      label: l10n.nameLabel,
      initialValue: _controller.profile?.name ?? '',
      validator: (value) => value.trim().isEmpty ? l10n.nameRequired : null,
    );
    if (value == null || !mounted) return;
    var saved = false;
    final authenticated = await runProtectedProfileAction(context, () async {
      saved = await _controller.updateName(value);
    });
    if (!authenticated && mounted) return leavePrivateArea(context);
    if (!mounted) return;
    if (saved) {
      await AuthScope.read(context).updateCachedUser(name: value.trim());
    }
    _showMessage(saved ? l10n.profileUpdateSuccess : l10n.profileUpdateFailed);
  }

  Future<void> _editEmail() async {
    final l10n = AppLocalizations.of(context);
    final current = _controller.profile;
    final value = await _showTextEditor(
      title: l10n.editEmailTitle,
      label: l10n.emailLabel,
      initialValue: current?.pendingEmailChange?.value ?? current?.email ?? '',
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        final email = value.trim();
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
            ? null
            : l10n.invalidEmail;
      },
    );
    if (value == null || !mounted) return;
    if (value.trim().toLowerCase() == current?.email?.trim().toLowerCase() &&
        current?.isEmailVerified == false) {
      await _requestEmailVerification();
      return;
    }
    final saved = await _runMutation(
      () => _controller.requestEmailChange(value),
    );
    if (mounted) {
      _showMessage(
        saved ? l10n.emailChangeRequested : l10n.profileUpdateFailed,
      );
    }
  }

  Future<void> _editPhone() async {
    final l10n = AppLocalizations.of(context);
    final current = _controller.profile;
    final value = await _showTextEditor(
      title: l10n.editPhoneTitle,
      label: l10n.phoneLabel,
      initialValue:
          current?.pendingPhoneChange?.value ?? current?.phoneNumber ?? '',
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
      validator: (value) =>
          RegExp(r'^(05\d{8}|\+9665\d{8})$').hasMatch(value.trim())
          ? null
          : l10n.invalidSaudiPhone,
    );
    if (value == null || !mounted) return;
    final saved = await _runMutation(
      () => _controller.requestPhoneChange(value),
    );
    if (!mounted) return;
    _showMessage(saved ? l10n.phoneCodeSent : l10n.profileUpdateFailed);
    if (saved) await _verifyPendingPhone();
  }

  Future<void> _verifyPendingPhone() async {
    final l10n = AppLocalizations.of(context);
    final otp = await _showTextEditor(
      title: l10n.enterOtpTitle,
      label: l10n.otpLabel,
      initialValue: '',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) =>
          RegExp(r'^\d{4,8}$').hasMatch(value.trim()) ? null : l10n.otpLabel,
    );
    if (otp == null || !mounted) return;
    final saved = await _runMutation(() => _controller.verifyPhoneChange(otp));
    if (!mounted) return;
    if (saved) {
      await AuthScope.read(
        context,
      ).updateCachedUser(phoneNumber: _controller.profile?.phoneNumber);
    }
    _showMessage(saved ? l10n.phoneVerified : l10n.profileUpdateFailed);
  }

  Future<void> _resendPendingEmail() async {
    final email = _controller.profile?.pendingEmailChange?.value;
    if (email == null) return;
    final saved = await _runMutation(
      () => _controller.requestEmailChange(email),
    );
    if (mounted) {
      _showMessage(
        saved
            ? AppLocalizations.of(context).emailChangeRequested
            : AppLocalizations.of(context).profileUpdateFailed,
      );
    }
  }

  Future<void> _resendPendingPhone() async {
    final phone = _controller.profile?.pendingPhoneChange?.value;
    if (phone == null) return;
    final saved = await _runMutation(
      () => _controller.requestPhoneChange(phone),
    );
    if (mounted) {
      _showMessage(
        saved
            ? AppLocalizations.of(context).phoneCodeSent
            : AppLocalizations.of(context).profileUpdateFailed,
      );
    }
  }

  Future<void> _cancelEmailChange() async {
    final saved = await _runMutation(_controller.cancelEmailChange);
    if (mounted) {
      _showMessage(
        saved
            ? AppLocalizations.of(context).profileUpdateSuccess
            : AppLocalizations.of(context).profileUpdateFailed,
      );
    }
  }

  Future<void> _cancelPhoneChange() async {
    final saved = await _runMutation(_controller.cancelPhoneChange);
    if (mounted) {
      _showMessage(
        saved
            ? AppLocalizations.of(context).profileUpdateSuccess
            : AppLocalizations.of(context).profileUpdateFailed,
      );
    }
  }

  Future<bool> _runMutation(Future<bool> Function() action) async {
    var saved = false;
    final authenticated = await runProtectedProfileAction(context, () async {
      saved = await action();
    });
    if (!authenticated && mounted) leavePrivateArea(context);
    return authenticated && saved;
  }

  Future<String?> _showTextEditor({
    required String title,
    required String label,
    required String initialValue,
    required String? Function(String) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) async {
    final formKey = GlobalKey<FormState>();
    var editedValue = initialValue;
    final l10n = AppLocalizations.of(context);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.screen,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const ValueKey('profile-edit-input'),
                  initialValue: initialValue,
                  autofocus: true,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: AppTextStyles.homeCardTitle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primary,
                  onChanged: (value) => editedValue = value,
                  validator: (value) => validator(value ?? ''),
                  decoration: InputDecoration(labelText: label),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const ValueKey('profile-edit-save'),
                  onPressed: () {
                    if (formKey.currentState?.validate() == true) {
                      Navigator.pop(sheetContext, editedValue.trim());
                    }
                  },
                  child: Text(l10n.saveChanges),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return value;
  }

  void _showMessage(String message) {
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
        onEditName: _editName,
        onEditEmail: _editEmail,
        onEditPhone: _editPhone,
        onVerifyPhone: _verifyPendingPhone,
        onResendEmail: _resendPendingEmail,
        onResendPhone: _resendPendingPhone,
        onCancelEmail: _cancelEmailChange,
        onCancelPhone: _cancelPhoneChange,
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
    required this.onEditName,
    required this.onEditEmail,
    required this.onEditPhone,
    required this.onVerifyPhone,
    required this.onResendEmail,
    required this.onResendPhone,
    required this.onCancelEmail,
    required this.onCancelPhone,
    required this.onRefresh,
  });

  final UserProfileDto profile;
  final EmailVerificationRequestStatus verificationRequestStatus;
  final VoidCallback onRequestEmailVerification;
  final VoidCallback onEditName;
  final VoidCallback onEditEmail;
  final VoidCallback onEditPhone;
  final VoidCallback onVerifyPhone;
  final VoidCallback onResendEmail;
  final VoidCallback onResendPhone;
  final VoidCallback onCancelEmail;
  final VoidCallback onCancelPhone;
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
                  onEdit: onEditName,
                  editKey: const ValueKey('profile-edit-name'),
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: l10n.phoneLabel,
                  value: optional(profile.phoneNumber),
                  leftToRight: profile.phoneNumber?.trim().isNotEmpty == true,
                  verified: profile.isPhoneVerified,
                  onEdit: onEditPhone,
                  editKey: const ValueKey('profile-edit-phone'),
                ),
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: l10n.emailLabel,
                  value: optional(profile.email),
                  leftToRight: profile.email?.trim().isNotEmpty == true,
                  verified: profile.isEmailVerified,
                  onEdit: onEditEmail,
                  editKey: const ValueKey('profile-edit-email'),
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
          if (profile.pendingEmailChange case final pending?) ...[
            const SizedBox(height: AppSpacing.md),
            _PendingChangeCard(
              icon: Icons.mark_email_unread_outlined,
              title: l10n.pendingEmailTitle,
              message: l10n.pendingEmailMessage(pending.value),
              resendAvailableAtUtc: pending.resendAvailableAtUtc,
              resendLabel: l10n.resendVerificationEmail,
              onResend: onResendEmail,
              onCancel: onCancelEmail,
            ),
          ],
          if (profile.pendingPhoneChange case final pending?) ...[
            const SizedBox(height: AppSpacing.md),
            _PendingChangeCard(
              icon: Icons.sms_outlined,
              title: l10n.pendingPhoneTitle,
              message: l10n.pendingPhoneMessage(pending.value),
              resendAvailableAtUtc: pending.resendAvailableAtUtc,
              resendLabel: l10n.resendCode,
              onVerify: onVerifyPhone,
              onResend: onResendPhone,
              onCancel: onCancelPhone,
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
    this.verified,
    this.onEdit,
    this.editKey,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool leftToRight;
  final bool? verified;
  final VoidCallback? onEdit;
  final Key? editKey;

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
              if (verified != null)
                Text(
                  verified!
                      ? AppLocalizations.of(context).verified
                      : AppLocalizations.of(context).unverified,
                  style: AppTextStyles.cardMetadata.copyWith(
                    color: verified!
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        if (onEdit != null)
          IconButton(
            key: editKey,
            tooltip: AppLocalizations.of(context).editProfileField,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.primary,
          ),
      ],
    ),
  );
}

class _PendingChangeCard extends StatelessWidget {
  const _PendingChangeCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.resendAvailableAtUtc,
    required this.resendLabel,
    required this.onResend,
    required this.onCancel,
    this.onVerify,
  });

  final IconData icon;
  final String title;
  final String message;
  final DateTime? resendAvailableAtUtc;
  final String resendLabel;
  final VoidCallback onResend;
  final VoidCallback onCancel;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seconds =
        resendAvailableAtUtc
            ?.difference(DateTime.now().toUtc())
            .inSeconds
            .clamp(0, 3600) ??
        0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.homeCardTitle)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTextStyles.cardMetadata),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              if (onVerify != null)
                FilledButton(onPressed: onVerify, child: Text(l10n.verifyCode)),
              TextButton(
                onPressed: seconds > 0 ? null : onResend,
                child: Text(
                  seconds > 0
                      ? l10n.resendVerificationEmailIn(seconds)
                      : resendLabel,
                ),
              ),
              TextButton(onPressed: onCancel, child: Text(l10n.cancelChange)),
            ],
          ),
        ],
      ),
    );
  }
}
