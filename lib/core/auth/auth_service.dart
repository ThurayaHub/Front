import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/network/api_client.dart';

abstract interface class AuthGateway {
  Future<AuthResponse> loginWithPhone(String phoneNumber);

  Future<AuthResponse> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  });

  Future<AuthResponse> refresh(String refreshToken);

  Future<void> logout(String refreshToken);
}

class AuthService implements AuthGateway {
  AuthService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(useAuthentication: false),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  @override
  Future<AuthResponse> loginWithPhone(String phoneNumber) async {
    final data = await _apiClient.postResultData(
      '/api/auth/login-phone',
      body: {'phoneNumber': phoneNumber.trim()},
    );
    return _parseResponse(data);
  }

  @override
  Future<AuthResponse> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  }) async {
    final data = await _apiClient.postResultData(
      '/api/auth/complete-registration',
      body: {
        'phoneNumber': phoneNumber.trim(),
        'name': name.trim(),
        'email': email.trim(),
      },
    );
    return _parseResponse(data);
  }

  @override
  Future<AuthResponse> refresh(String refreshToken) async {
    final data = await _apiClient.postResultData(
      '/api/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    return _parseResponse(data);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _apiClient.postResultData(
      '/api/auth/logout',
      body: {'refreshToken': refreshToken},
    );
  }

  AuthResponse _parseResponse(Object? data) {
    if (data is! Map) {
      throw const ApiException('The authentication response is invalid.');
    }
    return AuthResponse.fromJson(Map<String, dynamic>.from(data));
  }

  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }
}
