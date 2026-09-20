import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/restaurants/models/restaurant_review.dart';

class RestaurantReviewService {
  RestaurantReviewService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<List<RestaurantReview>> getReviews(int restaurantId) async {
    final data = await _apiClient.getResultData(
      '/api/restaurants/$restaurantId/user-reviews',
    );
    if (data is! List) {
      throw const ApiException('The restaurant reviews response is invalid.');
    }

    try {
      return data
          .map(
            (review) => RestaurantReview.fromJson(
              Map<String, dynamic>.from(review as Map),
            ),
          )
          .toList(growable: false);
    } on Object catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException('The restaurant reviews response is invalid.');
    }
  }

  Future<void> createReview({
    required int restaurantId,
    required int stars,
    required String comment,
  }) async {
    final normalizedComment = comment.trim();
    await _apiClient.postResultData(
      '/api/restaurants/$restaurantId/user-reviews',
      body: <String, Object?>{
        'stars': stars,
        'comment': normalizedComment.isEmpty ? null : normalizedComment,
      },
    );
  }

  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }
}
