enum DivisionType {
  fullBody,
  ppl,
  abc,
  custom
}

extension DivisionTypeExtension on DivisionType {
  String get title {
    switch (this) {
      case DivisionType.fullBody:
        return 'Full Body';
      case DivisionType.ppl:
        return 'PPL (Push/Pull/Legs)';
      case DivisionType.abc:
        return 'ABC';
      case DivisionType.custom:
        return 'Customizada';
    }
  }

  String get subtitle {
    switch (this) {
      case DivisionType.fullBody:
        return 'Treino completo por sessão';
      case DivisionType.ppl:
        return 'Divisão por movimento';
      case DivisionType.abc:
        return 'Divisão por grupos musculares';
      case DivisionType.custom:
        return 'Crie sua própria divisão';
    }
  }
}
