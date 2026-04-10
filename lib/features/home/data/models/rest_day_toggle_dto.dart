/// DTO for rest day toggle response
class RestDayToggleDto {
  final bool active;

  RestDayToggleDto({required this.active});

  /// Factory constructor to deserialize from API response
  factory RestDayToggleDto.fromJson(Map<String, dynamic> json) {
    return RestDayToggleDto(active: (json['active'] as bool?) ?? false);
  }
}
