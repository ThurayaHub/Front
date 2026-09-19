class WheelOptionDto {
  const WheelOptionDto({
    required this.id,
    required this.text,
    required this.isActive,
  });

  factory WheelOptionDto.fromJson(Map<String, dynamic> json) {
    return WheelOptionDto(
      id: (json['id'] as num).toInt(),
      text: json['text'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  final int id;
  final String text;
  final bool isActive;
}

class WheelSessionDto {
  const WheelSessionDto({
    required this.id,
    required this.name,
    required this.options,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  factory WheelSessionDto.fromJson(Map<String, dynamic> json) {
    final options = json['options'];
    if (options is! List) {
      throw const FormatException('Wheel session options are invalid.');
    }
    return WheelSessionDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      options: options
          .map(
            (option) => WheelOptionDto.fromJson(
              Map<String, dynamic>.from(option as Map),
            ),
          )
          .toList(growable: false),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(json['updatedAtUtc'] as String).toUtc(),
    );
  }

  final int id;
  final String? name;
  final List<WheelOptionDto> options;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
}

class WheelSpinResultDto {
  const WheelSpinResultDto({
    required this.id,
    required this.wheelSessionId,
    required this.selectedOption,
    required this.createdAtUtc,
  });

  factory WheelSpinResultDto.fromJson(Map<String, dynamic> json) {
    return WheelSpinResultDto(
      id: (json['id'] as num).toInt(),
      wheelSessionId: (json['wheelSessionId'] as num).toInt(),
      selectedOption: WheelOptionDto.fromJson(
        Map<String, dynamic>.from(json['selectedOption'] as Map),
      ),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
    );
  }

  final int id;
  final int wheelSessionId;
  final WheelOptionDto selectedOption;
  final DateTime createdAtUtc;
}

class WheelSpinSelection {
  const WheelSpinSelection({required this.result, required this.optionIndex});

  final WheelSpinResultDto result;
  final int optionIndex;
}
