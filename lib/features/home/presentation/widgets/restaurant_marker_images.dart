import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Two shared, locally bundled glyphs, decoded by MapLibre once per style.
abstract final class RestaurantMarkerImages {
  static const restaurant = 'thuraya-restaurant-icon';
  static const cafe = 'thuraya-cafe-icon';
  static const imageSize = 72.0;

  static Future<Map<String, Uint8List>>? _images;
  static Map<String, Uint8List>? _loadedImages;

  static Future<Map<String, Uint8List>> load() {
    final loaded = _loadedImages;
    return loaded == null ? _images ??= _load() : SynchronousFuture(loaded);
  }

  static Future<Map<String, Uint8List>> _load() async {
    final restaurantBytes = await rootBundle.load(
      'assets/map/restaurant_icon.png',
    );
    final cafeBytes = await rootBundle.load('assets/map/cafe_icon.png');
    return _loadedImages = Map.unmodifiable({
      restaurant: restaurantBytes.buffer.asUint8List(
        restaurantBytes.offsetInBytes,
        restaurantBytes.lengthInBytes,
      ),
      cafe: cafeBytes.buffer.asUint8List(
        cafeBytes.offsetInBytes,
        cafeBytes.lengthInBytes,
      ),
    });
  }
}
