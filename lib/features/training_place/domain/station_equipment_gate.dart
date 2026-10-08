/// Máquina, cabo e Smith pedem estação. O número do stack não se compara
/// entre aparelhos. Tipo ausente ou outro equipamento não pede.
bool stationEquipmentRequiresStation(String? equipmentName) {
  if (equipmentName == null || equipmentName.trim().isEmpty) return false;
  final normalized = foldEquipment(equipmentName);
  return normalized == 'maquina' ||
      normalized == 'cabo' ||
      normalized == 'smith';
}

String foldEquipment(String raw) {
  const pairs = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ç': 'c',
  };
  final buffer = StringBuffer();
  for (final char in raw.trim().toLowerCase().split('')) {
    buffer.write(pairs[char] ?? char);
  }
  return buffer.toString();
}
