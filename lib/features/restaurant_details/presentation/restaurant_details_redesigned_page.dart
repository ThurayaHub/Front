import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/authentication_guard.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/widgets/rating_stars.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_external_actions.dart';
import 'package:thuraya/features/restaurant_reviews/presentation/create_restaurant_review_sheet.dart';
import 'package:thuraya/features/restaurant_reviews/services/restaurant_review_service.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/features/restaurants/models/restaurant_review.dart';
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

enum _ReviewStatus { idle, loading, ready, error }

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  late final RestaurantDetailsService _detailsService;
  late final RestaurantReviewService _reviewService;
  late final RestaurantExternalActions _externalActions;
  late final bool _ownsDetailsService;
  late final bool _ownsReviewService;
  RestaurantDetailsDto? _details;
  bool? _isFavorite;
  int? _favoriteUserId;
  bool _isLoading = false;
  bool _isUpdatingFavorite = false;
  int _loadGeneration = 0;
  _ReviewStatus _reviewStatus = _ReviewStatus.idle;
  List<RestaurantReview> _reviews = const [];

  int? get _restaurantId =>
      _details?.id ?? widget.restaurantId ?? widget.restaurant?.id;

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
    if (widget.restaurant != null) {
      _reviews = widget.restaurant!.reviews
          .where((review) => review.isPublished)
          .toList(growable: false);
      _reviewStatus = _ReviewStatus.ready;
    }
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

  Future<void> _loadReviews({bool force = false}) async {
    final id = _restaurantId;
    if (id == null || (!force && _reviewStatus != _ReviewStatus.idle)) return;
    setState(() => _reviewStatus = _ReviewStatus.loading);
    try {
      final reviews = await _reviewService.getReviews(id);
      if (!mounted) return;
      setState(() {
        _reviews = reviews.where((r) => r.isPublished).toList(growable: false);
        _reviewStatus = _ReviewStatus.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _reviewStatus = _ReviewStatus.error);
    }
  }

  Future<void> _favorite() async {
    if (_isUpdatingFavorite) return;
    try {
      await AuthenticationGuard.requireAuthentication<void>(
        context,
        _toggleFavorite,
      );
    } catch (_) {
      if (mounted) {
        _message(AppLocalizations.of(context).favoriteUpdateUnavailable);
      }
    }
  }

  Future<void> _toggleFavorite() async {
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
        if (!mounted) return;
        _details = details;
        _isFavorite = details.isFavorite;
        _favoriteUserId = details.isFavorite == null ? null : userId;
      }
      final result = await _detailsService.setFavorite(
        details.id,
        isFavorite: !(_isFavorite ?? false),
      );
      if (!mounted) return;
      setState(() {
        _isFavorite = result.isFavorite;
        _favoriteUserId = userId;
      });
    } on AuthenticationRequiredException {
      _isFavorite = null;
      _favoriteUserId = null;
      rethrow;
    } finally {
      if (mounted) setState(() => _isUpdatingFavorite = false);
    }
  }

  Future<void> _directions() async {
    final unavailable = AppLocalizations.of(context).directionsUnavailable;
    final details = await _ensureDetails();
    if (details == null || !mounted) return _message(unavailable);
    try {
      if (!await _externalActions.openDirections(details) && mounted) {
        _message(unavailable);
      }
    } catch (_) {
      if (mounted) _message(unavailable);
    }
  }

  Future<void> _share(Rect? origin) async {
    final unavailable = AppLocalizations.of(context).shareUnavailable;
    final details = await _ensureDetails();
    if (details == null || !mounted) return _message(unavailable);
    try {
      await _externalActions.shareRestaurant(
        details,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (mounted) _message(unavailable);
    }
  }

  Future<void> _writeReview(_ViewData restaurant) async {
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
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (_) => CreateRestaurantReviewSheet(
                  restaurantName: restaurant.name,
                  onSubmit: (stars, comment) async {
                    await _reviewService.createReview(
                      restaurantId: id,
                      stars: stars,
                      comment: comment,
                    );
                  },
                ),
              ) ??
              false;
        },
      );
      if (created == true && mounted) {
        await _loadDetails();
        if (!mounted) return;
        setState(() => _reviewStatus = _ReviewStatus.idle);
        unawaited(_loadReviews());
        _message(AppLocalizations.of(context).reviewCreatedSuccess);
      }
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).reviewSubmitError);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        ? _ViewData.fromDetails(
            _details!,
            Localizations.localeOf(context).languageCode,
          )
        : widget.restaurant == null
        ? null
        : _ViewData.fromRestaurant(widget.restaurant!);
    if (data == null) {
      return _StatusPage(
        loading: _isLoading,
        onRetry: () => _loadDetails(showLoading: true),
      );
    }
    return _DetailsView(
      restaurant: data,
      reviews: _reviews,
      reviewStatus: _reviewStatus,
      isFavorite: _isFavorite ?? false,
      updatingFavorite: _isUpdatingFavorite,
      onFavorite: _favorite,
      onDirections: _directions,
      onShare: _share,
      onWriteReview: () => _writeReview(data),
      onLoadReviews: _loadReviews,
    );
  }
}

class _DetailsView extends StatefulWidget {
  const _DetailsView({
    required this.restaurant,
    required this.reviews,
    required this.reviewStatus,
    required this.isFavorite,
    required this.updatingFavorite,
    required this.onFavorite,
    required this.onDirections,
    required this.onShare,
    required this.onWriteReview,
    required this.onLoadReviews,
  });
  final _ViewData restaurant;
  final List<RestaurantReview> reviews;
  final _ReviewStatus reviewStatus;
  final bool isFavorite;
  final bool updatingFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onDirections;
  final ValueChanged<Rect?> onShare;
  final VoidCallback onWriteReview;
  final Future<void> Function({bool force}) onLoadReviews;

  @override
  State<_DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<_DetailsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this)..addListener(_tabChanged);
  }

  void _tabChanged() {
    if (_tabs.index == 1) unawaited(widget.onLoadReviews());
  }

  void _showReviews() {
    _tabs.animateTo(1);
    unawaited(widget.onLoadReviews());
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_tabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _Palette.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: _BottomBar(
        onDirections: widget.onDirections,
        onReview: widget.onWriteReview,
      ),
      body: NestedScrollView(
        key: const ValueKey('restaurant-details-page'),
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            pinned: false,
            stretch: true,
            expandedHeight: 250,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 66,
            leading: Padding(
              padding: const EdgeInsetsDirectional.only(start: 10),
              child: _GlassButton(
                key: const ValueKey('restaurant-details-back'),
                label: l10n.back,
                onTap: () => Navigator.of(context).pop(),
                child: const BackButtonIcon(),
              ),
            ),
            actions: [
              _GlassButton(
                key: const ValueKey('restaurant-details-favorite'),
                label: widget.isFavorite
                    ? l10n.removeFromFavorites
                    : l10n.addToFavorites,
                onTap: widget.updatingFavorite ? null : widget.onFavorite,
                child: widget.updatingFavorite
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: widget.isFavorite
                            ? const Color(0xFFFF6978)
                            : Colors.white,
                      ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (buttonContext) => _GlassButton(
                  key: const ValueKey('restaurant-details-share'),
                  label: l10n.share,
                  wide: true,
                  onTap: () {
                    final box = buttonContext.findRenderObject() as RenderBox?;
                    widget.onShare(
                      box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ios_share_rounded, size: 19),
                      const SizedBox(width: 6),
                      Text(
                        l10n.share,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroGallery(photos: widget.restaurant.photos),
            ),
          ),
          SliverToBoxAdapter(child: _Identity(data: widget.restaurant)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsDelegate(
              color: colors.surface,
              border: colors.border,
              child: TabBar(
                controller: _tabs,
                labelColor: colors.primary,
                unselectedLabelColor: colors.secondaryText,
                indicatorColor: AppColors.secondary,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: l10n.overviewTab),
                  Tab(
                    key: widget.restaurant.hasReviews
                        ? const ValueKey('restaurant-details-reviews')
                        : null,
                    text: l10n.reviewsTitle,
                  ),
                  Tab(text: l10n.photos),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _Overview(
              data: widget.restaurant,
              onReviews: _showReviews,
              onDirections: widget.onDirections,
            ),
            _Reviews(
              data: widget.restaurant,
              reviews: widget.reviews,
              status: widget.reviewStatus,
              onRetry: () => widget.onLoadReviews(force: true),
              onWriteReview: widget.onWriteReview,
            ),
            _Photos(photos: widget.restaurant.photos),
          ],
        ),
      ),
    );
  }
}

class _HeroGallery extends StatefulWidget {
  const _HeroGallery({required this.photos});
  final List<String> photos;
  @override
  State<_HeroGallery> createState() => _HeroGalleryState();
}

class _HeroGalleryState extends State<_HeroGallery> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    final photos = widget.photos.isEmpty ? const [''] : widget.photos;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: const ValueKey('restaurant-details-hero-image'),
          itemCount: photos.length,
          onPageChanged: (index) => setState(() => current = index),
          itemBuilder: (_, index) => GestureDetector(
            onTap: widget.photos.isEmpty
                ? null
                : () => _openViewer(context, widget.photos, index),
            child: _RestaurantImage(source: photos[index]),
          ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Color(0x55000000),
                ],
                stops: [0, .52, 1],
              ),
            ),
          ),
        ),
        if (widget.photos.length > 1)
          PositionedDirectional(
            end: 16,
            bottom: 14,
            child: _PhotoCount(
              current: current + 1,
              total: widget.photos.length,
            ),
          ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.data});
  final _ViewData data;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              data.name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            if (data.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: data.categories
                    .map((item) => _Chip(label: item))
                    .toList(growable: false),
              ),
            ],
            if (data.neighborhood.isNotEmpty || data.price.isNotEmpty) ...[
              const SizedBox(height: 11),
              Wrap(
                spacing: 16,
                runSpacing: 7,
                children: [
                  if (data.neighborhood.isNotEmpty)
                    _Meta(
                      icon: Icons.location_on_outlined,
                      text: data.neighborhood,
                    ),
                  if (data.price.isNotEmpty)
                    _Meta(
                      icon: Icons.payments_outlined,
                      text: data.price,
                      ltr: true,
                    ),
                ],
              ),
            ],
            if (data.photos.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.photos.length - 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (context, index) => Material(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: ValueKey('restaurant-gallery-image-$index'),
                      onTap: () => _openViewer(context, data.photos, index + 1),
                      child: SizedBox(
                        width: 76,
                        child: _RestaurantImage(source: data.photos[index + 1]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.data,
    required this.onReviews,
    required this.onDirections,
  });
  final _ViewData data;
  final VoidCallback onReviews;
  final VoidCallback onDirections;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final highlights =
        data.thurayaRating != null || data.hasStar || data.hasReviews;
    return ListView(
      key: const PageStorageKey('restaurant-overview-scroll'),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 40),
      children: [
        if (highlights) ...[
          _Title(l10n.restaurantHighlights),
          const SizedBox(height: 11),
          _Highlights(data: data, onReviews: onReviews),
        ],
        if (data.thurayaEvaluations.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ThurayaEvaluations(data.thurayaEvaluations),
        ],
        if (data.description.isNotEmpty) ...[
          const SizedBox(height: 26),
          _Title(l10n.aboutRestaurant),
          const SizedBox(height: 9),
          _Description(data.description),
        ],
        if (data.hasInfo) ...[
          const SizedBox(height: 26),
          _Title(l10n.restaurantInformation),
          const SizedBox(height: 9),
          _InfoCard(data),
        ],
        if (data.address.isNotEmpty) ...[
          const SizedBox(height: 26),
          _Title(l10n.restaurantLocation),
          const SizedBox(height: 9),
          _Location(data: data, onDirections: onDirections),
        ],
      ],
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights({required this.data, required this.onReviews});
  final _ViewData data;
  final VoidCallback onReviews;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (_, box) {
        final width = (box.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (data.thurayaRating != null)
              SizedBox(
                width: width,
                child: _Metric(
                  key: const ValueKey('restaurant-details-thuraya-rating'),
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.thurayaRatingLabel,
                  value: _rating(data.thurayaRating!),
                  detail: l10n.outOfFive,
                  branded: true,
                ),
              ),
            if (data.hasReviews)
              SizedBox(
                width: width,
                child: _Metric(
                  icon: Icons.star_rounded,
                  title: l10n.reviewsTitle,
                  value: _rating(data.userRating!),
                  detail: data.reviewCount.toString(),
                  onTap: onReviews,
                ),
              ),
            if (data.hasStar)
              SizedBox(
                width: box.maxWidth,
                child: _StarAward(onTap: () => _starInfo(context)),
              ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    this.branded = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final bool branded;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    final card = Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: branded ? colors.tint : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: branded
              ? colors.primary.withValues(alpha: .22)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: branded ? colors.primary : AppColors.secondary),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
    return onTap == null
        ? card
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: card,
            ),
          );
  }
}

class _StarAward extends StatelessWidget {
  const _StarAward({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _Palette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('restaurant-details-thuraya-star'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.navy, colors.navy.withValues(alpha: .88)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: .7),
            ),
          ),
          child: Row(
            children: [
              Image.asset(AppAssets.thurayaStar, width: 43, height: 43),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.thurayaStar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      l10n.thurayaStarDescription,
                      style: const TextStyle(
                        color: Color(0xFFD8D8E4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.info_outline, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThurayaEvaluations extends StatelessWidget {
  const _ThurayaEvaluations(this.evaluations);
  final List<_ThurayaEvaluationData> evaluations;

  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const ValueKey('restaurant-details-thuraya-review'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                l10n.thurayaEvaluations,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < evaluations.length; index++) ...[
            if (index > 0) ...[
              Divider(color: colors.primary.withValues(alpha: .12)),
              const SizedBox(height: 4),
            ],
            _ThurayaEvaluation(
              evaluation: evaluations[index],
              l10n: l10n,
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }
}

class _ThurayaEvaluation extends StatelessWidget {
  const _ThurayaEvaluation({
    required this.evaluation,
    required this.l10n,
    required this.colors,
  });

  final _ThurayaEvaluationData evaluation;
  final AppLocalizations l10n;
  final _Palette colors;

  @override
  Widget build(BuildContext context) {
    final createdDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(evaluation.createdAtUtc.toLocal());
    final updatedDate = evaluation.updatedAtUtc == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatMediumDate(evaluation.updatedAtUtc!.toLocal());
    return Semantics(
      label: '${l10n.thurayaRatingLabel} ${_rating(evaluation.stars)}',
      child: Column(
        key: ValueKey('restaurant-details-admin-rating-${evaluation.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: RatingStars(
                  rating: evaluation.stars,
                  starSize: 18,
                  spacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${_rating(evaluation.stars)} / 5',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            l10n.thurayaRatedOn(createdDate),
            key: ValueKey(
              'restaurant-details-admin-rating-date-${evaluation.id}',
            ),
            style: TextStyle(color: colors.secondaryText, fontSize: 12),
          ),
          if (updatedDate != null)
            Text(
              l10n.thurayaRatingUpdatedOn(updatedDate),
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
            ),
          if (evaluation.comment case final comment?) ...[
            const SizedBox(height: 9),
            Text(
              comment,
              style: TextStyle(
                color: colors.secondaryText,
                height: 1.65,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Description extends StatefulWidget {
  const _Description(this.text);
  final String text;
  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final long = widget.text.length > 180;
    final colors = _Palette.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('restaurant-details-about'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.text,
          maxLines: long && !expanded ? 4 : null,
          overflow: long && !expanded ? TextOverflow.ellipsis : null,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 15,
            height: 1.7,
          ),
        ),
        if (long)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? l10n.showLess : l10n.readMore),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.data);
  final _ViewData data;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <Widget>[
      if (data.categories.isNotEmpty)
        _Info(
          Icons.restaurant_menu_rounded,
          l10n.cuisines,
          data.categories.join('، '),
        ),
      if (data.price.isNotEmpty)
        _Info(Icons.payments_outlined, l10n.price, data.price, ltr: true),
    ];
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value, {this.ltr = false});
  final IconData icon;
  final String label;
  final String value;
  final bool ltr;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Directionality(
              textDirection: ltr
                  ? TextDirection.ltr
                  : Directionality.of(context),
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Location extends StatelessWidget {
  const _Location({required this.data, required this.onDirections});
  final _ViewData data;
  final VoidCallback onDirections;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.tint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.location_on_outlined, color: colors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.neighborhood.isNotEmpty)
                      Text(
                        data.neighborhood,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      data.address,
                      style: TextStyle(
                        color: colors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_rounded),
            label: Text(AppLocalizations.of(context).directions),
          ),
        ],
      ),
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({
    required this.data,
    required this.reviews,
    required this.status,
    required this.onRetry,
    required this.onWriteReview,
  });
  final _ViewData data;
  final List<RestaurantReview> reviews;
  final _ReviewStatus status;
  final Future<void> Function() onRetry;
  final VoidCallback onWriteReview;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _Palette.of(context);
    return KeyedSubtree(
      key: const ValueKey('restaurant-reviews-list'),
      child: CustomScrollView(
        key: const PageStorageKey('restaurant-reviews-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _Card(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.userRating == null
                              ? '—'
                              : _rating(data.userRating!),
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.outOfFive,
                          style: TextStyle(color: colors.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RatingStars(
                            rating: data.userRating ?? 0,
                            starSize: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.ratingCount(data.reviewCount),
                            style: TextStyle(color: colors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: l10n.writeYourReview,
                      onPressed: onWriteReview,
                      icon: const Icon(Icons.rate_review_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
          switch (status) {
            _ReviewStatus.idle ||
            _ReviewStatus.loading => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  key: ValueKey('restaurant-reviews-loading'),
                ),
              ),
            ),
            _ReviewStatus.error => SliverFillRemaining(
              hasScrollBody: false,
              child: _Empty(
                key: const ValueKey('restaurant-reviews-error'),
                icon: Icons.cloud_off,
                title: l10n.reviewsLoadError,
                action: l10n.retry,
                onAction: onRetry,
              ),
            ),
            _ReviewStatus.ready when reviews.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: _Empty(
                key: const ValueKey('restaurant-reviews-empty'),
                icon: Icons.reviews_outlined,
                title: l10n.noReviewsYet,
              ),
            ),
            _ReviewStatus.ready => SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 40),
              sliver: SliverList.separated(
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _ReviewCard(reviews[index]),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(this.review);
  final RestaurantReview review;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    final comment = review.comment?.trim();
    final initial = review.reviewerName.trim().isEmpty
        ? '•'
        : review.reviewerName.trim().characters.first;
    return _Card(
      key: ValueKey('review-card-${review.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.tint,
                foregroundColor: colors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(review.createdAtUtc.toLocal()),
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: RatingStars(
                  rating: review.ratingOutOfFive,
                  starSize: 16,
                  spacing: 1,
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              key: ValueKey('review-comment-${review.id}'),
              style: TextStyle(color: colors.secondaryText, height: 1.55),
            ),
          ],
        ],
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos});
  final List<String> photos;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (photos.isEmpty) {
      return _Empty(
        icon: Icons.photo_library_outlined,
        title: l10n.noPhotosAvailable,
        subtitle: l10n.noPhotosAvailableSubtitle,
      );
    }
    return GridView.builder(
      key: const PageStorageKey('restaurant-photos-scroll'),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: .88,
      ),
      itemCount: photos.length,
      itemBuilder: (_, index) => Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: index == 0
              ? const ValueKey('restaurant-photo-cover')
              : ValueKey('restaurant-gallery-image-${index - 1}'),
          onTap: () => _openViewer(context, photos, index),
          child: _RestaurantImage(source: photos[index]),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onDirections, required this.onReview});
  final VoidCallback onDirections;
  final VoidCallback onReview;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: FilledButton.icon(
                key: const ValueKey('restaurant-details-directions'),
                onPressed: onDirections,
                icon: const Icon(Icons.directions_rounded),
                label: Text(l10n.directions),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 5,
              child: OutlinedButton.icon(
                key: const ValueKey('restaurant-write-review'),
                onPressed: onReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(
                  l10n.writeYourReview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: _Palette.of(context).primaryText,
      fontSize: 19,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: colors.secondaryText, fontSize: 12),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.ltr = false});
  final IconData icon;
  final String text;
  final bool ltr;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: colors.secondaryText),
        const SizedBox(width: 5),
        Directionality(
          textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
          child: Text(
            text,
            style: TextStyle(color: colors.secondaryText, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
    this.actionKey,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final Future<void> Function()? onAction;
  final Key? actionKey;
  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: colors.secondaryText),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText),
              ),
            ],
            if (action != null && onAction != null) ...[
              const SizedBox(height: 10),
              TextButton(
                key: actionKey,
                onPressed: onAction,
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.wide = false,
  });
  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final bool wide;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Center(
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Material(
            color: const Color(0x990A0A12),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: wide ? 110 : 46,
                height: 46,
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 22),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  const _TabsDelegate({
    required this.child,
    required this.color,
    required this.border,
  });
  final Widget child;
  final Color color;
  final Color border;
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      border: Border(bottom: BorderSide(color: border)),
    ),
    child: child,
  );
  @override
  bool shouldRebuild(covariant _TabsDelegate old) =>
      old.color != color || old.border != border;
}

class _PhotoCount extends StatelessWidget {
  const _PhotoCount({required this.current, required this.total});
  final int current;
  final int total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        '$current / $total',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initial});
  final List<String> photos;
  final int initial;
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController controller;
  late int current;
  @override
  void initState() {
    super.initState();
    current = widget.initial;
    controller = PageController(initialPage: current);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('restaurant-photo-viewer'),
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        PageView.builder(
          controller: controller,
          itemCount: widget.photos.length,
          onPageChanged: (value) => setState(() => current = value),
          itemBuilder: (_, index) => InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: _RestaurantImage(
                source: widget.photos[index],
                fit: BoxFit.contain,
                fallback: Colors.black,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
                _PhotoCount(current: current + 1, total: widget.photos.length),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

void _openViewer(BuildContext context, List<String> photos, int initial) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _PhotoViewer(photos: photos, initial: initial),
    ),
  );
}

Future<void> _starInfo(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Image.asset(AppAssets.thurayaStar, width: 58, height: 58),
      title: Text(l10n.thurayaStarMeaning, textAlign: TextAlign.center),
      content: Text(
        l10n.thurayaStarMeaningDescription,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.source,
    this.fit = BoxFit.cover,
    this.fallback,
  });
  final String source;
  final BoxFit fit;
  final Color? fallback;
  @override
  Widget build(BuildContext context) {
    final replacement = ColoredBox(
      color: fallback ?? _Palette.of(context).panel,
      child: Image.asset(AppAssets.restaurantDetailsCover, fit: fit),
    );
    final value = source.trim();
    if (value.isEmpty) return replacement;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => replacement,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : ColoredBox(
                color: fallback ?? _Palette.of(context).panel,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      );
    }
    return Image.asset(
      value,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => replacement,
    );
  }
}

class _StatusPage extends StatelessWidget {
  const _StatusPage({required this.loading, required this.onRetry});
  final bool loading;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: loading
            ? Column(
                key: const ValueKey('restaurant-details-loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 15),
                  Text(l10n.loadingRestaurantDetails),
                ],
              )
            : _Empty(
                key: const ValueKey('restaurant-details-error'),
                icon: Icons.error_outline,
                title: l10n.restaurantDetailsUnavailable,
                action: l10n.retry,
                onAction: () async => onRetry(),
                actionKey: const ValueKey('restaurant-details-retry'),
              ),
      ),
    );
  }
}

class _ViewData {
  const _ViewData({
    required this.name,
    required this.description,
    required this.categories,
    required this.neighborhood,
    required this.address,
    required this.price,
    required this.photos,
    required this.userRating,
    required this.reviewCount,
    required this.hasStar,
    required this.thurayaRating,
    required this.thurayaEvaluations,
  });
  factory _ViewData.fromDetails(RestaurantDetailsDto value, String language) {
    return _ViewData(
      name: value.localizedName(language).trim(),
      description: value.localizedDescription(language).trim(),
      categories: value.categories
          .map((item) => item.name.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      neighborhood: value.localizedNeighborhood(language).trim(),
      address: value.address.trim(),
      price: value.priceLevelName?.trim().isNotEmpty == true
          ? value.priceLevelName!.trim()
          : List.filled(value.priceLevelId.clamp(0, 4), r'$').join(),
      photos: value.photos
          .map((item) => item.url.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      userRating:
          value.reviewSummary.userRatingAverage != null &&
              value.reviewSummary.reviewCount > 0
          ? value.reviewSummary.userRatingAverage!.clamp(0, 5)
          : null,
      reviewCount: value.reviewSummary.reviewCount,
      hasStar: value.hasThurayaStar,
      thurayaRating:
          value.reviewSummary.adminRatingAverage != null &&
              value.reviewSummary.adminRatingCount > 0
          ? value.reviewSummary.adminRatingAverage!.clamp(0, 5)
          : null,
      thurayaEvaluations: value.adminRatings
          .map(_ThurayaEvaluationData.fromDto)
          .toList(growable: false),
    );
  }
  factory _ViewData.fromRestaurant(Restaurant value) {
    final photos = <String>[value.coverImage, ...value.galleryImages]
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return _ViewData(
      name: value.name.trim(),
      description: value.description.trim(),
      categories: value.category.trim().isEmpty
          ? const []
          : [value.category.trim()],
      neighborhood: value.neighborhood.trim(),
      address: '',
      price: value.priceLevel.trim(),
      photos: photos,
      userRating: value.rating > 0 && value.reviewCount > 0
          ? value.rating
          : null,
      reviewCount: value.reviewCount,
      hasStar: value.hasThurayaStar,
      thurayaRating: value.thurayaRating != null && value.thurayaRating! > 0
          ? value.thurayaRating
          : null,
      thurayaEvaluations: const [],
    );
  }
  final String name;
  final String description;
  final List<String> categories;
  final String neighborhood;
  final String address;
  final String price;
  final List<String> photos;
  final double? userRating;
  final int reviewCount;
  final bool hasStar;
  final double? thurayaRating;
  final List<_ThurayaEvaluationData> thurayaEvaluations;
  bool get hasReviews => userRating != null && reviewCount > 0;
  bool get hasInfo => categories.isNotEmpty || price.isNotEmpty;
}

class _ThurayaEvaluationData {
  const _ThurayaEvaluationData({
    required this.id,
    required this.stars,
    required this.comment,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  factory _ThurayaEvaluationData.fromDto(AdminRestaurantRatingDto value) {
    final comment = value.comment?.trim();
    return _ThurayaEvaluationData(
      id: value.id,
      stars: value.stars.clamp(0, 5),
      comment: comment?.isNotEmpty == true ? comment : null,
      createdAtUtc: value.createdAtUtc,
      updatedAtUtc: value.updatedAtUtc,
    );
  }

  final int id;
  final double stars;
  final String? comment;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
}

class _Palette {
  const _Palette({
    required this.background,
    required this.surface,
    required this.panel,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.primary,
    required this.navy,
    required this.tint,
  });
  factory _Palette.of(BuildContext context) {
    return _Palette(
      background: AppColors.background,
      surface: AppColors.surface,
      panel: AppColors.panel,
      border: AppColors.panelBorder,
      primaryText: AppColors.textPrimary,
      secondaryText: AppColors.textSecondary,
      primary: AppColors.primary,
      navy: AppColors.primary,
      tint: AppColors.primary.withValues(alpha: .055),
    );
  }
  final Color background;
  final Color surface;
  final Color panel;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color primary;
  final Color navy;
  final Color tint;
}

String _rating(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
