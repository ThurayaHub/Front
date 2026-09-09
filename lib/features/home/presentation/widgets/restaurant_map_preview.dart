import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/authentication_guard.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_map_preview_card.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantMapPreview extends StatefulWidget {
  const RestaurantMapPreview({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.onClose,
    this.detailsService,
  });

  final RestaurantMapMarker restaurant;
  final ValueChanged<RestaurantDetailsDto> onTap;
  final VoidCallback onClose;
  final RestaurantDetailsService? detailsService;

  @override
  State<RestaurantMapPreview> createState() => _RestaurantMapPreviewState();
}

class _RestaurantMapPreviewState extends State<RestaurantMapPreview> {
  late final RestaurantDetailsService _detailsService;
  late final bool _ownsDetailsService;
  RestaurantDetailsDto? _details;
  bool? _isFavorite;
  int? _favoriteUserId;
  int _requestGeneration = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _ownsDetailsService = widget.detailsService == null;
    _detailsService = widget.detailsService ?? RestaurantDetailsService();
    unawaited(_loadDetails());
  }

  @override
  void didUpdateWidget(covariant RestaurantMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      _details = null;
      _isFavorite = null;
      _favoriteUserId = null;
      _isLoading = true;
      _hasError = false;
      unawaited(_loadDetails());
    }
  }

  Future<void> _loadDetails() async {
    final requestGeneration = ++_requestGeneration;
    try {
      final details = await _detailsService.getDetails(widget.restaurant.id);
      if (!mounted || requestGeneration != _requestGeneration) {
        return;
      }
      final currentUserId = AuthScope.read(context).user?.id;
      setState(() {
        _details = details;
        _isFavorite = details.isFavorite;
        _favoriteUserId = details.isFavorite == null ? null : currentUserId;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted || requestGeneration != _requestGeneration) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _retry() {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    unawaited(_loadDetails());
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
    if (_isUpdatingFavorite || _details == null) {
      return;
    }

    setState(() => _isUpdatingFavorite = true);
    try {
      final currentUserId = AuthScope.read(context).user?.id;
      if (currentUserId == null) {
        throw const AuthenticationRequiredException(
          'Authentication is required.',
        );
      }

      if (_favoriteUserId != currentUserId || _isFavorite == null) {
        final refreshedDetails = await _detailsService.getDetails(
          widget.restaurant.id,
        );
        if (!mounted) {
          return;
        }
        _details = refreshedDetails;
        _isFavorite = refreshedDetails.isFavorite;
        _favoriteUserId = refreshedDetails.isFavorite == null
            ? null
            : currentUserId;
      }

      final result = await _detailsService.setFavorite(
        widget.restaurant.id,
        isFavorite: !(_isFavorite ?? false),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavorite = result.isFavorite;
        _favoriteUserId = currentUserId;
      });
    } on AuthenticationRequiredException {
      _favoriteUserId = null;
      _isFavorite = null;
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFavorite = false);
      }
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _requestGeneration++;
    if (_ownsDetailsService) {
      _detailsService.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    if (details != null) {
      return RestaurantMapPreviewCard(
        restaurant: details,
        isFavorite: _isFavorite,
        isUpdatingFavorite: _isUpdatingFavorite,
        onTap: () => widget.onTap(details),
        onFavoriteTap: _handleFavoriteTap,
        onClose: widget.onClose,
      );
    }

    return _RestaurantPreviewStatusCard(
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _retry,
      onClose: widget.onClose,
    );
  }
}

class _RestaurantPreviewStatusCard extends StatelessWidget {
  const _RestaurantPreviewStatusCard({
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.onClose,
  });

  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: RestaurantMapPreviewCard.maxWidth,
        minHeight: 116,
      ),
      child: Material(
        key: ValueKey(
          hasError ? 'restaurant-preview-error' : 'restaurant-preview-loading',
        ),
        color: AppColors.surface,
        elevation: 12,
        shadowColor: AppColors.shadow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: isLoading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            localizations.loadingRestaurantDetails,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.cardMetadata,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localizations.restaurantDetailsUnavailable,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.homeCategory,
                          ),
                          if (hasError) ...[
                            const SizedBox(height: AppSpacing.xs),
                            TextButton(
                              key: const ValueKey('restaurant-preview-retry'),
                              onPressed: onRetry,
                              child: Text(localizations.retry),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.xxs,
              end: AppSpacing.xxs,
              child: IconButton(
                key: const ValueKey('restaurant-preview-close'),
                tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
