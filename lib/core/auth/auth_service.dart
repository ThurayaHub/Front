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

abstract interface class PhoneOtpGateway {
  Future<PhoneOtpChallenge> requestPhoneOtp(String phoneNumber);

  Future<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  });
}

abstract interface class OtpRegistrationGateway {
  Future<AuthResponse> completeVerifiedRegistration({
    required String phoneNumber,
    required String name,
    required String email,
    required String registrationToken,
  });
}

class AuthService
    implements AuthGateway, PhoneOtpGateway, OtpRegistrationGateway {
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
  Future<PhoneOtpChallenge> requestPhoneOtp(String phoneNumber) async {
    final data = await _apiClient.postResultData(
      '/api/auth/phone-otp/request',
      body: {'phoneNumber': phoneNumber.trim()},
    );
    if (data is! Map) {
      throw const ApiException('The phone verification response is invalid.');
    }
    return PhoneOtpChallenge.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final data = await _apiClient.postResultData(
      '/api/auth/phone-otp/verify',
      body: {'phoneNumber': phoneNumber.trim(), 'otp': otp.trim()},
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
  Future<AuthResponse> completeVerifiedRegistration({
    required String phoneNumber,
    required String name,
    required String email,
    required String registrationToken,
  }) async {
    final data = await _apiClient.postResultData(
      '/api/auth/complete-registration',
      body: {
        'phoneNumber': phoneNumber.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'registrationToken': registrationToken,
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
