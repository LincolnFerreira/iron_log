import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filtro ativo na tela de histórico.
/// Valores: 'all', 'week', 'month'
final historyFilterProvider = StateProvider<String>((ref) => 'all');
