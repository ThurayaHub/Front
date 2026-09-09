import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/features/account/models/profile_models.dart';
import 'package:thuraya/features/account/presentation/profile_controllers.dart';
import 'package:thuraya/features/account/presentation/widgets/profile_page_support.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ProfileReviewsPage extends StatefulWidget {
  const ProfileReviewsPage({super.key, this.controller});

  final ReviewsController? controller;

  @override
  State<ProfileReviewsPage> createState() => _ProfileReviewsPageState();
}

class _ProfileReviewsPageState extends State<ProfileReviewsPage> {
  late final ReviewsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ReviewsController();
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
      key: const ValueKey('profile-reviews-page'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfilePageHeader(
              title: l10n.myReviews,
              subtitle: l10n.myReviewsSubtitle,
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
      ProfileLoadStatus.ready when _controller.reviews.isEmpty =>
        RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            key: const ValueKey('profile-reviews-empty'),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height - 180,
                child: ProfileEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: l10n.reviewsEmptyTitle,
                  subtitle: l10n.reviewsEmptySubtitle,
                  onExplore: () => leavePrivateArea(context),
                ),
              ),
            ],
          ),
        ),
      ProfileLoadStatus.ready => RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView.separated(
          key: const ValueKey('profile-reviews-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          itemCount: _controller.reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _ReviewCard(
            review: _controller.reviews[index],
            onOpen: () => Navigator.of(context).pushNamed(
              AppRouteNames.restaurantDetails,
              arguments: _controller.reviews[index].restaurantId,
            ),
          ),
        ),
      ),
    };
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onOpen});

  final ProfileReviewDto review;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim();
    final rating = review.rating.clamp(0, 5).toDouble();
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(review.createdAtUtc.toLocal());
    return Material(
      key: ValueKey('profile-review-${review.reviewId}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.panelBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: ProfileRestaurantImage(
                    source: review.restaurantMainPhotoUrl,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.arabicRestaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.homeCardTitle,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.secondary,
                          size: 19,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.rating,
                        ),
                      ],
                    ),
                    if (comment != null && comment.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        comment,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.homeCategory,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(date, style: AppTextStyles.cardMetadata),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
