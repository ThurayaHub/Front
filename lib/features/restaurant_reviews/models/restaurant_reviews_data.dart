import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/features/restaurants/models/restaurant_review.dart';

class RestaurantReviewsData {
  const RestaurantReviewsData({
    required this.restaurantName,
    required this.rating,
    required this.reviewCount,
    required this.reviews,
    required this.hasReviewList,
  });

  factory RestaurantReviewsData.fromRestaurant(Restaurant restaurant) {
    return RestaurantReviewsData(
      restaurantName: restaurant.name,
      rating: restaurant.rating,
      reviewCount: restaurant.reviewCount,
      reviews: restaurant.reviews,
      hasReviewList: true,
    );
  }

  final String restaurantName;
  final double rating;
  final int reviewCount;
  final List<RestaurantReview> reviews;

  /// False when the API supplies only the aggregate rating and count.
  final bool hasReviewList;
}
