import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';

void main() {
  const riyadh = SupportedMapRegions.riyadh;

  test('Riyadh region includes its center and city boundary edges', () {
    expect(
      riyadh.contains(
        latitude: riyadh.centerLatitude,
        longitude: riyadh.centerLongitude,
      ),
      isTrue,
    );
    expect(
      riyadh.contains(
        latitude: riyadh.bounds.southwestLatitude,
        longitude: riyadh.bounds.southwestLongitude,
      ),
      isTrue,
    );
    expect(
      riyadh.contains(
        latitude: riyadh.bounds.northeastLatitude,
        longitude: riyadh.bounds.northeastLongitude,
      ),
      isTrue,
    );
  });

  test('Riyadh region rejects coordinates in other Saudi cities', () {
    expect(riyadh.contains(latitude: 21.5433, longitude: 39.1728), isFalse);
    expect(riyadh.contains(latitude: 26.4207, longitude: 50.0888), isFalse);
  });

  test('region names support locale selection and a safe fallback', () {
    expect(riyadh.localizedName('ar'), 'الرياض');
    expect(riyadh.localizedName('en'), 'Riyadh');
    expect(riyadh.localizedName('fr'), 'Riyadh');
  });

  test('intersects a viewport with the supported region bounds', () {
    const supported = SupportedMapBounds(
      southwestLatitude: 24,
      southwestLongitude: 46,
      northeastLatitude: 25,
      northeastLongitude: 47,
    );
    const viewport = SupportedMapBounds(
      southwestLatitude: 24.5,
      southwestLongitude: 45.5,
      northeastLatitude: 25.5,
      northeastLongitude: 46.5,
    );

    final intersection = supported.intersection(viewport);

    expect(intersection, isNotNull);
    expect(intersection!.southwestLatitude, 24.5);
    expect(intersection.southwestLongitude, 46);
    expect(intersection.northeastLatitude, 25);
    expect(intersection.northeastLongitude, 46.5);
  });

  test('returns no intersection for a viewport outside the region', () {
    const supported = SupportedMapBounds(
      southwestLatitude: 24,
      southwestLongitude: 46,
      northeastLatitude: 25,
      northeastLongitude: 47,
    );
    const viewport = SupportedMapBounds(
      southwestLatitude: 26,
      southwestLongitude: 48,
      northeastLatitude: 27,
      northeastLongitude: 49,
    );

    expect(supported.intersection(viewport), isNull);
  });
}
