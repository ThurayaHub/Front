import 'dart:ui';

import 'package:share_plus/share_plus.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantExternalActions {
  const RestaurantExternalActions();

  Future<bool> openDirections(RestaurantDetailsDto restaurant) {
    final backendUrl = Uri.tryParse(restaurant.googleMapsUrl.trim());
    final directionsUri = backendUrl != null && backendUrl.hasScheme
        ? backendUrl
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': '${restaurant.latitude},${restaurant.longitude}',
          });

    return launchUrl(directionsUri, mode: LaunchMode.externalApplication);
  }

  Future<void> shareRestaurant(
    RestaurantDetailsDto restaurant, {
    Rect? sharePositionOrigin,
  }) {
    final address = restaurant.address.trim();
    final mapsUrl = restaurant.googleMapsUrl.trim();
    final text = [
      restaurant.name.trim(),
      if (address.isNotEmpty) address,
      if (mapsUrl.isNotEmpty) mapsUrl,
    ].join('\n');

    return SharePlus.instance.share(
      ShareParams(
        subject: restaurant.name.trim(),
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
