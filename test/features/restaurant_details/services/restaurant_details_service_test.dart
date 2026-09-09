import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';

import '../../../fixtures/restaurant_details_fixture.dart';

void main() {
  test('requests the ID endpoint and parses the actual details DTO', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    Uri? requestedUri;

    server.listen((request) async {
      requestedUri = request.uri;
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(successfulRestaurantDetailsResult));
      await request.response.close();
    });

    final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(apiClient.close);
    final service = RestaurantDetailsService(apiClient: apiClient);

    final details = await service.getDetails(42);

    expect(requestedUri?.path, '/api/restaurants/42');
    expect(details.id, 42);
    expect(details.name, 'Riyadh Table');
    expect(details.nameArabic, 'مائدة الرياض');
    expect(details.latitude, 24.7136);
    expect(details.longitude, 46.6753);
    expect(details.priceLevelId, 3);
    expect(details.hasThurayaStar, isTrue);
    expect(details.categories.single.name, 'Saudi');
    expect(details.photos.single.isCoverPhoto, isTrue);
    expect(details.badges.single.name, 'Thuraya Star');
    expect(details.reviewSummary.userRatingAverage, 4.5);
    expect(details.reviewSummary.reviewCount, 8);
    expect(details.thurayaReviewSummary.averageRating, 9.5);
    expect(details.thurayaReviewSummary.latestReview?.id, 71);
    expect(details.isFavorite, isNull);
  });

  test(
    'uses the authenticated favorite endpoints and parses their state',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <(String, String)>[];

      server.listen((request) async {
        requests.add((request.method, request.uri.path));
        final isFavorite = request.method == 'POST';
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'success': true,
              'message': 'Favorite updated.',
              'data': {
                'restaurantId': 42,
                'userId': 7,
                'isFavorite': isFavorite,
              },
              'errors': <String>[],
              'statusCode': 200,
            }),
          );
        await request.response.close();
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
      addTearDown(apiClient.close);
      final service = RestaurantDetailsService(apiClient: apiClient);

      final added = await service.setFavorite(42, isFavorite: true);
      final removed = await service.setFavorite(42, isFavorite: false);

      expect(requests, [
        ('POST', '/api/restaurants/42/favorite'),
        ('DELETE', '/api/restaurants/42/favorite'),
      ]);
      expect(added.isFavorite, isTrue);
      expect(removed.isFavorite, isFalse);
    },
  );
}
