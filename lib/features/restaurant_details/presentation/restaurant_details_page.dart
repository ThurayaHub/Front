import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/authentication_guard.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_star_badge.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_external_actions.dart';
import 'package:thuraya/features/restaurant_reviews/models/restaurant_reviews_data.dart';
import 'package:thuraya/features/restaurant_reviews/presentation/create_restaurant_review_sheet.dart';
import 'package:thuraya/features/restaurant_reviews/services/restaurant_review_service.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantDetailsPage extends StatefulWidget {
  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
    this.detailsService,
    this.reviewService,
    this.externalActions,
  }) : restaurantId = null,
       details = null;

  const RestaurantDetailsPage.fromId({
    super.key,
    required this.restaurantId,
    this.detailsService,
    this.reviewService,
    this.externalActions,
  }) : restaurant = null,
       details = null;

  const RestaurantDetailsPage.fromDetails({
    super.key,
    required this.details,
    this.detailsService,
    this.reviewService,
    this.externalActions,
  }) : restaurant = null,
       restaurantId = null;

  final Restaurant? restaurant;
  final int? restaurantId;
  final RestaurantDetailsDto? details;
  final RestaurantDetailsService? detailsService;
  final RestaurantReviewService? reviewService;
  final RestaurantExternalActions? externalActions;

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  late final RestaurantDetailsService _detailsService;
  late final RestaurantExternalActions _externalActions;
  late final RestaurantReviewService _reviewService;
  late final bool _ownsDetailsService;
  late final bool _ownsReviewService;
  RestaurantDetailsDto? _details;
  bool? _isFavorite;
  int? _favoriteUserId;
  int _loadGeneration = 0;
  bool _isLoading = false;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _ownsDetailsService = widget.detailsService == null;
    _detailsService = widget.detailsService ?? RestaurantDetailsService();
    _ownsReviewService = widget.reviewService == null;
    _reviewService = widget.reviewService ?? RestaurantReviewService();
    _externalActions =
        widget.externalActions ?? const RestaurantExternalActions();
    _details = widget.details;
    _isFavorite = widget.details?.isFavorite;
    if (widget.restaurantId != null) {
      _isLoading = true;
      unawaited(_loadDetails());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_details?.isFavorite != null) {
      _favoriteUserId = AuthScope.read(context).user?.id;
    }
  }

  int? get _restaurantId =>
      _details?.id ?? widget.restaurantId ?? widget.restaurant?.id;

  Future<void> _loadDetails({bool showLoading = false}) async {
    final id = _restaurantId;
    if (id == null) return;
    final generation = ++_loadGeneration;
    if (showLoading) setState(() => _isLoading = true);
    try {
      final details = await _detailsService.getDetails(id);
      if (!mounted || generation != _loadGeneration) return;
      final userId = details.isFavorite == null
          ? null
          : AuthScope.read(context).user?.id;
      setState(() {
        _details = details;
        _isFavorite = details.isFavorite;
        _favoriteUserId = details.isFavorite == null ? null : userId;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<RestaurantDetailsDto?> _ensureDetails() async {
    if (_details != null) return _details;
    final id = _restaurantId;
    if (id == null) return null;
    try {
      final details = await _detailsService.getDetails(id);
      if (!mounted) return null;
      final userId = details.isFavorite == null
          ? null
          : AuthScope.read(context).user?.id;
      setState(() {
        _details = details;
        _isFavorite = details.isFavorite;
        _favoriteUserId = details.isFavorite == null ? null : userId;
      });
      return details;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleFavoriteTap() async {
    if (_isUpdatingFavorite) {
      return;
    }
    try {
      await AuthenticationGuard.requireAuthentication<void>(
        context,
        _toggleFavorite,
      );
    } catch (_) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).favoriteUpdateUnavailable);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite) {
      return;
    }
    setState(() => _isUpdatingFavorite = true);
    try {
      final userId = AuthScope.read(context).user?.id;
      if (userId == null) {
        throw const AuthenticationRequiredException('Authentication required.');
      }
      var details = await _ensureDetails();
      if (details == null) {
        throw const ApiException('Restaurant details unavailable.');
      }
      if (_favoriteUserId != userId || _isFavorite == null) {
        details = await _detailsService.getDetails(details.id);
        if (!mounted) {
          return;
        }
        _details = details;
        _isFavorite = details.isFavorite;
        _favoriteUserId = details.isFavorite == null ? null : userId;
      }
      final result = await _detailsService.setFavorite(
        details.id,
        isFavorite: !(_isFavorite ?? false),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavorite = result.isFavorite;
        _favoriteUserId = userId;
      });
    } on AuthenticationRequiredException {
      _isFavorite = null;
      _favoriteUserId = null;
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFavorite = false);
      }
    }
  }

  Future<void> _openDirections() async {
    final unavailableMessage = AppLocalizations.of(
      context,
    ).directionsUnavailable;
    final details = await _ensureDetails();
    if (details == null || !mounted) {
      _showMessage(unavailableMessage);
      return;
    }
    try {
      if (!await _externalActions.openDirections(details) && mounted) {
        _showMessage(unavailableMessage);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(unavailableMessage);
      }
    }
  }

  Future<void> _shareRestaurant(Rect? origin) async {
    final unavailableMessage = AppLocalizations.of(context).shareUnavailable;
    final details = await _ensureDetails();
    if (details == null || !mounted) {
      _showMessage(unavailableMessage);
      return;
    }
    try {
      await _externalActions.shareRestaurant(
        details,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (mounted) {
        _showMessage(unavailableMessage);
      }
    }
  }

  void _openReviews(_RestaurantViewData restaurant) {
    final legacy = widget.restaurant;
    final data = legacy == null
        ? RestaurantReviewsData(
            restaurantId: _restaurantId!,
            restaurantName: restaurant.name,
            rating: restaurant.userRating!,
            reviewCount: restaurant.reviewCount,
            reviews: const [],
            hasReviewList: false,
          )
        : RestaurantReviewsData.fromRestaurant(legacy);
    Navigator.of(
      context,
    ).pushNamed(AppRouteNames.restaurantReviews, arguments: data);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleWriteReview(_RestaurantViewData restaurant) async {
    final id = _restaurantId;
    if (id == null) return;

    try {
      final created = await AuthenticationGuard.requireAuthentication<bool>(
        context,
        () async {
          if (!mounted) return false;
          return await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: AppColors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (_) => CreateRestaurantReviewSheet(
                  restaurantName: restaurant.name,
                  onSubmit: (stars, comment) async {
                    final submitted =
                        await AuthenticationGuard.requireAuthentication<bool>(
                          context,
                          () async {
                            await _reviewService.createReview(
                              restaurantId: id,
                              stars: stars,
                              comment: comment,
                            );
                            return true;
                          },
                        );
                    if (submitted != true) {
                      throw const AuthenticationRequiredException(
                        'Authentication is required.',
                      );
                    }
                  },
                ),
              ) ??
              false;
        },
      );

      if (created == true && mounted) {
        await _loadDetails();
        if (mounted) {
          _showMessage(AppLocalizations.of(context).reviewCreatedSuccess);
        }
      }
    } catch (_) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).reviewSubmitError);
      }
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    if (_ownsDetailsService) _detailsService.close();
    if (_ownsReviewService) _reviewService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _details != null
        ? _RestaurantViewData.fromDetails(
            _details!,
            Localizations.localeOf(context).languageCode,
          )
        : widget.restaurant == null
        ? null
        : _RestaurantViewData.fromRestaurant(widget.restaurant!);
    if (data == null) {
      return _DetailsStatusPage(
        isLoading: _isLoading,
        onRetry: () => _loadDetails(showLoading: true),
      );
    }
    return _RestaurantDetailsContent(
      restaurant: data,
      isFavorite: _isFavorite ?? false,
      isUpdatingFavorite: _isUpdatingFavorite,
      onFavoriteTap: _handleFavoriteTap,
      onDirectionsTap: _openDirections,
      onShareTap: _shareRestaurant,
      onWriteReviewTap: () => _handleWriteReview(data),
      onReviewsTap: data.hasUserReviews ? () => _openReviews(data) : null,
    );
  }
}

class _RestaurantDetailsContent extends StatelessWidget {
  const _RestaurantDetailsContent({
    required this.restaurant,
    required this.isFavorite,
    required this.isUpdatingFavorite,
    required this.onFavoriteTap,
    required this.onDirectionsTap,
    required this.onShareTap,
    required this.onWriteReviewTap,
    required this.onReviewsTap,
  });

  static const _heroHeight = 326.0;
  static const _sheetTop = 294.0;
  final _RestaurantViewData restaurant;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onDirectionsTap;
  final ValueChanged<Rect?> onShareTap;
  final VoidCallback onWriteReviewTap;
  final VoidCallback? onReviewsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            key: const ValueKey('restaurant-details-page'),
            child: Stack(
              children: [
                SizedBox(
                  key: const ValueKey('restaurant-details-hero-image'),
                  width: double.infinity,
                  height: _heroHeight,
                  child: _RestaurantImage(source: restaurant.heroImage),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: _sheetTop),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.screen,
                        30,
                        AppSpacing.screen,
                        48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RestaurantHeader(restaurant: restaurant),
                          if (restaurant.thurayaComment != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _ThurayaReview(comment: restaurant.thurayaComment!),
                          ],
                          if (restaurant.hasUserReviews) ...[
                            const SizedBox(height: AppSpacing.md),
                            _UserReviewsTile(
                              rating: restaurant.userRating!,
                              reviewCount: restaurant.reviewCount,
                              onTap: onReviewsTap!,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          _RestaurantActions(
                            onDirectionsTap: onDirectionsTap,
                            onShareTap: onShareTap,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            key: const ValueKey('restaurant-write-review'),
                            onPressed: onWriteReviewTap,
                            icon: const Icon(Icons.rate_review_rounded),
                            label: Text(l10n.writeYourReview),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: .045,
                              ),
                              minimumSize: const Size.fromHeight(54),
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: .2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (restaurant.description.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _AboutSection(description: restaurant.description),
                          ],
                          if (restaurant.galleryImages.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _PhotoGallery(
                              images: restaurant.galleryImages,
                              allImages: restaurant.allImages,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _HeroControls(
            backLabel: l10n.back,
            favoriteLabel: isFavorite
                ? l10n.removeFromFavorites
                : l10n.addToFavorites,
            isFavorite: isFavorite,
            isUpdatingFavorite: isUpdatingFavorite,
            onFavoriteTap: onFavoriteTap,
          ),
        ],
      ),
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  const _RestaurantHeader({required this.restaurant});
  final _RestaurantViewData restaurant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                restaurant.name,
                textAlign: TextAlign.start,
                style: AppTextStyles.detailsTitle.copyWith(fontSize: 26),
              ),
            ),
            if (restaurant.thurayaRating != null) ...[
              const SizedBox(width: AppSpacing.md),
              _ThurayaRating(rating: restaurant.thurayaRating!),
            ],
          ],
        ),
        if (restaurant.hasThurayaStar) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ThurayaStarBadge(
              key: const ValueKey('restaurant-details-thuraya-star'),
              hasThurayaStar: true,
              size: 30,
              variant: ThurayaStarBadgeVariant.full,
            ),
          ),
        ],
        if (restaurant.metadata.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.restaurant_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              Text(
                restaurant.metadata,
                style: AppTextStyles.detailsMetadata.copyWith(fontSize: 14),
              ),
              if (restaurant.priceLevel.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    restaurant.priceLevel,
                    style: AppTextStyles.detailsMetadata.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (restaurant.address.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  restaurant.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardMetadata.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ThurayaRating extends StatelessWidget {
  const _ThurayaRating({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('restaurant-details-thuraya-rating'),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 3),
                Text(
                  _formatRating(rating),
                  style: AppTextStyles.homeThurayaRating,
                ),
              ],
            ),
          ),
          Text(
            AppLocalizations.of(context).thurayaRatingLabel,
            style: AppTextStyles.detailsCaption.copyWith(
              color: AppColors.primary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThurayaReview extends StatelessWidget {
  const _ThurayaReview({required this.comment});
  final String comment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const ValueKey('restaurant-details-thuraya-review'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: .09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.thurayaReviewLabel,
                style: AppTextStyles.detailsAwardTitle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            comment,
            textAlign: TextAlign.start,
            style: AppTextStyles.detailsBody.copyWith(
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserReviewsTile extends StatelessWidget {
  const _UserReviewsTile({
    required this.rating,
    required this.reviewCount,
    required this.onTap,
  });
  final double rating;
  final int reviewCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const ValueKey('restaurant-details-reviews'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.panelBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.secondary,
                size: 25,
              ),
              const SizedBox(width: AppSpacing.xs),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  _formatRating(rating),
                  style: AppTextStyles.detailsRating,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.ratingCount(reviewCount),
                style: AppTextStyles.detailsMetadata.copyWith(fontSize: 14),
              ),
              const Spacer(),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantActions extends StatelessWidget {
  const _RestaurantActions({
    required this.onDirectionsTap,
    required this.onShareTap,
  });
  final VoidCallback onDirectionsTap;
  final ValueChanged<Rect?> onShareTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            key: const ValueKey('restaurant-details-directions'),
            icon: Icons.directions_rounded,
            label: l10n.directions,
            onTap: onDirectionsTap,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Builder(
            builder: (buttonContext) => _ActionButton(
              key: const ValueKey('restaurant-details-share'),
              icon: Icons.ios_share_rounded,
              label: l10n.share,
              onTap: () {
                final box = buttonContext.findRenderObject() as RenderBox?;
                onShareTap(
                  box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 21),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: AppTextStyles.detailsActionLabel.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('restaurant-details-about'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: AppLocalizations.of(context).aboutRestaurant),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          textAlign: TextAlign.start,
          style: AppTextStyles.detailsBody.copyWith(height: 1.75),
        ),
      ],
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.images, required this.allImages});
  final List<String> images;
  final List<String> allImages;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('restaurant-details-photos'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: AppLocalizations.of(context).photos),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final image = images[index];
              return InkWell(
                key: ValueKey('restaurant-gallery-image-$index'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _PhotoViewer(
                      photos: allImages,
                      initialIndex: allImages
                          .indexOf(image)
                          .clamp(0, allImages.length - 1),
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 164,
                    child: _RestaurantImage(source: image),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    textAlign: TextAlign.start,
    style: AppTextStyles.cardTitle.copyWith(fontSize: 19),
  );
}

class _HeroControls extends StatelessWidget {
  const _HeroControls({
    required this.backLabel,
    required this.favoriteLabel,
    required this.isFavorite,
    required this.isUpdatingFavorite,
    required this.onFavoriteTap,
    this.showFavorite = true,
  });
  final String backLabel;
  final String favoriteLabel;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final VoidCallback onFavoriteTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FrostedCircleButton(
              key: const ValueKey('restaurant-details-back'),
              semanticLabel: backLabel,
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
                size: 23,
              ),
            ),
            if (showFavorite)
              _FrostedCircleButton(
                key: const ValueKey('restaurant-details-favorite'),
                semanticLabel: favoriteLabel,
                onTap: isUpdatingFavorite ? null : onFavoriteTap,
                child: isUpdatingFavorite
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.hot : AppColors.primary,
                        size: 23,
                      ),
              )
            else
              const SizedBox.square(dimension: 48),
          ],
        ),
      ),
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  const _FrostedCircleButton({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });
  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: AppColors.surface.withValues(alpha: .9),
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: 48,
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initialIndex});
  final List<String> photos;
  final int initialIndex;
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller;
  late int _current;
  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('restaurant-photo-viewer'),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (value) => setState(() => _current = value),
            itemBuilder: (_, index) => InteractiveViewer(
              child: Center(
                child: _RestaurantImage(
                  source: widget.photos[index],
                  fit: BoxFit.contain,
                  fallbackColor: Colors.black,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${_current + 1} / ${widget.photos.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.source,
    this.fit = BoxFit.cover,
    this.fallbackColor = AppColors.panel,
  });
  final String source;
  final BoxFit fit;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: fallbackColor,
      child: Image.asset(AppAssets.restaurantDetailsCover, fit: fit),
    );
    final value = source.trim();
    if (value.isEmpty) return fallback;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : ColoredBox(
                color: fallbackColor,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
      );
    }
    return Image.asset(
      value,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _DetailsStatusPage extends StatelessWidget {
  const _DetailsStatusPage({required this.isLoading, required this.onRetry});
  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: isLoading
                  ? Column(
                      key: const ValueKey('restaurant-details-loading'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.loadingRestaurantDetails,
                          style: AppTextStyles.screenSubtitle,
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('restaurant-details-error'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.restaurantDetailsUnavailable,
                          style: AppTextStyles.screenSubtitle,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          key: const ValueKey('restaurant-details-retry'),
                          onPressed: onRetry,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
            ),
          ),
          _HeroControls(
            backLabel: l10n.back,
            favoriteLabel: l10n.addToFavorites,
            isFavorite: false,
            isUpdatingFavorite: false,
            onFavoriteTap: () {},
            showFavorite: false,
          ),
        ],
      ),
    );
  }
}

class _RestaurantViewData {
  const _RestaurantViewData({
    required this.name,
    required this.description,
    required this.metadata,
    required this.address,
    required this.priceLevel,
    required this.heroImage,
    required this.galleryImages,
    required this.allImages,
    required this.userRating,
    required this.reviewCount,
    required this.hasThurayaStar,
    required this.thurayaRating,
    required this.thurayaComment,
  });

  factory _RestaurantViewData.fromDetails(
    RestaurantDetailsDto details,
    String languageCode,
  ) {
    final photos = details.photos
        .map((photo) => photo.url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final categories = details.categories
        .map((category) => category.name.trim())
        .where((name) => name.isNotEmpty)
        .join('، ');
    final neighborhood = details.localizedNeighborhood(languageCode).trim();
    final priceName = details.priceLevelName?.trim();
    final latestComment = details.thurayaReviewSummary.latestReview?.comment
        .trim();
    return _RestaurantViewData(
      name: details.localizedName(languageCode).trim(),
      description: details.localizedDescription(languageCode).trim(),
      metadata: [
        categories,
        neighborhood,
      ].where((value) => value.isNotEmpty).join(' • '),
      address: details.address.trim(),
      priceLevel: priceName == null || priceName.isEmpty
          ? List.filled(details.priceLevelId.clamp(0, 4), r'$').join()
          : priceName,
      heroImage: photos.isEmpty ? '' : photos.first,
      galleryImages: photos.length < 2
          ? const []
          : photos.skip(1).toList(growable: false),
      allImages: photos,
      userRating:
          details.reviewSummary.userRatingAverage == null ||
              details.reviewSummary.reviewCount <= 0
          ? null
          : details.reviewSummary.userRatingAverage!.clamp(0, 5),
      reviewCount: details.reviewSummary.reviewCount,
      hasThurayaStar: details.hasThurayaStar,
      thurayaRating:
          details.thurayaReviewSummary.averageRating == null ||
              details.thurayaReviewSummary.totalReviews <= 0
          ? null
          : (details.thurayaReviewSummary.averageRating! / 2).clamp(0, 5),
      thurayaComment: latestComment == null || latestComment.isEmpty
          ? null
          : latestComment,
    );
  }

  factory _RestaurantViewData.fromRestaurant(Restaurant restaurant) {
    final photos = <String>[restaurant.coverImage, ...restaurant.galleryImages]
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toSet()
        .toList();
    return _RestaurantViewData(
      name: restaurant.name.trim(),
      description: restaurant.description.trim(),
      metadata: [
        restaurant.category.trim(),
        restaurant.neighborhood.trim(),
      ].where((value) => value.isNotEmpty).join(' • '),
      address: '',
      priceLevel: restaurant.priceLevel.trim(),
      heroImage: photos.isEmpty ? '' : photos.first,
      galleryImages: photos.length < 2
          ? const []
          : photos.skip(1).toList(growable: false),
      allImages: photos,
      userRating: restaurant.rating > 0 && restaurant.reviewCount > 0
          ? restaurant.rating
          : null,
      reviewCount: restaurant.reviewCount,
      hasThurayaStar: restaurant.hasThurayaStar,
      thurayaRating:
          restaurant.thurayaRating != null && restaurant.thurayaRating! > 0
          ? restaurant.thurayaRating
          : null,
      thurayaComment: null,
    );
  }

  final String name;
  final String description;
  final String metadata;
  final String address;
  final String priceLevel;
  final String heroImage;
  final List<String> galleryImages;
  final List<String> allImages;
  final double? userRating;
  final int reviewCount;
  final bool hasThurayaStar;
  final double? thurayaRating;
  final String? thurayaComment;
  bool get hasUserReviews => userRating != null && reviewCount > 0;
}

String _formatRating(double rating) => rating == rating.roundToDouble()
    ? rating.toStringAsFixed(0)
    : rating.toStringAsFixed(1);
