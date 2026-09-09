import 'package:thuraya/core/network/api_client.dart';

class RestaurantReviewService {
  RestaurantReviewService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<void> createReview({
    required int restaurantId,
    required int stars,
    required String comment,
  }) async {
    await _apiClient.postResultData(
      '/api/restaurants/$restaurantId/user-reviews',
      body: <String, Object>{'stars': stars, 'comment': comment.trim()},
    );
  }

  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }
}
