import 'package:flutter/foundation.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/account/models/profile_models.dart';
import 'package:thuraya/features/account/services/profile_service.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';

enum ProfileLoadStatus { idle, loading, ready, error }

enum EmailVerificationRequestStatus { idle, sending, sent, error }

enum EmailVerificationRequestFailure { none, rateLimited, unavailable }

enum ProfileMutationStatus { idle, saving, success, error }

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
  EmailVerificationRequestStatus verificationRequestStatus =
      EmailVerificationRequestStatus.idle;
  EmailVerificationRequestFailure verificationRequestFailure =
      EmailVerificationRequestFailure.none;
  ProfileMutationStatus mutationStatus = ProfileMutationStatus.idle;
  ApiException? mutationError;

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
      if (value.isEmailVerified) {
        verificationRequestStatus = EmailVerificationRequestStatus.idle;
      }
    } on AuthenticationRequiredException {
      rethrow;
    } catch (_) {
      if (_disposed) return;
      status = ProfileLoadStatus.error;
    }
    _notify();
  }

  Future<bool> requestEmailVerification() async {
    if (verificationRequestStatus == EmailVerificationRequestStatus.sending) {
      return false;
    }
    verificationRequestStatus = EmailVerificationRequestStatus.sending;
    verificationRequestFailure = EmailVerificationRequestFailure.none;
    _notify();
    try {
      final result = await _gateway.requestEmailVerification();
      if (_disposed) return false;
      final current = profile;
      if (current != null) {
        profile = UserProfileDto(
          userId: current.userId,
          name: current.name,
          phoneNumber: current.phoneNumber,
          isPhoneVerified: current.isPhoneVerified,
          email: current.email,
          isEmailVerified: result.isEmailVerified,
          createdAtUtc: current.createdAtUtc,
          emailVerifiedAtUtc: result.emailVerifiedAtUtc,
          emailVerificationResendAvailableAtUtc: result.resendAvailableAtUtc,
          pendingEmailChange: current.pendingEmailChange,
          pendingPhoneChange: current.pendingPhoneChange,
        );
      }
      verificationRequestStatus = EmailVerificationRequestStatus.sent;
      _notify();
      return true;
    } on AuthenticationRequiredException {
      rethrow;
    } on ApiException catch (error) {
      if (_disposed) return false;
      verificationRequestStatus = EmailVerificationRequestStatus.error;
      verificationRequestFailure = error.statusCode == 429
          ? EmailVerificationRequestFailure.rateLimited
          : EmailVerificationRequestFailure.unavailable;
      _notify();
      return false;
    } catch (_) {
      if (_disposed) return false;
      verificationRequestStatus = EmailVerificationRequestStatus.error;
      verificationRequestFailure = EmailVerificationRequestFailure.unavailable;
      _notify();
      return false;
    }
  }

  Future<bool> updateName(String name) {
    return _mutate(() => _gateway.updateName(name));
  }

  Future<bool> requestEmailChange(String email) {
    return _mutateAndReload(() => _gateway.requestEmailChange(email));
  }

  Future<bool> cancelEmailChange() {
    return _mutate(_gateway.cancelEmailChange);
  }

  Future<bool> requestPhoneChange(String phoneNumber) {
    return _mutateAndReload(() => _gateway.requestPhoneChange(phoneNumber));
  }

  Future<bool> verifyPhoneChange(String otp) {
    return _mutate(() => _gateway.verifyPhoneChange(otp));
  }

  Future<bool> cancelPhoneChange() {
    return _mutate(_gateway.cancelPhoneChange);
  }

  Future<bool> _mutate(Future<UserProfileDto> Function() action) async {
    if (mutationStatus == ProfileMutationStatus.saving) return false;
    mutationStatus = ProfileMutationStatus.saving;
    mutationError = null;
    _notify();
    try {
      final value = await action();
      if (_disposed) return false;
      profile = value;
      mutationStatus = ProfileMutationStatus.success;
      _notify();
      return true;
    } on AuthenticationRequiredException {
      rethrow;
    } on ApiException catch (error) {
      if (_disposed) return false;
      mutationError = error;
      mutationStatus = ProfileMutationStatus.error;
    } catch (_) {
      if (_disposed) return false;
      mutationError = const ApiException('The profile update failed.');
      mutationStatus = ProfileMutationStatus.error;
    }
    _notify();
    return false;
  }

  Future<bool> _mutateAndReload(Future<Object?> Function() action) async {
    if (mutationStatus == ProfileMutationStatus.saving) return false;
    mutationStatus = ProfileMutationStatus.saving;
    mutationError = null;
    _notify();
    try {
      await action();
      final value = await _gateway.getDetails();
      if (_disposed) return false;
      profile = value;
      mutationStatus = ProfileMutationStatus.success;
      _notify();
      return true;
    } on AuthenticationRequiredException {
      rethrow;
    } on ApiException catch (error) {
      if (_disposed) return false;
      mutationError = error;
      mutationStatus = ProfileMutationStatus.error;
    } catch (_) {
      if (_disposed) return false;
      mutationError = const ApiException('The profile update failed.');
      mutationStatus = ProfileMutationStatus.error;
    }
    _notify();
    return false;
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
