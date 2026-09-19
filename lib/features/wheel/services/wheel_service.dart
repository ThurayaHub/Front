import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/wheel/models/wheel_models.dart';

abstract interface class WheelGateway {
  Future<WheelSessionDto> createSession({String? name});

  Future<WheelSessionDto> getSession(int wheelSessionId);

  Future<WheelOptionDto> addOption(int wheelSessionId, String text);

  Future<WheelSpinResultDto> spin(int wheelSessionId);
}

class WheelService implements WheelGateway {
  WheelService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  @override
  Future<WheelSessionDto> createSession({String? name}) async {
    final data = await _apiClient.postResultData(
      '/api/wheels',
      body: <String, Object?>{'name': name},
    );
    return WheelSessionDto.fromJson(_object(data, 'wheel session'));
  }

  @override
  Future<WheelSessionDto> getSession(int wheelSessionId) async {
    final data = await _apiClient.getResultData('/api/wheels/$wheelSessionId');
    return WheelSessionDto.fromJson(_object(data, 'wheel session'));
  }

  @override
  Future<WheelOptionDto> addOption(int wheelSessionId, String text) async {
    final data = await _apiClient.postResultData(
      '/api/wheels/$wheelSessionId/options',
      body: <String, Object?>{'text': text},
    );
    return WheelOptionDto.fromJson(_object(data, 'wheel option'));
  }

  @override
  Future<WheelSpinResultDto> spin(int wheelSessionId) async {
    final data = await _apiClient.postResultData(
      '/api/wheels/$wheelSessionId/spin',
    );
    return WheelSpinResultDto.fromJson(_object(data, 'wheel spin'));
  }

  Map<String, dynamic> _object(Object? data, String name) {
    if (data is! Map) {
      throw ApiException('The $name response is invalid.');
    }
    return Map<String, dynamic>.from(data);
  }

  void close() {
    if (_ownsApiClient) _apiClient.close();
  }
}
