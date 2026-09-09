class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _requiredNumber(json, 'id').toInt(),
      name: _requiredString(json, 'name'),
      email: _requiredString(json, 'email'),
      phoneNumber: json['phoneNumber'] as String?,
      role: _requiredString(json, 'role'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshTokenExpiresAtUtc,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAtUtc;
  final DateTime refreshTokenExpiresAtUtc;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(_requiredMap(json, 'user')),
      accessToken: _requiredString(json, 'accessToken'),
      refreshToken: _requiredString(json, 'refreshToken'),
      accessTokenExpiresAtUtc: DateTime.parse(
        _requiredString(json, 'accessTokenExpiresAtUtc'),
      ).toUtc(),
      refreshTokenExpiresAtUtc: DateTime.parse(
        _requiredString(json, 'refreshTokenExpiresAtUtc'),
      ).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresAtUtc': accessTokenExpiresAtUtc
          .toUtc()
          .toIso8601String(),
      'refreshTokenExpiresAtUtc': refreshTokenExpiresAtUtc
          .toUtc()
          .toIso8601String(),
    };
  }
}

class AuthResponse {
  const AuthResponse({
    required this.isNewUser,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshTokenExpiresAtUtc,
  });

  final bool isNewUser;
  final AuthUser? user;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? accessTokenExpiresAtUtc;
  final DateTime? refreshTokenExpiresAtUtc;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuthResponse(
      isNewUser: json['isNewUser'] == true,
      user: user is Map
          ? AuthUser.fromJson(Map<String, dynamic>.from(user))
          : null,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      accessTokenExpiresAtUtc: _optionalDateTime(
        json['accessTokenExpiresAtUtc'],
      ),
      refreshTokenExpiresAtUtc: _optionalDateTime(
        json['refreshTokenExpiresAtUtc'],
      ),
    );
  }

  AuthSession? toSession() {
    final currentUser = user;
    final currentAccessToken = accessToken?.trim();
    final currentRefreshToken = refreshToken?.trim();
    final accessExpiry = accessTokenExpiresAtUtc;
    final refreshExpiry = refreshTokenExpiresAtUtc;
    if (currentUser == null ||
        currentAccessToken == null ||
        currentAccessToken.isEmpty ||
        currentRefreshToken == null ||
        currentRefreshToken.isEmpty ||
        accessExpiry == null ||
        refreshExpiry == null) {
      return null;
    }

    return AuthSession(
      user: currentUser,
      accessToken: currentAccessToken,
      refreshToken: currentRefreshToken,
      accessTokenExpiresAtUtc: accessExpiry,
      refreshTokenExpiresAtUtc: refreshExpiry,
    );
  }
}

DateTime? _optionalDateTime(Object? value) {
  return value is String ? DateTime.tryParse(value)?.toUtc() : null;
}

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value;
  }
  throw FormatException('Missing or invalid auth field "$key".');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('Missing or invalid auth field "$key".');
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('Missing or invalid auth field "$key".');
}
