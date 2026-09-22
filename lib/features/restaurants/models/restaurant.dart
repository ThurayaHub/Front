import 'package:thuraya/features/restaurants/models/restaurant_review.dart';

enum RestaurantCardStatus { thurayaStar, rating }

class Restaurant {
  const Restaurant({
    required this.id,
    required this.cardImage,
    required this.coverImage,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.priceLevel,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.galleryImages,
    required this.reviews,
    required this.cardStatus,
    this.isHot = false,
    this.thurayaRating,
    this.travelMinutes,
  });

  final int id;
  final String cardImage;
  final String coverImage;
  final String name;
  final String category;
  final String neighborhood;
  final String priceLevel;
  final double rating;
  final int reviewCount;
  final String description;
  final List<String> galleryImages;
  final List<RestaurantReview> reviews;
  final RestaurantCardStatus cardStatus;
  final bool isHot;
  final double? thurayaRating;
  final int? travelMinutes;

  bool get hasThurayaStar => cardStatus == RestaurantCardStatus.thurayaStar;
  String get cardDetails => '$category • $neighborhood';
}
