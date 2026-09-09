import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/restaurant_reviews/services/restaurant_review_service.dart';

void main() {
  test(
    'posts the integer rating and trimmed comment with Bearer auth',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      String? authorization;
      Object? body;
      Uri? requestedUri;

      server.listen((request) async {
        requestedUri = request.uri;
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
        body = jsonDecode(await utf8.decoder.bind(request).join());
        request.response
          ..statusCode = HttpStatus.created
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'success': true,
              'message': 'Created.',
              'data': {
                'id': 9,
                'restaurantId': 42,
                'userId': 7,
                'stars': 5,
                'comment': 'تجربة ممتازة',
                'isPublished': true,
                'createdAtUtc': '2026-09-09T12:00:00Z',
                'updatedAtUtc': null,
              },
              'errors': <String>[],
              'statusCode': 201,
            }),
          );
        await request.response.close();
      });

      final apiClient = ApiClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        authorizationDelegate: _AuthorizationDelegate(),
      );
      addTearDown(apiClient.close);
      final service = RestaurantReviewService(apiClient: apiClient);

      await service.createReview(
        restaurantId: 42,
        stars: 5,
        comment: '  تجربة ممتازة  ',
      );

      expect(requestedUri?.path, '/api/restaurants/42/user-reviews');
      expect(authorization, 'Bearer test-token');
      expect(body, {'stars': 5, 'comment': 'تجربة ممتازة'});
    },
  );
}

class _AuthorizationDelegate implements ApiAuthorizationDelegate {
  @override
  Future<void> clearSession() async {}

  @override
  Future<String?> getAccessToken() async => 'test-token';

  @override
  Future<String?> refreshAccessToken() async => null;
}
