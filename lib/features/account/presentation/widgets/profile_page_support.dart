import 'package:flutter/material.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/authentication_guard.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/restaurant_image.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

Future<bool> runProtectedProfileAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await AuthenticationGuard.requireAuthentication<void>(context, action);
  } catch (_) {
    // A repeated authorization failure leaves the app anonymous. The caller
    // exits the private area without exposing the backend error.
  }
  return context.mounted && AuthScope.read(context).isAuthenticated;
}

void leavePrivateArea(BuildContext context) {
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRouteNames.home, (_) => false);
}

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              key: const ValueKey('profile-page-back'),
              tooltip: AppLocalizations.of(context).back,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primary,
            )
          else
            const SizedBox.square(dimension: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 26),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.detailsCaption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileLoadingSkeleton extends StatelessWidget {
  const ProfileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('profile-loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: const [
        _SkeletonBlock(height: 176),
        SizedBox(height: AppSpacing.md),
        _SkeletonBlock(height: 68),
        SizedBox(height: AppSpacing.sm),
        _SkeletonBlock(height: 68),
        SizedBox(height: AppSpacing.sm),
        _SkeletonBlock(height: 68),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class ProfileErrorState extends StatelessWidget {
  const ProfileErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: const ValueKey('profile-error'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.primary,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.profileLoadError,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const ValueKey('profile-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileEmptyState extends StatelessWidget {
  const ProfileEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onExplore,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEDF7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.map_outlined),
              label: Text(AppLocalizations.of(context).exploreRestaurants),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileRestaurantImage extends StatelessWidget {
  const ProfileRestaurantImage({super.key, required this.source});

  final String? source;

  @override
  Widget build(BuildContext context) => RestaurantImage(source: source);
}

String profileInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'ث';
  String firstCharacter(String value) => String.fromCharCode(value.runes.first);
  if (parts.length == 1) return firstCharacter(parts.first);
  return '${firstCharacter(parts.first)}${firstCharacter(parts.last)}';
}
