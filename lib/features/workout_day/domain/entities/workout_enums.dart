/// Tipos de atividade de cardio
enum CardioType {
  running('running', 'Corrida'),
  cycling('cycling', 'Ciclismo'),
  walking('walking', 'Caminhada'),
  swimming('swimming', 'Natação'),
  elliptical('elliptical', 'Elíptico'),
  rowing('rowing', 'Remo'),
  climbing('climbing', 'Escalada'),
  stairClimbing('stair_climbing', 'Escada'),
  jumpingRope('jumping_rope', 'Corda'),
  other('other', 'Outro');

  final String value;
  final String label;

  const CardioType(this.value, this.label);

  static CardioType fromString(String value) {
    try {
      return CardioType.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return CardioType.other;
    }
  }
}

/// Intensidade do exercício
enum Intensity {
  low('low', 'Baixa'),
  moderate('moderate', 'Moderada'),
  high('high', 'Alta');

  final String value;
  final String label;

  const Intensity(this.value, this.label);

  static Intensity fromString(String value) {
    try {
      return Intensity.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return Intensity.moderate;
    }
  }
}
