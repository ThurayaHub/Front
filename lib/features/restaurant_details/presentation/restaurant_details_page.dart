import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/rating_stars.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantDetailsPage extends StatefulWidget {
  const RestaurantDetailsPage({super.key, required this.restaurant})
    : restaurantId = null,
      detailsService = null;

  const RestaurantDetailsPage.fromId({
    super.key,
    required this.restaurantId,
    this.detailsService,
  }) : restaurant = null;

  final Restaurant? restaurant;
  final int? restaurantId;
  final RestaurantDetailsService? detailsService;

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  RestaurantDetailsService? _detailsService;
  Restaurant? _restaurant;
  int _loadGeneration = 0;
  bool _ownsDetailsService = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
    if (widget.restaurantId != null) {
      _ownsDetailsService = widget.detailsService == null;
      _detailsService = widget.detailsService ?? RestaurantDetailsService();
      _isLoading = true;
      unawaited(_loadDetails());
    }
  }

  Future<void> _loadDetails({bool showLoading = false}) async {
    final restaurantId = widget.restaurantId;
    final detailsService = _detailsService;
    if (restaurantId == null || detailsService == null) {
      return;
    }

    final loadGeneration = ++_loadGeneration;
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final details = await detailsService.getDetails(restaurantId);
      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }
      setState(() {
        _restaurant = _restaurantFromDetails(details);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Restaurant _restaurantFromDetails(RestaurantDetailsDto details) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final photos = details.photos
        .map((photo) => photo.url)
        .toList(growable: false);
    final coverPhotos = details.photos.where((photo) => photo.isCoverPhoto);
    final coverImage = coverPhotos.isNotEmpty
        ? coverPhotos.first.url
        : (photos.isEmpty ? '' : photos.first);
    final category = details.categories
        .map((category) => category.name.trim())
        .where((name) => name.isNotEmpty)
        .join('، ');
    final priceLevelName = details.priceLevelName?.trim();
    final priceLevel = priceLevelName == null || priceLevelName.isEmpty
        ? List.filled(details.priceLevelId.clamp(0, 4), r'$').join()
        : priceLevelName;

    return Restaurant(
      id: details.id,
      cardImage: coverImage,
      coverImage: coverImage,
      name: details.localizedName(languageCode),
      category: category,
      neighborhood: details.localizedNeighborhood(languageCode),
      priceLevel: priceLevel,
      rating: ((details.reviewSummary.userRatingAverage ?? 0) / 2).clamp(0, 5),
      reviewCount: details.reviewSummary.reviewCount,
      description: details.localizedDescription(languageCode),
      galleryImages: photos,
      reviews: const [],
      cardStatus: details.hasThurayaStar
          ? RestaurantCardStatus.thurayaStar
          : RestaurantCardStatus.rating,
      thurayaRating: details.thurayaReviewSummary.averageRating == null
          ? null
          : (details.thurayaReviewSummary.averageRating! / 2).clamp(0, 5),
    );
  }

  @override
  void dispose() {
    _loadGeneration++;
    if (_ownsDetailsService) {
      _detailsService?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant;
    if (restaurant != null) {
      return _RestaurantDetailsContent(
        restaurant: restaurant,
        reviewsAvailable: widget.restaurant != null,
      );
    }

    return _DetailsStatusPage(
      isLoading: _isLoading,
      onRetry: () => _loadDetails(showLoading: true),
    );
  }
}

class _RestaurantDetailsContent extends StatelessWidget {
  const _RestaurantDetailsContent({
    required this.restaurant,
    required this.reviewsAvailable,
  });

  static const double _heroHeight = 288;
  static const double _sheetTop = 264;
  static const double _sheetMinimumHeight = 781;

  final Restaurant restaurant;
  final bool reviewsAvailable;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        key: const ValueKey('restaurant-details-page'),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: _heroHeight,
              child: _RestaurantImage(
                source: restaurant.coverImage,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: _sheetTop),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _sheetMinimumHeight,
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(48),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.lg,
                      AppSpacing.screen,
                      37.667,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RestaurantHeading(restaurant: restaurant),
                        const SizedBox(height: AppSpacing.lg),
                        _RatingPanels(
                          rating: restaurant.rating,
                          reviewCount: restaurant.reviewCount,
                          hasThurayaStar:
                              restaurant.cardStatus ==
                              RestaurantCardStatus.thurayaStar,
                          onReviewsTap: reviewsAvailable
                              ? () => Navigator.of(context).pushNamed(
                                  AppRouteNames.restaurantReviews,
                                  arguments: restaurant,
                                )
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _RestaurantActions(),
                        if (restaurant.description.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _AboutSection(description: restaurant.description),
                        ],
                        if (restaurant.galleryImages.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _PhotoGallery(images: restaurant.galleryImages),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: _HeroControls(
                backLabel: localizations.back,
                saveLabel: localizations.saveRestaurant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsStatusPage extends StatelessWidget {
  const _DetailsStatusPage({required this.isLoading, required this.onRetry});

  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
                          localizations.loadingRestaurantDetails,
                          textAlign: TextAlign.center,
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
                          localizations.restaurantDetailsUnavailable,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.screenSubtitle,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          key: const ValueKey('restaurant-details-retry'),
                          onPressed: onRetry,
                          child: Text(localizations.retry),
                        ),
                      ],
                    ),
            ),
          ),
          _HeroControls(
            backLabel: localizations.back,
            saveLabel: localizations.saveRestaurant,
            showSave: false,
          ),
        ],
      ),
    );
  }
}

class _HeroControls extends StatelessWidget {
  const _HeroControls({
    required this.backLabel,
    required this.saveLabel,
    this.showSave = true,
  });

  final String backLabel;
  final String saveLabel;
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(AppSpacing.screen),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x80000000), Color(0x00000000)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FrostedCircleButton(
            key: const ValueKey('restaurant-details-back'),
            semanticLabel: backLabel,
            icon: AppAssets.restaurantBackArrow,
            iconWidth: 16,
            iconHeight: 16,
            onTap: () => Navigator.of(context).pop(),
          ),
          if (showSave)
            _FrostedCircleButton(
              semanticLabel: saveLabel,
              icon: AppAssets.restaurantBookmark,
              iconWidth: 14,
              iconHeight: 18,
              onTap: () {},
            )
          else
            const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  const _FrostedCircleButton({
    super.key,
    required this.semanticLabel,
    required this.icon,
    required this.iconWidth,
    required this.iconHeight,
    required this.onTap,
  });

  final String semanticLabel;
  final String icon;
  final double iconWidth;
  final double iconHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xCCFCF9F8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                icon,
                width: iconWidth,
                height: iconHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantHeading extends StatelessWidget {
  const _RestaurantHeading({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      restaurant.category.trim(),
      restaurant.neighborhood.trim(),
    ].where((value) => value.isNotEmpty).join(' • ');

    return SizedBox(
      height: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            restaurant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.detailsTitle,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.restaurantCutlery,
                width: 11.25,
                height: 15,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.detailsMetadata,
                ),
              ),
              if (restaurant.priceLevel.trim().isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    restaurant.priceLevel,
                    style: AppTextStyles.detailsMetadata,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingPanels extends StatelessWidget {
  const _RatingPanels({
    required this.rating,
    required this.reviewCount,
    required this.hasThurayaStar,
    required this.onReviewsTap,
  });

  final double rating;
  final int reviewCount;
  final bool hasThurayaStar;
  final VoidCallback? onReviewsTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      height: 135.333,
      child: Row(
        children: [
          if (hasThurayaStar) ...[
            Expanded(
              child: _RatingPanel(
                child: Column(
                  children: [
                    const SizedBox(height: 13.667),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.award,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        AppAssets.restaurantAwardStar,
                        width: 32,
                        height: 32,
                        colorFilter: const ColorFilter.mode(
                          AppColors.awardStar,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      localizations.thurayaStar,
                      style: AppTextStyles.detailsAwardTitle,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      localizations.thurayaStarDescription,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.detailsCaption,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Semantics(
              button: onReviewsTap != null,
              enabled: onReviewsTap != null,
              label: localizations.openRestaurantReviews,
              child: GestureDetector(
                key: const ValueKey('restaurant-details-reviews'),
                behavior: HitTestBehavior.opaque,
                onTap: onReviewsTap,
                child: _RatingPanel(
                  child: Column(
                    children: [
                      const SizedBox(height: 29),
                      const RatingStars(
                        rating: 1,
                        maxStars: 1,
                        starSize: 26.667,
                        spacing: 0,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.detailsRating,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        localizations.userReviewCount(reviewCount),
                        style: AppTextStyles.detailsReviewLink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPanel extends StatelessWidget {
  const _RatingPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000666),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RestaurantActions extends StatelessWidget {
  const _RestaurantActions();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      height: 76,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RestaurantAction(
            icon: AppAssets.restaurantPhone,
            iconWidth: 18,
            iconHeight: 18,
            label: localizations.call,
          ),
          _RestaurantAction(
            icon: AppAssets.restaurantDirections,
            iconWidth: 20,
            iconHeight: 20,
            label: localizations.directions,
          ),
          _RestaurantAction(
            icon: AppAssets.restaurantShare,
            iconWidth: 18,
            iconHeight: 20,
            label: localizations.share,
          ),
        ],
      ),
    );
  }
}

class _RestaurantAction extends StatelessWidget {
  const _RestaurantAction({
    required this.icon,
    required this.iconWidth,
    required this.iconHeight,
    required this.label,
  });

  final String icon;
  final double iconWidth;
  final double iconHeight;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 76,
      child: Column(
        children: [
          Semantics(
            button: true,
            label: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  icon,
                  width: iconWidth,
                  height: iconHeight,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, maxLines: 1, style: AppTextStyles.detailsActionLabel),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      height: 156,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.aboutRestaurant,
              textAlign: TextAlign.right,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.detailsBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      height: 192,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          children: [
            Row(
              children: [
                Text(localizations.photos, style: AppTextStyles.cardTitle),
                const Spacer(),
                Text(
                  localizations.viewAll,
                  style: AppTextStyles.detailsGalleryLink,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => SizedBox(
                    width: 128,
                    height: 128,
                    child: _RestaurantImage(
                      source: images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({required this.source, required this.fit});

  final String source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        source,
        fit: fit,
        alignment: Alignment.center,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const _RestaurantImagePlaceholder(showProgress: true),
        errorBuilder: (_, _, _) => const _RestaurantImagePlaceholder(),
      );
    }

    if (source.isNotEmpty) {
      return Image.asset(
        source,
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => const _RestaurantImagePlaceholder(),
      );
    }

    return const _RestaurantImagePlaceholder();
  }
}

class _RestaurantImagePlaceholder extends StatelessWidget {
  const _RestaurantImagePlaceholder({this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.panel,
      child: Center(
        child: showProgress
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.restaurant_rounded,
                color: AppColors.textMuted,
                size: 40,
              ),
      ),
    );
  }
}
