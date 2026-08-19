class RestaurantDetailsDto {
  const RestaurantDetailsDto({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.descriptionArabic,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.googleMapsUrl,
    required this.priceLevelId,
    required this.priceLevelName,
    required this.statusId,
    required this.statusName,
    required this.neighborhoodId,
    required this.neighborhoodNameAr,
    required this.neighborhoodNameEn,
    required this.trendRank,
    required this.hasThurayaStar,
    required this.categories,
    required this.photos,
    required this.badges,
    required this.reviewSummary,
    required this.thurayaReviewSummary,
    required this.isFavorite,
  });

  final int id;
  final String name;
  final String? nameArabic;
  final String? description;
  final String? descriptionArabic;
  final String address;
  final double latitude;
  final double longitude;
  final String googleMapsUrl;
  final int priceLevelId;
  final String? priceLevelName;
  final int statusId;
  final String? statusName;
  final int? neighborhoodId;
  final String? neighborhoodNameAr;
  final String? neighborhoodNameEn;
  final int? trendRank;
  final bool hasThurayaStar;
  final List<RestaurantCategoryDto> categories;
  final List<RestaurantPhotoDto> photos;
  final List<RestaurantBadgeDto> badges;
  final RestaurantReviewSummaryDto reviewSummary;
  final ThurayaReviewSummaryDto thurayaReviewSummary;
  final bool? isFavorite;

  factory RestaurantDetailsDto.fromJson(Map<String, dynamic> json) {
    return RestaurantDetailsDto(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
      nameArabic: json['nameArabic'] as String?,
      description: json['description'] as String?,
      descriptionArabic: json['descriptionArabic'] as String?,
      address: _requiredString(json, 'address'),
      latitude: _requiredNumber(json, 'latitude').toDouble(),
      longitude: _requiredNumber(json, 'longitude').toDouble(),
      googleMapsUrl: _requiredString(json, 'googleMapsUrl'),
      priceLevelId: _requiredNumber(json, 'priceLevelId').toInt(),
      priceLevelName: json['priceLevelName'] as String?,
      statusId: _requiredNumber(json, 'statusId').toInt(),
      statusName: json['statusName'] as String?,
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      neighborhoodNameAr: json['neighborhoodNameAr'] as String?,
      neighborhoodNameEn: json['neighborhoodNameEn'] as String?,
      trendRank: (json['trendRank'] as num?)?.toInt(),
      hasThurayaStar: json['hasThurayaStar'] == true,
      categories: _mapList(json['categories'], RestaurantCategoryDto.fromJson),
      photos: _mapList(json['photos'], RestaurantPhotoDto.fromJson),
      badges: _mapList(json['badges'], RestaurantBadgeDto.fromJson),
      reviewSummary: RestaurantReviewSummaryDto.fromJson(
        _requiredMap(json, 'reviewSummary'),
      ),
      thurayaReviewSummary: ThurayaReviewSummaryDto.fromJson(
        _requiredMap(json, 'thurayaReviewSummary'),
      ),
      isFavorite: json['isFavorite'] as bool?,
    );
  }

  String localizedName(String languageCode) {
    return languageCode == 'ar' ? _valueOrFallback(nameArabic, name) : name;
  }

  String localizedDescription(String languageCode) {
    return languageCode == 'ar'
        ? _valueOrFallback(descriptionArabic, description ?? '')
        : (description ?? '');
  }

  String localizedNeighborhood(String languageCode) {
    if (languageCode == 'ar') {
      return _valueOrFallback(neighborhoodNameAr, neighborhoodNameEn ?? '');
    }
    return _valueOrFallback(neighborhoodNameEn, neighborhoodNameAr ?? '');
  }

  static String _valueOrFallback(String? value, String fallback) {
    final trimmedValue = value?.trim();
    return trimmedValue == null || trimmedValue.isEmpty
        ? fallback
        : trimmedValue;
  }
}

class RestaurantCategoryDto {
  const RestaurantCategoryDto({required this.id, required this.name});

  final int id;
  final String name;

  factory RestaurantCategoryDto.fromJson(Map<String, dynamic> json) {
    return RestaurantCategoryDto(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
    );
  }
}

class RestaurantPhotoDto {
  const RestaurantPhotoDto({
    required this.id,
    required this.url,
    required this.caption,
    required this.displayOrder,
    required this.isCoverPhoto,
  });

  final int id;
  final String url;
  final String? caption;
  final int displayOrder;
  final bool isCoverPhoto;

  factory RestaurantPhotoDto.fromJson(Map<String, dynamic> json) {
    return RestaurantPhotoDto(
      id: _requiredNumber(json, 'id').toInt(),
      url: _requiredString(json, 'url'),
      caption: json['caption'] as String?,
      displayOrder: _requiredNumber(json, 'displayOrder').toInt(),
      isCoverPhoto: json['isCoverPhoto'] == true,
    );
  }
}

class RestaurantBadgeDto {
  const RestaurantBadgeDto({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.reason,
  });

  final int id;
  final String name;
  final String? description;
  final String? type;
  final String? reason;

  factory RestaurantBadgeDto.fromJson(Map<String, dynamic> json) {
    return RestaurantBadgeDto(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
      description: json['description'] as String?,
      type: json['type'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class RestaurantReviewSummaryDto {
  const RestaurantReviewSummaryDto({
    required this.userRatingAverage,
    required this.reviewCount,
    required this.adminRatingAverage,
    required this.adminRatingCount,
  });

  final double? userRatingAverage;
  final int reviewCount;
  final double? adminRatingAverage;
  final int adminRatingCount;

  factory RestaurantReviewSummaryDto.fromJson(Map<String, dynamic> json) {
    return RestaurantReviewSummaryDto(
      userRatingAverage: (json['userRatingAverage'] as num?)?.toDouble(),
      reviewCount: _requiredNumber(json, 'reviewCount').toInt(),
      adminRatingAverage: (json['adminRatingAverage'] as num?)?.toDouble(),
      adminRatingCount: _requiredNumber(json, 'adminRatingCount').toInt(),
    );
  }
}

class ThurayaReviewSummaryDto {
  const ThurayaReviewSummaryDto({
    required this.averageRating,
    required this.totalReviews,
    required this.latestReview,
    required this.history,
  });

  final double? averageRating;
  final int totalReviews;
  final ThurayaReviewDto? latestReview;
  final List<ThurayaReviewDto> history;

  factory ThurayaReviewSummaryDto.fromJson(Map<String, dynamic> json) {
    final latestReview = json['latestReview'];
    return ThurayaReviewSummaryDto(
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: _requiredNumber(json, 'totalReviews').toInt(),
      latestReview: latestReview is Map
          ? ThurayaReviewDto.fromJson(Map<String, dynamic>.from(latestReview))
          : null,
      history: _mapList(json['history'], ThurayaReviewDto.fromJson),
    );
  }
}

class ThurayaReviewDto {
  const ThurayaReviewDto({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.createdByAdminUserId,
    required this.hasThurayaStar,
  });

  final int id;
  final double rating;
  final String comment;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final int? createdByAdminUserId;
  final bool? hasThurayaStar;

  factory ThurayaReviewDto.fromJson(Map<String, dynamic> json) {
    return ThurayaReviewDto(
      id: _requiredNumber(json, 'id').toInt(),
      rating: _requiredNumber(json, 'rating').toDouble(),
      comment: _requiredString(json, 'comment'),
      createdAtUtc: DateTime.parse(_requiredString(json, 'createdAtUtc')),
      updatedAtUtc: json['updatedAtUtc'] is String
          ? DateTime.parse(json['updatedAtUtc'] as String)
          : null,
      createdByAdminUserId: (json['createdByAdminUserId'] as num?)?.toInt(),
      hasThurayaStar: json['hasThurayaStar'] as bool?,
    );
  }
}

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" in restaurant details.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('Missing or invalid "$key" in restaurant details.');
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('Missing or invalid "$key" in restaurant details.');
}

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) {
    throw const FormatException('Invalid list in restaurant details.');
  }
  return value
      .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
      .toList(growable: false);
}
