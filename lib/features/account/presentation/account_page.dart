import 'package:flutter/material.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/features/account/models/profile_models.dart';
import 'package:thuraya/features/account/presentation/profile_controllers.dart';
import 'package:thuraya/features/account/presentation/widgets/profile_page_support.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.controller});

  final AccountSummaryController? controller;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AccountSummaryController _controller;
  late final bool _ownsController;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AccountSummaryController();
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

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    _controller.clear();
    try {
      await AuthScope.read(context).logout();
    } catch (_) {
      // Local session clearing is guaranteed even if token revocation fails.
    }
    if (mounted) leavePrivateArea(context);
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
      key: const ValueKey('account-page'),
      backgroundColor: AppColors.background,
      bottomNavigationBar: const ThurayaBottomNavigationBar(
        selectedTab: ThurayaNavigationTab.account,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ProfilePageHeader(title: l10n.account, showBack: false),
            Expanded(child: _buildBody(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return switch (_controller.status) {
      ProfileLoadStatus.idle ||
      ProfileLoadStatus.loading => const ProfileLoadingSkeleton(),
      ProfileLoadStatus.error => ProfileErrorState(onRetry: _load),
      ProfileLoadStatus.ready => RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          key: const ValueKey('account-content'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            116,
          ),
          children: [
            _SummaryCard(summary: _controller.summary!),
            const SizedBox(height: AppSpacing.lg),
            _AccountMenuItem(
              key: const ValueKey('account-details'),
              icon: Icons.badge_outlined,
              title: l10n.profileDetailsTitle,
              subtitle: l10n.profileDetailsSubtitle,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouteNames.profileDetails),
            ),
            _AccountMenuItem(
              key: const ValueKey('account-favorites'),
              icon: Icons.favorite_border_rounded,
              title: l10n.myFavorites,
              subtitle: l10n.favoritesSubtitle,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AppRouteNames.profileFavorites),
            ),
            _AccountMenuItem(
              key: const ValueKey('account-reviews'),
              icon: Icons.rate_review_outlined,
              title: l10n.myReviews,
              subtitle: l10n.myReviewsSubtitle,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouteNames.profileReviews),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              key: const ValueKey('account-logout'),
              onPressed: _isLoggingOut ? null : _logout,
              icon: _isLoggingOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(_isLoggingOut ? l10n.loggingOut : l10n.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: Color(0x33A00012)),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    };
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ProfileSummaryDto summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = summary.phoneNumber?.trim();
    final email = summary.email?.trim();
    return Container(
      key: const ValueKey('account-summary'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121A237E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              profileInitials(summary.name),
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.name, style: AppTextStyles.cardTitle),
                if (phone != null && phone.isNotEmpty)
                  _SummaryLine(
                    icon: Icons.phone_outlined,
                    value: phone,
                    leftToRight: true,
                  ),
                if (email != null && email.isNotEmpty)
                  _SummaryLine(
                    icon: Icons.email_outlined,
                    value: email,
                    leftToRight: true,
                  ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _StatusChip(
                      icon: summary.isEmailVerified
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      label: summary.isEmailVerified
                          ? l10n.emailVerified
                          : l10n.emailUnverified,
                      verified: summary.isEmailVerified,
                    ),
                    _StatusChip(
                      icon: Icons.rate_review_outlined,
                      label: l10n.reviewsWritten(summary.reviewCount),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.value,
    this.leftToRight = false,
  });
  final IconData icon;
  final String value;
  final bool leftToRight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Directionality(
            textDirection: leftToRight
                ? TextDirection.ltr
                : Directionality.of(context),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.cardMetadata,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.verified = false,
  });
  final IconData icon;
  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: verified ? const Color(0xFFEAF6EF) : AppColors.panel,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: verified ? const Color(0xFF287A4A) : AppColors.primary,
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.cardMetadata),
      ],
    ),
  );
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    elevation: 0,
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.panelBorder),
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDF7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTextStyles.homeCardTitle),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.cardMetadata,
      ),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        color: AppColors.textMuted,
      ),
    ),
  );
}
