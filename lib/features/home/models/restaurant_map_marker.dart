class RestaurantMapMarker {
  const RestaurantMapMarker({
    required this.id,
    required this.name,
    this.nameArabic,
    required this.latitude,
    required this.longitude,
    this.placeType = RestaurantMapPlaceType.restaurant,
    this.priceLevelId,
    this.priceLevelName,
    required this.hasThurayaStar,
    this.thurayaRatingAverage,
    this.thurayaReviewCount = 0,
    this.userRatingAverage,
    this.reviewCount = 0,
    this.mainPhotoUrl,
    this.primaryCategoryId,
    this.primaryCategoryName,
    this.neighborhoodId,
    this.neighborhoodNameAr,
    this.neighborhoodNameEn,
    this.address = '',
  });

  final int id;
  final String name;
  final String? nameArabic;
  final double latitude;
  final double longitude;
  final RestaurantMapPlaceType placeType;
  final int? priceLevelId;
  final String? priceLevelName;
  final bool hasThurayaStar;
  final double? thurayaRatingAverage;
  final int thurayaReviewCount;
  final double? userRatingAverage;
  final int reviewCount;
  final String? mainPhotoUrl;
  final int? primaryCategoryId;
  final String? primaryCategoryName;
  final int? neighborhoodId;
  final String? neighborhoodNameAr;
  final String? neighborhoodNameEn;
  final String address;

  factory RestaurantMapMarker.fromJson(Map<String, dynamic> json) {
    return RestaurantMapMarker(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
      nameArabic: json['nameArabic'] as String?,
      latitude: _requiredNumber(json, 'latitude').toDouble(),
      longitude: _requiredNumber(json, 'longitude').toDouble(),
      placeType: RestaurantMapPlaceType.fromJson(json['placeType']),
      priceLevelId: (json['priceLevelId'] as num?)?.toInt(),
      priceLevelName: json['priceLevelName'] as String?,
      hasThurayaStar: json['hasThurayaStar'] == true,
      thurayaRatingAverage: (json['thurayaRatingAverage'] as num?)?.toDouble(),
      thurayaReviewCount: (json['thurayaReviewCount'] as num?)?.toInt() ?? 0,
      userRatingAverage: (json['userRatingAverage'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
      primaryCategoryId: (json['primaryCategoryId'] as num?)?.toInt(),
      primaryCategoryName: json['primaryCategoryName'] as String?,
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      neighborhoodNameAr: json['neighborhoodNameAr'] as String?,
      neighborhoodNameEn: json['neighborhoodNameEn'] as String?,
      address: json['address'] as String? ?? '',
    );
  }

  String localizedName(String languageCode) {
    final arabicName = nameArabic?.trim();
    if (languageCode == 'ar' && arabicName != null && arabicName.isNotEmpty) {
      return arabicName;
    }
    return name.trim();
  }

  String localizedNeighborhood(String languageCode) {
    final primary = languageCode == 'ar'
        ? neighborhoodNameAr
        : neighborhoodNameEn;
    final fallback = languageCode == 'ar'
        ? neighborhoodNameEn
        : neighborhoodNameAr;
    final value = primary?.trim();
    if (value != null && value.isNotEmpty) return value;
    return fallback?.trim() ?? '';
  }

  static num _requiredNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value;
    }
    throw FormatException('Missing or invalid "$key" in map marker.');
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('Missing or invalid "$key" in map marker.');
  }
}

enum RestaurantMapPlaceType {
  restaurant,
  cafe;

  factory RestaurantMapPlaceType.fromJson(Object? value) {
    return switch (value) {
      String text when text.toLowerCase() == 'cafe' => cafe,
      _ => restaurant,
    };
  }
}
