final Map<String, dynamic> successfulRestaurantDetailsResult = {
  'success': true,
  'message': 'Restaurant details retrieved successfully.',
  'data': restaurantDetailsData,
  'errors': <String>[],
  'statusCode': 200,
};

final Map<String, dynamic> restaurantDetailsData = {
  'id': 42,
  'name': 'Riyadh Table',
  'nameArabic': 'مائدة الرياض',
  'description': 'A modern Saudi restaurant.',
  'descriptionArabic': 'مطعم سعودي عصري.',
  'address': 'Riyadh',
  'latitude': 24.7136,
  'longitude': 46.6753,
  'googleMapsUrl': 'https://www.google.com/maps/search/?api=1&query=24,46',
  'priceLevelId': 3,
  'priceLevelName': r'$$$',
  'statusId': 1,
  'statusName': 'Published',
  'neighborhoodId': 5,
  'neighborhoodNameAr': 'العليا',
  'neighborhoodNameEn': 'Al Olaya',
  'trendRank': 2,
  'hasThurayaStar': true,
  'categories': [
    {'id': 9, 'name': 'Saudi'},
  ],
  'photos': [
    {
      'id': 11,
      'url': 'https://example.com/photo.jpg',
      'caption': 'Dining room',
      'displayOrder': 1,
      'isCoverPhoto': true,
    },
  ],
  'badges': [
    {
      'id': 3,
      'name': 'Thuraya Star',
      'description': 'Excellent',
      'type': 'Award',
      'reason': 'Quality',
    },
  ],
  'reviewSummary': {
    'userRatingAverage': 9.0,
    'reviewCount': 8,
    'adminRatingAverage': 8.5,
    'adminRatingCount': 2,
  },
  'thurayaReviewSummary': {
    'averageRating': 9.5,
    'totalReviews': 1,
    'latestReview': thurayaReviewData,
    'history': [thurayaReviewData],
  },
  'isFavorite': null,
};

final Map<String, dynamic> thurayaReviewData = {
  'id': 71,
  'rating': 9.5,
  'comment': 'Excellent.',
  'createdAtUtc': '2026-08-01T12:00:00Z',
  'updatedAtUtc': null,
  'createdByAdminUserId': 4,
  'hasThurayaStar': null,
};
