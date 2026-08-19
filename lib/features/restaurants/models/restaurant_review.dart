class RestaurantReview {
  const RestaurantReview({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.reviewerName,
    required this.stars,
    required this.comment,
    required this.isPublished,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final int id;
  final int restaurantId;
  final int userId;
  final String reviewerName;
  final double stars;
  final String? comment;
  final bool isPublished;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  double get ratingOutOfFive => (stars / 2).clamp(0, 5).toDouble();
}
