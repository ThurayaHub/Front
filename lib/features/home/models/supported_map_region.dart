class SupportedMapBounds {
  const SupportedMapBounds({
    required this.southwestLatitude,
    required this.southwestLongitude,
    required this.northeastLatitude,
    required this.northeastLongitude,
  });

  final double southwestLatitude;
  final double southwestLongitude;
  final double northeastLatitude;
  final double northeastLongitude;

  double get latitudeSpan => northeastLatitude - southwestLatitude;

  double get longitudeSpan => northeastLongitude - southwestLongitude;

  bool contains({required double latitude, required double longitude}) {
    return latitude >= southwestLatitude &&
        latitude <= northeastLatitude &&
        longitude >= southwestLongitude &&
        longitude <= northeastLongitude;
  }

  SupportedMapBounds? intersection(SupportedMapBounds other) {
    final southwestLatitude = this.southwestLatitude > other.southwestLatitude
        ? this.southwestLatitude
        : other.southwestLatitude;
    final southwestLongitude =
        this.southwestLongitude > other.southwestLongitude
        ? this.southwestLongitude
        : other.southwestLongitude;
    final northeastLatitude = this.northeastLatitude < other.northeastLatitude
        ? this.northeastLatitude
        : other.northeastLatitude;
    final northeastLongitude =
        this.northeastLongitude < other.northeastLongitude
        ? this.northeastLongitude
        : other.northeastLongitude;

    if (southwestLatitude > northeastLatitude ||
        southwestLongitude > northeastLongitude) {
      return null;
    }

    return SupportedMapBounds(
      southwestLatitude: southwestLatitude,
      southwestLongitude: southwestLongitude,
      northeastLatitude: northeastLatitude,
      northeastLongitude: northeastLongitude,
    );
  }

  SupportedMapBounds expandedBy(
    double fraction, {
    SupportedMapBounds? constrainedTo,
  }) {
    assert(fraction >= 0);
    final latitudePadding = latitudeSpan * fraction;
    final longitudePadding = longitudeSpan * fraction;
    final expanded = SupportedMapBounds(
      southwestLatitude: (southwestLatitude - latitudePadding).clamp(-90, 90),
      southwestLongitude: (southwestLongitude - longitudePadding).clamp(
        -180,
        180,
      ),
      northeastLatitude: (northeastLatitude + latitudePadding).clamp(-90, 90),
      northeastLongitude: (northeastLongitude + longitudePadding).clamp(
        -180,
        180,
      ),
    );
    return constrainedTo == null
        ? expanded
        : expanded.intersection(constrainedTo) ?? this;
  }
}

class SupportedMapRegion {
  const SupportedMapRegion({
    required this.id,
    required this.localizedNames,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.bounds,
    required this.initialZoom,
    required this.currentLocationZoom,
    required this.minimumZoom,
    required this.maximumZoom,
  });

  final String id;
  final Map<String, String> localizedNames;
  final double centerLatitude;
  final double centerLongitude;
  final SupportedMapBounds bounds;
  final double initialZoom;
  final double currentLocationZoom;
  final double minimumZoom;
  final double maximumZoom;

  bool contains({required double latitude, required double longitude}) {
    return bounds.contains(latitude: latitude, longitude: longitude);
  }

  String localizedName(String languageCode) {
    return localizedNames[languageCode] ?? localizedNames['en'] ?? id;
  }
}

abstract final class SupportedMapRegions {
  /// Riyadh City extent in WGS84 coordinates.
  ///
  /// Add another configured region here, then pass it to [SupportedMapRegion]
  /// consumers to switch the supported map area without changing map logic.
  static const SupportedMapRegion riyadh = SupportedMapRegion(
    id: 'riyadh',
    localizedNames: {'ar': 'الرياض', 'en': 'Riyadh'},
    centerLatitude: 24.7136,
    centerLongitude: 46.6753,
    bounds: SupportedMapBounds(
      southwestLatitude: 24.3173588,
      southwestLongitude: 46.3138654,
      northeastLatitude: 25.1777166,
      northeastLongitude: 47.3272638,
    ),
    initialZoom: 12.5,
    currentLocationZoom: 15.5,
    minimumZoom: 9.5,
    maximumZoom: 20,
  );
}
