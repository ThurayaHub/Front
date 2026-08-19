class RestaurantMapMarker {
  const RestaurantMapMarker({
    required this.id,
    required this.name,
    this.nameArabic,
    required this.latitude,
    required this.longitude,
    this.placeType = RestaurantMapPlaceType.restaurant,
    required this.priceLevelId,
    required this.hasThurayaStar,
    required this.userRatingAverage,
    required this.reviewCount,
    required this.mainPhotoUrl,
    required this.primaryCategoryId,
    required this.primaryCategoryName,
  });

  final int id;
  final String name;
  final String? nameArabic;
  final double latitude;
  final double longitude;
  final RestaurantMapPlaceType placeType;
  final int priceLevelId;
  final bool hasThurayaStar;
  final double? userRatingAverage;
  final int reviewCount;
  final String? mainPhotoUrl;
  final int? primaryCategoryId;
  final String? primaryCategoryName;

  factory RestaurantMapMarker.fromJson(Map<String, dynamic> json) {
    return RestaurantMapMarker(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
      nameArabic: json['nameArabic'] as String?,
      latitude: _requiredNumber(json, 'latitude').toDouble(),
      longitude: _requiredNumber(json, 'longitude').toDouble(),
      placeType: RestaurantMapPlaceType.fromJson(json['placeType']),
      priceLevelId: _requiredNumber(json, 'priceLevelId').toInt(),
      hasThurayaStar: json['hasThurayaStar'] == true,
      userRatingAverage: (json['userRatingAverage'] as num?)?.toDouble(),
      reviewCount: _requiredNumber(json, 'reviewCount').toInt(),
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
      primaryCategoryId: (json['primaryCategoryId'] as num?)?.toInt(),
      primaryCategoryName: json['primaryCategoryName'] as String?,
    );
  }

  String localizedName(String languageCode) {
    final arabicName = nameArabic?.trim();
    if (languageCode == 'ar' && arabicName != null && arabicName.isNotEmpty) {
      return arabicName;
    }
    return name.trim();
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
