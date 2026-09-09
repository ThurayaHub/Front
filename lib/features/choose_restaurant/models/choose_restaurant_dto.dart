import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';

class ChooseRestaurantRequest {
  const ChooseRestaurantRequest({
    required this.priceLevelIds,
    required this.categoryIds,
    required this.neighborhoodIds,
  });

  final List<int> priceLevelIds;
  final List<int> categoryIds;
  final List<int> neighborhoodIds;

  Map<String, dynamic> toJson() => {
    'priceLevelIds': priceLevelIds,
    'categoryIds': categoryIds,
    'neighborhoodIds': neighborhoodIds,
  };
}

class ChooseRestaurantResponseDto {
  const ChooseRestaurantResponseDto({
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
    required this.neighborhoodId,
    required this.neighborhoodNameAr,
    required this.neighborhoodNameEn,
    required this.userRatingAverage,
    required this.reviewCount,
    required this.mainPhotoUrl,
    required this.hasThurayaStar,
    required this.categories,
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
  final int? neighborhoodId;
  final String? neighborhoodNameAr;
  final String? neighborhoodNameEn;
  final double? userRatingAverage;
  final int reviewCount;
  final String? mainPhotoUrl;
  final bool hasThurayaStar;
  final List<RestaurantCategoryDto> categories;

  factory ChooseRestaurantResponseDto.fromJson(Map<String, dynamic> json) {
    return ChooseRestaurantResponseDto(
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
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      neighborhoodNameAr: json['neighborhoodNameAr'] as String?,
      neighborhoodNameEn: json['neighborhoodNameEn'] as String?,
      userRatingAverage: (json['userRatingAverage'] as num?)?.toDouble(),
      reviewCount: _requiredNumber(json, 'reviewCount').toInt(),
      mainPhotoUrl: json['mainPhotoUrl'] as String?,
      hasThurayaStar: json['hasThurayaStar'] == true,
      categories: _mapCategories(json['categories']),
    );
  }

  String localizedName(String languageCode) {
    return languageCode == 'ar'
        ? _valueOrFallback(nameArabic, name)
        : _valueOrFallback(name, nameArabic ?? '');
  }

  String localizedDescription(String languageCode) {
    return languageCode == 'ar'
        ? _valueOrFallback(descriptionArabic, description ?? '')
        : _valueOrFallback(description, descriptionArabic ?? '');
  }

  String localizedNeighborhood(String languageCode) {
    return languageCode == 'ar'
        ? _valueOrFallback(neighborhoodNameAr, neighborhoodNameEn ?? '')
        : _valueOrFallback(neighborhoodNameEn, neighborhoodNameAr ?? '');
  }
}

class ChooseRestaurantRecommendation {
  const ChooseRestaurantRecommendation({required this.selection, this.details});

  final ChooseRestaurantResponseDto selection;
  final RestaurantDetailsDto? details;
}

List<RestaurantCategoryDto> _mapCategories(Object? value) {
  if (value is! List) {
    throw const FormatException('Invalid categories in recommendation.');
  }
  return value
      .map(
        (item) => RestaurantCategoryDto.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList(growable: false);
}

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  throw FormatException('Missing or invalid "$key" in recommendation.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Missing or invalid "$key" in recommendation.');
}

String _valueOrFallback(String? value, String fallback) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback.trim() : trimmed;
}
