String foldNickname(String raw) {
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

String newTrainingPlaceId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = (now.hashCode & 0x7fffffff).toRadixString(36);
  return 'c$now$salt';
}
