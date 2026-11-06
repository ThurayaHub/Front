import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';

void main() {
  Map<String, dynamic> markerJson() => {
    'id': 1,
    'name': 'Coffee Restaurant',
    'latitude': 24.71,
    'longitude': 46.67,
    'hasThurayaStar': true,
  };

  test(
    'uses backend placeType even when a multi-category primary category differs',
    () {
      final json = {
        ...markerJson(),
        'placeType': 'cafe',
        'primaryCategoryName': 'Italian',
        'categories': [
          {'name': 'Italian'},
          {'name': 'Cafe'},
        ],
      };
      expect(
        RestaurantMapMarker.fromJson(json).placeType,
        RestaurantMapPlaceType.cafe,
      );
      json['categories'] = [
        {'name': 'Cafe'},
        {'name': 'Italian'},
      ];
      expect(
        RestaurantMapMarker.fromJson(json).placeType,
        RestaurantMapPlaceType.cafe,
      );
    },
  );

  test('normalizes type capitalization and whitespace', () {
    expect(
      RestaurantMapMarker.fromJson({
        ...markerJson(),
        'placeType': ' CaFe ',
      }).placeType,
      RestaurantMapPlaceType.cafe,
    );
  });

  test(
    'missing or unknown type has a stable restaurant fallback without guessing from names',
    () {
      for (final type in [null, '', 'unknown', 42]) {
        expect(
          RestaurantMapMarker.fromJson({
            ...markerJson(),
            'placeType': type,
          }).placeType,
          RestaurantMapPlaceType.restaurant,
        );
      }
      expect(
        RestaurantMapMarker.fromJson(markerJson()).placeType,
        RestaurantMapPlaceType.restaurant,
      );
    },
  );

  test('business category and Thuraya Star award are independent', () {
    for (final star in [true, false]) {
      final venue = RestaurantMapMarker.fromJson({
        ...markerJson(),
        'placeType': 'restaurant',
        'primaryCategoryName': 'Cafe',
        'hasThurayaStar': star,
      });
      expect(venue.placeType, RestaurantMapPlaceType.restaurant);
      expect(venue.hasThurayaStar, star);
    }
  });
}
