import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/home/models/restaurant_map_bounds.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/services/restaurant_map_service.dart';

void main() {
  test('requests visible bounds and parses the backend marker DTO', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    Uri? requestedUri;

    server.listen((request) async {
      requestedUri = request.uri;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'success': true,
            'message': 'Restaurant map markers retrieved successfully.',
            'data': [
              {
                'id': 7,
                'name': 'Riyadh Restaurant',
                'nameArabic': 'مطعم الرياض',
                'latitude': 24.7136,
                'longitude': 46.6753,
                'placeType': 'cafe',
                'priceLevelId': 2,
                'hasThurayaStar': true,
                'userRatingAverage': 4.75,
                'reviewCount': 18,
                'mainPhotoUrl': '/uploads/restaurants/7/main.jpg',
                'primaryCategoryId': 3,
                'primaryCategoryName': 'سعودي',
              },
            ],
            'errors': <String>[],
            'statusCode': 200,
          }),
        );
      await request.response.close();
    });

    final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(apiClient.close);
    final service = RestaurantMapService(apiClient: apiClient);

    final markers = await service.getMarkers(
      const RestaurantMapBounds(
        north: 24.8,
        south: 24.6,
        east: 46.8,
        west: 46.5,
      ),
    );

    expect(requestedUri?.path, '/api/restaurants/map');
    expect(requestedUri?.queryParameters, {
      'north': '24.8',
      'south': '24.6',
      'east': '46.8',
      'west': '46.5',
      'limit': '200',
    });
    expect(markers, hasLength(1));
    final marker = markers.single;
    expect(marker.id, 7);
    expect(marker.name, 'Riyadh Restaurant');
    expect(marker.nameArabic, 'مطعم الرياض');
    expect(marker.localizedName('ar'), 'مطعم الرياض');
    expect(marker.latitude, 24.7136);
    expect(marker.longitude, 46.6753);
    expect(marker.placeType, RestaurantMapPlaceType.cafe);
    expect(marker.priceLevelId, 2);
    expect(marker.hasThurayaStar, isTrue);
    expect(marker.userRatingAverage, 4.75);
    expect(marker.reviewCount, 18);
    expect(marker.mainPhotoUrl, '/uploads/restaurants/7/main.jpg');
    expect(marker.primaryCategoryId, 3);
    expect(marker.primaryCategoryName, 'سعودي');
  });

  test('surfaces an unsuccessful API result without clearing data', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'success': false,
            'message': 'Map request failed.',
            'data': null,
            'errors': ['Invalid bounds.'],
            'statusCode': 400,
          }),
        );
      await request.response.close();
    });

    final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(apiClient.close);
    final service = RestaurantMapService(apiClient: apiClient);

    expect(
      service.getMarkers(
        const RestaurantMapBounds(
          north: 24.8,
          south: 24.6,
          east: 46.8,
          west: 46.5,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.message,
          'message',
          'Map request failed.',
        ),
      ),
    );
  });
}
