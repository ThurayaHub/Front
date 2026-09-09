import 'package:flutter/foundation.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/account/models/profile_models.dart';
import 'package:thuraya/features/account/services/profile_service.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';

enum ProfileLoadStatus { idle, loading, ready, error }

typedef FavoriteRemover = Future<void> Function(int restaurantId);

class AccountSummaryController extends ChangeNotifier {
  AccountSummaryController({ProfileGateway? gateway}) {
    if (gateway == null) {
      final service = ProfileService();
      _gateway = service;
      _ownedService = service;
    } else {
      _gateway = gateway;
    }
  }

  late final ProfileGateway _gateway;
  ProfileService? _ownedService;
  bool _disposed = false;

  ProfileLoadStatus status = ProfileLoadStatus.idle;
  ProfileSummaryDto? summary;

  Future<void> load({bool refresh = false}) async {
    if (status == ProfileLoadStatus.loading ||
        (!refresh && status == ProfileLoadStatus.ready)) {
      return;
    }
    status = ProfileLoadStatus.loading;
    _notify();
    try {
      final value = await _gateway.getSummary();
      if (_disposed) return;
      summary = value;
      status = ProfileLoadStatus.ready;
    } on AuthenticationRequiredException {
      rethrow;
    } catch (_) {
      if (_disposed) return;
      status = ProfileLoadStatus.error;
    }
    _notify();
  }

  void clear() {
    summary = null;
    status = ProfileLoadStatus.idle;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ownedService?.close();
    super.dispose();
  }
}

class ProfileDetailsController extends ChangeNotifier {
  ProfileDetailsController({ProfileGateway? gateway}) {
    if (gateway == null) {
      final service = ProfileService();
      _gateway = service;
      _ownedService = service;
    } else {
      _gateway = gateway;
    }
  }

  late final ProfileGateway _gateway;
  ProfileService? _ownedService;
  bool _disposed = false;

  ProfileLoadStatus status = ProfileLoadStatus.idle;
  UserProfileDto? profile;

  Future<void> load({bool refresh = false}) async {
    if (status == ProfileLoadStatus.loading ||
        (!refresh && status == ProfileLoadStatus.ready)) {
      return;
    }
    status = ProfileLoadStatus.loading;
    _notify();
    try {
      final value = await _gateway.getDetails();
      if (_disposed) return;
      profile = value;
      status = ProfileLoadStatus.ready;
    } on AuthenticationRequiredException {
      rethrow;
    } catch (_) {
      if (_disposed) return;
      status = ProfileLoadStatus.error;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ownedService?.close();
    super.dispose();
  }
}

class FavoritesController extends ChangeNotifier {
  FavoritesController({
    ProfileGateway? gateway,
    FavoriteRemover? favoriteRemover,
  }) {
    if (gateway == null) {
      final service = ProfileService();
      _gateway = service;
      _ownedProfileService = service;
    } else {
      _gateway = gateway;
    }

    if (favoriteRemover == null) {
      final service = RestaurantDetailsService();
      _favoriteRemover = (id) async {
        await service.setFavorite(id, isFavorite: false);
      };
      _ownedDetailsService = service;
    } else {
      _favoriteRemover = favoriteRemover;
    }
  }

  late final ProfileGateway _gateway;
  late final FavoriteRemover _favoriteRemover;
  ProfileService? _ownedProfileService;
  RestaurantDetailsService? _ownedDetailsService;
  bool _disposed = false;

  ProfileLoadStatus status = ProfileLoadStatus.idle;
  List<ProfileFavoriteRestaurantDto> favorites = const [];
  final Set<int> removingRestaurantIds = {};

  Future<void> load({bool refresh = false}) async {
    if (status == ProfileLoadStatus.loading ||
        (!refresh && status == ProfileLoadStatus.ready)) {
      return;
    }
    status = ProfileLoadStatus.loading;
    _notify();
    try {
      final value = await _gateway.getFavorites();
      if (_disposed) return;
      favorites = value;
      status = ProfileLoadStatus.ready;
    } on AuthenticationRequiredException {
      rethrow;
    } catch (_) {
      if (_disposed) return;
      status = ProfileLoadStatus.error;
    }
    _notify();
  }

  Future<bool> removeFavorite(int restaurantId) async {
    if (removingRestaurantIds.contains(restaurantId)) return false;
    removingRestaurantIds.add(restaurantId);
    _notify();
    try {
      await _favoriteRemover(restaurantId);
      if (_disposed) return false;
      favorites = favorites
          .where((favorite) => favorite.restaurantId != restaurantId)
          .toList(growable: false);
      return true;
    } on AuthenticationRequiredException {
      rethrow;
    } catch (_) {
      return false;
    } finally {
      removingRestaurantIds.remove(restaurantId);
      _notify();
    }
  }

  void clear() {
    favorites = const [];
    removingRestaurantIds.clear();
    status = ProfileLoadStatus.idle;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ownedProfileService?.close();
    _ownedDetailsService?.close();
    super.dispose();
  }
}

class ReviewsController extends ChangeNotifier {
  ReviewsController({ProfileGateway? gateway}) {
    if (gateway == null) {
      final service = ProfileService();
      _gateway = service;
      _ownedService = service;
    } else {
      _gateway = gateway;
    }
  }

  late final ProfileGateway _gateway;
  ProfileService? _ownedService;
  bool _disposed = false;

  ProfileLoadStatus status = ProfileLoadStatus.idle;
  List<ProfileReviewDto> reviews = const [];

  Future<void> load({bool refresh = false}) async {
    if (status == ProfileLoadStatus.loading ||
        (!refresh && status == ProfileLoadStatus.ready)) {
      return;
    }
    status = ProfileLoadStatus.loading;
    _notify();
    try {
      final value = await _gateway.getReviews();
      if (_disposed) return;
      reviews = value;
      status = ProfileLoadStatus.ready;
    } on AuthenticationRequiredException {
      rethrow;
    } catch (_) {
      if (_disposed) return;
      status = ProfileLoadStatus.error;
    }
    _notify();
  }

  void clear() {
    reviews = const [];
    status = ProfileLoadStatus.idle;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ownedService?.close();
    super.dispose();
  }
}
