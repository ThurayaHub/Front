import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_star_badge.dart';
import 'package:thuraya/features/account/models/profile_models.dart';
import 'package:thuraya/features/account/presentation/profile_controllers.dart';
import 'package:thuraya/features/account/presentation/widgets/profile_page_support.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_arabic_labels.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ProfileFavoritesPage extends StatefulWidget {
  const ProfileFavoritesPage({super.key, this.controller});

  final FavoritesController? controller;

  @override
  State<ProfileFavoritesPage> createState() => _ProfileFavoritesPageState();
}

class _ProfileFavoritesPageState extends State<ProfileFavoritesPage> {
  late final FavoritesController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FavoritesController();
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

  Future<void> _remove(ProfileFavoriteRestaurantDto restaurant) async {
    var removed = false;
    final authenticated = await runProtectedProfileAction(context, () async {
      removed = await _controller.removeFavorite(restaurant.restaurantId);
    });
    if (!mounted) return;
    if (!authenticated) {
      leavePrivateArea(context);
    } else if (!removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).favoriteRemoveError),
        ),
      );
    }
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
      key: const ValueKey('profile-favorites-page'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfilePageHeader(
              title: l10n.myFavorites,
              subtitle: l10n.favoritesSubtitle,
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
      ProfileLoadStatus.ready when _controller.favorites.isEmpty =>
        RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            key: const ValueKey('favorites-empty'),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height - 180,
                child: ProfileEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: l10n.favoritesEmptyTitle,
                  subtitle: l10n.favoritesEmptySubtitle,
                  onExplore: () => leavePrivateArea(context),
                ),
              ),
            ],
          ),
        ),
      ProfileLoadStatus.ready => RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView.separated(
          key: const ValueKey('favorites-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          itemCount: _controller.favorites.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final restaurant = _controller.favorites[index];
            return _FavoriteCard(
              restaurant: restaurant,
              removing: _controller.removingRestaurantIds.contains(
                restaurant.restaurantId,
              ),
              onRemove: () => _remove(restaurant),
              onOpen: () => Navigator.of(context).pushNamed(
                AppRouteNames.restaurantDetails,
                arguments: restaurant.restaurantId,
              ),
            );
          },
        ),
      ),
    };
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.restaurant,
    required this.removing,
    required this.onRemove,
    required this.onOpen,
  });

  final ProfileFavoriteRestaurantDto restaurant;
  final bool removing;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metadata = <String>[
      if (restaurant.arabicNeighborhood.isNotEmpty)
        restaurant.arabicNeighborhood,
      if (restaurant.priceLevelName?.trim().isNotEmpty == true)
        ChooseRestaurantArabicLabels.priceName(restaurant.priceLevelName!),
    ];
    final userRating = restaurant.userRatingAverage?.clamp(0, 5).toDouble();

    return Material(
      key: ValueKey('favorite-${restaurant.restaurantId}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.panelBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 120,
                child: ProfileRestaurantImage(source: restaurant.mainPhotoUrl),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.arabicName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.homeCardTitle,
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          metadata.join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardMetadata,
                        ),
                      ],
                      const Spacer(),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (restaurant.hasThurayaStar)
                            ThurayaStarBadge(
                              key: ValueKey(
                                'favorite-thuraya-star-${restaurant.restaurantId}',
                              ),
                              hasThurayaStar: true,
                              size: 18,
                              variant: ThurayaStarBadgeVariant.compact,
                            ),
                          if (userRating != null)
                            _Badge(
                              icon: Icons.star_rounded,
                              label: userRating.toStringAsFixed(1),
                              color: AppColors.secondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: IconButton(
                  key: ValueKey('favorite-remove-${restaurant.restaurantId}'),
                  tooltip: l10n.removeFavorite,
                  onPressed: removing ? null : onRemove,
                  icon: removing
                      ? const SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite_rounded),
                  color: AppColors.hot,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 3),
      Text(label, style: AppTextStyles.rating),
    ],
  );
}
