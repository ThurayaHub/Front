import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/account/models/profile_models.dart';

abstract interface class ProfileGateway {
  Future<ProfileSummaryDto> getSummary();

  Future<UserProfileDto> getDetails();

  Future<List<ProfileFavoriteRestaurantDto>> getFavorites();

  Future<List<ProfileReviewDto>> getReviews();
}

class ProfileService implements ProfileGateway {
  ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  @override
  Future<ProfileSummaryDto> getSummary() async {
    final data = await _apiClient.getResultData('/api/profile');
    return ProfileSummaryDto.fromJson(_requiredMap(data));
  }

  @override
  Future<UserProfileDto> getDetails() async {
    final data = await _apiClient.getResultData('/api/profile/details');
    return UserProfileDto.fromJson(_requiredMap(data));
  }

  @override
  Future<List<ProfileFavoriteRestaurantDto>> getFavorites() async {
    final data = await _apiClient.getResultData('/api/profile/favorites');
    return _requiredList(data, ProfileFavoriteRestaurantDto.fromJson);
  }

  @override
  Future<List<ProfileReviewDto>> getReviews() async {
    final data = await _apiClient.getResultData('/api/profile/reviews');
    return _requiredList(data, ProfileReviewDto.fromJson);
  }

  void close() {
    if (_ownsApiClient) _apiClient.close();
  }
}

Map<String, dynamic> _requiredMap(Object? data) {
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const ApiException('The profile response is invalid.');
}

List<T> _requiredList<T>(
  Object? data,
  T Function(Map<String, dynamic>) parser,
) {
  if (data is! List) {
    throw const ApiException('The profile list response is invalid.');
  }
  return data
      .map((item) => parser(Map<String, dynamic>.from(item as Map)))
      .toList(growable: false);
}
