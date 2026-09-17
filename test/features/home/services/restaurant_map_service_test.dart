import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
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
      const SupportedMapBounds(
        southwestLatitude: 24.6,
        southwestLongitude: 46.5,
        northeastLatitude: 24.8,
        northeastLongitude: 46.8,
      ),
    );

    expect(requestedUri?.path, '/api/restaurants/map');
    expect(requestedUri?.queryParameters, {
      'north': '24.8',
      'south': '24.6',
      'east': '46.8',
      'west': '46.5',
      'limit': '500',
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
        const SupportedMapBounds(
          southwestLatitude: 24.6,
          southwestLongitude: 46.5,
          northeastLatitude: 24.8,
          northeastLongitude: 46.8,
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

  test(
    'follows map page cursors and merges markers by restaurant ID',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requestedAfterIds = <String?>[];

      server.listen((request) async {
        final afterId = request.uri.queryParameters['afterId'];
        requestedAfterIds.add(afterId);
        final isSecondPage = afterId == '7';
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'success': true,
              'message': 'Restaurant map markers retrieved successfully.',
              'data': {
                'items': [
                  {
                    'id': isSecondPage ? 8 : 7,
                    'name': isSecondPage ? 'Second' : 'First',
                    'nameArabic': null,
                    'latitude': 24.7,
                    'longitude': 46.7,
                    'placeType': 'restaurant',
                    'hasThurayaStar': false,
                  },
                ],
                'nextAfterId': isSecondPage ? null : 7,
              },
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
        const SupportedMapBounds(
          southwestLatitude: 24.6,
          southwestLongitude: 46.5,
          northeastLatitude: 24.8,
          northeastLongitude: 46.8,
        ),
      );

      expect(requestedAfterIds, [null, '7']);
      expect(markers.map((marker) => marker.id), [7, 8]);
    },
  );

  test('posts every optional discovery filter as typed JSON', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    Uri? requestedUri;
    Object? requestedBody;

    server.listen((request) async {
      requestedUri = request.uri;
      requestedBody = jsonDecode(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'success': true,
            'message': 'Restaurant search results retrieved successfully.',
            'data': [
              {
                'id': 9,
                'name': 'Burger House',
                'nameArabic': 'بيت البرجر',
                'latitude': 24.71,
                'longitude': 46.67,
                'priceLevelId': 2,
                'priceLevelName': 'Medium',
                'hasThurayaStar': false,
                'thurayaRatingAverage': 9.0,
                'thurayaReviewCount': 1,
                'userRatingAverage': 4.5,
                'reviewCount': 12,
                'mainPhotoUrl': null,
                'primaryCategoryId': 5,
                'primaryCategoryName': 'American',
                'neighborhoodId': 4,
                'neighborhoodNameAr': 'العليا',
                'neighborhoodNameEn': 'Al Olaya',
                'address': 'العليا، الرياض',
                'placeType': 'restaurant',
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
    final results = await service.search(
      RestaurantSearchFilters(
        searchText: 'برجر',
        priceLevelIds: {2, 3},
        categoryIds: {5, 8},
        minimumUserRating: 4,
        hasThurayaRating: true,
      ),
      const SupportedMapBounds(
        southwestLatitude: 24.3,
        southwestLongitude: 46.3,
        northeastLatitude: 25.1,
        northeastLongitude: 47.3,
      ),
    );

    expect(requestedUri?.path, '/api/restaurants/search');
    expect(requestedBody, {
      'searchText': 'برجر',
      'priceLevelIds': [2, 3],
      'categoryIds': [5, 8],
      'minimumUserRating': 4,
      'hasThurayaRating': true,
      'north': 25.1,
      'south': 24.3,
      'east': 47.3,
      'west': 46.3,
      'limit': 500,
    });
    expect(results.single.localizedName('ar'), 'بيت البرجر');
    expect(results.single.thurayaRatingAverage, 9);
    expect(results.single.localizedNeighborhood('en'), 'Al Olaya');
  });

  test('uses the lightweight filtered map route in map mode', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    Uri? requestedUri;
    Object? requestedBody;

    server.listen((request) async {
      requestedUri = request.uri;
      requestedBody = jsonDecode(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'success': true,
            'message': 'Restaurant map markers retrieved successfully.',
            'data': {
              'items': [
                {
                  'id': 9,
                  'name': 'Burger House',
                  'nameArabic': 'بيت البرجر',
                  'latitude': 24.71,
                  'longitude': 46.67,
                  'placeType': 'restaurant',
                  'hasThurayaStar': false,
                },
              ],
              'nextAfterId': null,
            },
            'errors': <String>[],
            'statusCode': 200,
          }),
        );
      await request.response.close();
    });

    final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(apiClient.close);
    final service = RestaurantMapService(apiClient: apiClient);
    final filters = RestaurantSearchFilters(categoryIds: {5});
    final results = await service.loadViewport(
      filters,
      const SupportedMapBounds(
        southwestLatitude: 24.6,
        southwestLongitude: 46.6,
        northeastLatitude: 24.7,
        northeastLongitude: 46.7,
      ),
      cacheExtent: const SupportedMapBounds(
        southwestLatitude: 24.3,
        southwestLongitude: 46.3,
        northeastLatitude: 25.2,
        northeastLongitude: 47.4,
      ),
      includeListMetadata: false,
    );

    expect(requestedUri?.path, '/api/restaurants/map/search');
    expect((requestedBody as Map<String, dynamic>)['categoryIds'], [5]);
    expect(results.single.id, 9);
    expect(results.single.priceLevelId, isNull);
  });
}
