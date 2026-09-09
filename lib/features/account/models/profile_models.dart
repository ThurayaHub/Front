class ProfileSummaryDto {
  const ProfileSummaryDto({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.isEmailVerified,
    required this.reviewCount,
  });

  final int userId;
  final String name;
  final String? phoneNumber;
  final String? email;
  final bool isEmailVerified;
  final int reviewCount;

  factory ProfileSummaryDto.fromJson(Map<String, dynamic> json) {
    return ProfileSummaryDto(
      userId: _requiredInt(json, 'userId'),
      name: _requiredString(json, 'name'),
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      isEmailVerified: json['isEmailVerified'] == true,
      reviewCount: _requiredInt(json, 'reviewCount'),
    );
  }
}

class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.isEmailVerified,
    required this.createdAtUtc,
    required this.emailVerifiedAtUtc,
  });

  final int userId;
  final String name;
  final String? phoneNumber;
  final String? email;
  final bool isEmailVerified;
  final DateTime createdAtUtc;
  final DateTime? emailVerifiedAtUtc;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: _requiredInt(json, 'userId'),
      name: _requiredString(json, 'name'),
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      isEmailVerified: json['isEmailVerified'] == true,
      createdAtUtc: _requiredDate(json, 'createdAtUtc'),
      emailVerifiedAtUtc: _optionalDate(json['emailVerifiedAtUtc']),
    );
  }
}

class ProfileFavoriteRestaurantDto {
  const ProfileFavoriteRestaurantDto({
    required this.restaurantId,
    required this.nameEn,
    required this.nameAr,
    required this.mainPhotoUrl,
    required this.userRatingAverage,
    required this.priceLevelId,
    required this.priceLevelName,
    required this.neighborhoodId,
    required this.neighborhoodNameAr,
    required this.neighborhoodNameEn,
    required this.hasThurayaStar,
  });

  final int restaurantId;
  final String nameEn;
  final String? nameAr;
  final String? mainPhotoUrl;
  final double? userRatingAverage;
  final int priceLevelId;
  final String? priceLevelName;
  final int? neighborhoodId;
  final String? neighborhoodNameAr;
  final String? neighborhoodNameEn;
  final bool hasThurayaStar;

  factory ProfileFavoriteRestaurantDto.fromJson(Map<String, dynamic> json) {
    return ProfileFavoriteRestaurantDto(
      restaurantId: _requiredInt(json, 'restaurantId'),
      nameEn: _requiredString(json, 'nameEn'),
      nameAr: json['nameAr'] as String?,
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
      userRatingAverage: (json['userRatingAverage'] as num?)?.toDouble(),
      priceLevelId: _requiredInt(json, 'priceLevelId'),
      priceLevelName: json['priceLevelName'] as String?,
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      neighborhoodNameAr: json['neighborhoodNameAr'] as String?,
      neighborhoodNameEn: json['neighborhoodNameEn'] as String?,
      hasThurayaStar: json['hasThurayaStar'] == true,
    );
  }

  String get arabicName => _valueOrFallback(nameAr, nameEn);

  String get arabicNeighborhood =>
      _valueOrFallback(neighborhoodNameAr, neighborhoodNameEn ?? '');
}

class ProfileReviewDto {
  const ProfileReviewDto({
    required this.reviewId,
    required this.restaurantId,
    required this.restaurantNameEn,
    required this.restaurantNameAr,
    required this.restaurantMainPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final int reviewId;
  final int restaurantId;
  final String restaurantNameEn;
  final String? restaurantNameAr;
  final String? restaurantMainPhotoUrl;
  final int rating;
  final String? comment;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory ProfileReviewDto.fromJson(Map<String, dynamic> json) {
    return ProfileReviewDto(
      reviewId: _requiredInt(json, 'reviewId'),
      restaurantId: _requiredInt(json, 'restaurantId'),
      restaurantNameEn: _requiredString(json, 'restaurantNameEn'),
      restaurantNameAr: json['restaurantNameAr'] as String?,
      restaurantMainPhotoUrl: json['restaurantMainPhotoUrl'] as String?,
      rating: _requiredInt(json, 'rating'),
      comment: json['comment'] as String?,
      createdAtUtc: _requiredDate(json, 'createdAtUtc'),
      updatedAtUtc: _optionalDate(json['updatedAtUtc']),
    );
  }

  String get arabicRestaurantName =>
      _valueOrFallback(restaurantNameAr, restaurantNameEn);
}

int _requiredInt(Map<String, dynamic> json, String key) {
  return _requiredNumber(json, key).toInt();
}

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  throw FormatException('Missing or invalid "$key" in profile data.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Missing or invalid "$key" in profile data.');
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _optionalDate(json[key]);
  if (value != null) return value;
  throw FormatException('Missing or invalid "$key" in profile data.');
}

DateTime? _optionalDate(Object? value) {
  return value is String ? DateTime.tryParse(value)?.toUtc() : null;
}

String _valueOrFallback(String? value, String fallback) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback.trim() : trimmed;
}
