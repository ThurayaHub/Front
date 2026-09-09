class RestaurantLookupItemDto {
  const RestaurantLookupItemDto({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;
  final String name;
  final String? description;

  factory RestaurantLookupItemDto.fromJson(Map<String, dynamic> json) {
    return RestaurantLookupItemDto(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
      description: json['description'] as String?,
    );
  }
}

class NeighborhoodLookupDto {
  const NeighborhoodLookupDto({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cityAr,
    required this.cityEn,
    required this.countryCode,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String cityAr;
  final String cityEn;
  final String countryCode;

  factory NeighborhoodLookupDto.fromJson(Map<String, dynamic> json) {
    return NeighborhoodLookupDto(
      id: _requiredNumber(json, 'id').toInt(),
      nameAr: _requiredString(json, 'nameAr'),
      nameEn: _requiredString(json, 'nameEn'),
      cityAr: _requiredString(json, 'cityAr'),
      cityEn: _requiredString(json, 'cityEn'),
      countryCode: _requiredString(json, 'countryCode'),
    );
  }

  String get arabicDisplayName {
    final neighborhood = nameAr.trim();
    final city = cityAr.trim();
    if (city.isEmpty || neighborhood.contains(city)) return neighborhood;
    return '$neighborhood، $city';
  }

  bool matches(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return true;
    return [
      nameAr,
      nameEn,
      cityAr,
      cityEn,
    ].map(_normalize).any((value) => value.contains(normalizedQuery));
  }
}

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  throw FormatException('Missing or invalid "$key" in lookup item.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Missing or invalid "$key" in lookup item.');
}

String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');
}
