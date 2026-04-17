/// Enum que define o modo de operação da tela de treino.
///
/// Diferencia entre três contextos operacionais distintos:
/// - template: Editando a configuração de uma sessão/rotina
/// - execution: Executando um treino em tempo real
/// - editing: Editando um treino já realizado (log histórico)
enum WorkoutScreenMode {
  /// Modo template: editando a estrutura/configuração de uma sessão
  /// Salvamentos afetam a rotina base, não um treino específico
  template,

  /// Modo execution: executando um treino em tempo real
  /// Salvamentos criam um novo WorkoutSession + SerieLog
  /// Permite recuperação se o app crashear
  execution,

  /// Modo editing: editando um treino já realizado
  /// Salvamentos são PATCHes em um WorkoutSession existente
  /// Modifica logs históricos, não a rotina
  editing,
}
