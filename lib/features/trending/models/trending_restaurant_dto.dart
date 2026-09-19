class TrendingRestaurantDto {
  const TrendingRestaurantDto({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.priceLevelId,
    required this.neighborhoodId,
    required this.trendRank,
    required this.hasThurayaStar,
    required this.coverPhotoUrl,
    required this.categoryIds,
  });

  final int id;
  final String name;
  final String? description;
  final String address;
  final double latitude;
  final double longitude;
  final int priceLevelId;
  final int? neighborhoodId;
  final int trendRank;
  final bool hasThurayaStar;
  final String? coverPhotoUrl;
  final List<int> categoryIds;

  factory TrendingRestaurantDto.fromJson(Map<String, dynamic> json) {
    return TrendingRestaurantDto(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
      description: json['description'] as String?,
      address: _requiredString(json, 'address'),
      latitude: _requiredNumber(json, 'latitude').toDouble(),
      longitude: _requiredNumber(json, 'longitude').toDouble(),
      priceLevelId: _requiredNumber(json, 'priceLevelId').toInt(),
      neighborhoodId: (json['neighborhoodId'] as num?)?.toInt(),
      trendRank: _requiredNumber(json, 'trendRank').toInt(),
      hasThurayaStar: json['hasThurayaStar'] == true,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      categoryIds: _requiredIntList(json, 'categoryIds'),
    );
  }
}

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  throw FormatException('Missing or invalid "$key" in trending restaurant.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Missing or invalid "$key" in trending restaurant.');
}

List<int> _requiredIntList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Missing or invalid "$key" in trending restaurant.');
  }
  return value
      .map((item) {
        if (item is num) return item.toInt();
        throw FormatException('Invalid item in trending restaurant "$key".');
      })
      .toList(growable: false);
}
