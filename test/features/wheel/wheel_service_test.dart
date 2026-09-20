import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/wheel/services/wheel_service.dart';

void main() {
  test(
    'uses authenticated Wheels endpoints and preserves backend IDs',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        final method = request.method;
        Object data;
        if (method == 'GET' && path == '/api/wheels/current') {
          data = _sessionJson(options: [_optionJson(90, 'قهوة', true)]);
        } else if (method == 'POST' && path == '/api/wheels') {
          expect(jsonDecode(request.body), {'name': null});
          data = _sessionJson(options: const []);
        } else if (method == 'GET' && path == '/api/wheels/31') {
          data = _sessionJson(options: [_optionJson(90, 'قهوة', true)]);
        } else if (method == 'POST' && path == '/api/wheels/31/options') {
          expect(jsonDecode(request.body), {'text': 'قهوة'});
          data = _optionJson(90, 'قهوة', true);
        } else if (method == 'DELETE' &&
            path == '/api/wheels/31/options/90') {
          data = _optionJson(90, 'قهوة', false);
        } else if (method == 'POST' && path == '/api/wheels/31/spin') {
          data = {
            'id': 801,
            'wheelSessionId': 31,
            'selectedOption': _optionJson(90, 'قهوة', true),
            'createdAtUtc': '2026-09-20T10:00:00Z',
          };
        } else {
          return http.Response('Not found', 404);
        }
        return http.Response(
          jsonEncode({'success': true, 'data': data}),
          method == 'POST' && path != '/api/wheels/31/spin' ? 201 : 200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = WheelService(
        apiClient: ApiClient(
          baseUrl: 'https://thuraya.test',
          httpClient: client,
          authorizationDelegate: _AuthorizationDelegate(),
        ),
      );

      final current = await service.getCurrentSession();
      final created = await service.createSession();
      final added = await service.addOption(created.id, 'قهوة');
      final loaded = await service.getSession(created.id);
      final removed = await service.removeOption(created.id, added.id);
      final spin = await service.spin(created.id);

      expect(current.options.single.id, 90);
      expect(created.id, 31);
      expect(added.id, 90);
      expect(loaded.options.single.id, 90);
      expect(removed.isActive, isFalse);
      expect(spin.id, 801);
      expect(spin.selectedOption.id, 90);
      expect(requests, hasLength(6));
      expect(
        requests.every(
          (request) => request.headers['Authorization'] == 'Bearer jwt-token',
        ),
        isTrue,
      );
      expect(
        requests.every((request) => !request.body.contains('userId')),
        isTrue,
      );
    },
  );
}

Map<String, Object?> _sessionJson({required List<Object> options}) => {
  'id': 31,
  'name': null,
  'options': options,
  'createdAtUtc': '2026-09-20T09:00:00Z',
  'updatedAtUtc': null,
};

Map<String, Object?> _optionJson(int id, String text, bool active) => {
  'id': id,
  'text': text,
  'isActive': active,
};

class _AuthorizationDelegate implements ApiAuthorizationDelegate {
  @override
  Future<void> clearSession() async {}

  @override
  Future<String?> getAccessToken() async => 'jwt-token';

  @override
  Future<String?> refreshAccessToken() async => 'refreshed-jwt-token';
}
