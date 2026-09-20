class RestaurantReview {
  const RestaurantReview({
    required this.id,
    required this.restaurantId,
    this.userId,
    required this.reviewerName,
    required this.stars,
    required this.comment,
    this.isPublished = true,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory RestaurantReview.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final restaurantId = json['restaurantId'];
    final reviewerName = json['reviewerName'];
    final stars = json['stars'];
    final createdAtUtc = json['createdAtUtc'];
    if (id is! num ||
        restaurantId is! num ||
        reviewerName is! String ||
        stars is! num ||
        createdAtUtc is! String) {
      throw const FormatException('Invalid restaurant review response.');
    }

    return RestaurantReview(
      id: id.toInt(),
      restaurantId: restaurantId.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      reviewerName: reviewerName,
      stars: stars.toInt(),
      comment: json['comment'] as String?,
      isPublished: json['isPublished'] as bool? ?? true,
      createdAtUtc: DateTime.parse(createdAtUtc),
      updatedAtUtc: json['updatedAtUtc'] is String
          ? DateTime.parse(json['updatedAtUtc'] as String)
          : null,
    );
  }

  final int id;
  final int restaurantId;
  final int? userId;
  final String reviewerName;
  final int stars;
  final String? comment;
  final bool isPublished;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  double get ratingOutOfFive => stars.clamp(0, 5).toDouble();
}
