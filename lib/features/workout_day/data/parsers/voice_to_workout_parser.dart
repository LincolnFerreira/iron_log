class ParsedExercise {
  final String name;
  final List<int> reps;
  final List<double> weights;
  final String weightUnit;
  final List<String> labels;
  final String notes;

  ParsedExercise({
    required this.name,
    required this.reps,
    required this.weights,
    required this.weightUnit,
    required this.labels,
    required this.notes,
  });
}

/// Very small rule-based parser to extract a single exercise from a freeform
/// Portuguese sentence. Focused on common patterns like:
/// "Supino reto fiz 20kg 15 repetições, depois 40 10, 60 4, senti dor no ombro"
class VoiceToWorkoutParser {
  /// Parse input text and returns a list of detected exercises (usually one).
  static List<ParsedExercise> parse(String input) {
    final text = input.toLowerCase().trim();

    // Extract notes (common patterns)
    final notesMatch = RegExp(
      r'\b(senti|senti dor|doeu|com dor|dói|dor no)\b',
    ).firstMatch(text);
    String notes = '';
    String core = text;
    if (notesMatch != null) {
      final idx = notesMatch.start;
      notes = text.substring(idx).trim();
      core = text.substring(0, idx).trim();
    }

    // Attempt to find exercise name before verbs like 'fiz', 'executei'
    final nameMatch = RegExp(
      r"^(.+?)\s+(?:fiz|executei|fizemos|fa[çc]o|fiz:)",
      caseSensitive: false,
    ).firstMatch(core);
    String name = '';
    String after = core;
    if (nameMatch != null) {
      name = nameMatch.group(1)!.trim();
      after = core.substring(nameMatch.end).trim();
    } else {
      // Fallback: take text before first number as name
      final numMatch = RegExp(r'\d+').firstMatch(core);
      if (numMatch != null) {
        name = core.substring(0, numMatch.start).trim();
        after = core.substring(numMatch.start).trim();
      } else {
        // If no numbers, treat whole core as name
        name = core;
        after = '';
      }
    }

    // Find explicit (weight, reps) pairs like '20kg 15' or '40 10'
    final pairRegex = RegExp(
      r"(\d+(?:[.,]\d+)?)(?:\s*(kg|quil?os|kilos|kg))?\s+(\d+)",
      caseSensitive: false,
    );
    final pairs = pairRegex.allMatches(after).toList();

    print('DEBUG_PARSER: after="$after"');
    print('DEBUG_PARSER: pairMatches count=${pairs.length}');
    for (var mi = 0; mi < pairs.length; mi++) {
      final m = pairs[mi];
      print(
        'DEBUG_PARSER pair[$mi] full=${m.group(0)} g1=${m.group(1)} g2=${m.group(2)} g3=${m.group(3)}',
      );
    }

    final List<double> weights = [];
    final List<int> reps = [];
    String weightUnit = 'kg';

    if (pairs.isNotEmpty) {
      for (final m in pairs) {
        final wRaw = m.group(1) ?? '';
        final unit = m.group(2);
        final rRaw = m.group(3) ?? '0';
        final w = _parseDouble(wRaw);
        final rr = int.tryParse(rRaw) ?? 0;
        if (unit != null && unit.isNotEmpty) {
          weightUnit = 'kg';
        }
        weights.add(w);
        reps.add(rr);
      }
    } else {
      // Fallback: grab all numbers from the full core sentence (not only
      // the "after" slice) and pair them sequentially (weight, reps).
      // This fixes cases like "comecei com 20 quilos fiz 15..." where the
      // initial weight appears before the first verb and would be lost if
      // we only scanned `after`.
      final numRegex = RegExp(r'\d+(?:[.,]\d+)?');
      final nums = numRegex.allMatches(core).map((m) => m.group(0)!).toList();
      print('DEBUG_PARSER: nums=$nums');
      final parsed = nums.map((s) => s.replaceAll(',', '.')).toList();
      print('DEBUG_PARSER: parsedStrings=$parsed');
      for (int i = 0; i + 1 < parsed.length; i += 2) {
        final rawW = parsed[i];
        print('DEBUG_PARSER: weight raw="$rawW"');
        final w = _parseDouble(parsed[i]);
        final rr = int.tryParse(parsed[i + 1]) ?? 0;
        weights.add(w);
        reps.add(rr);
      }
    }

    // Derive labels default (Top Set)
    final labels = List<String>.generate(weights.length, (_) => 'Top Set');

    final parsedExercise = ParsedExercise(
      name: name,
      reps: reps,
      weights: weights,
      weightUnit: weightUnit,
      labels: labels,
      notes: notes,
    );

    return [parsedExercise];
  }

  static double _parseDouble(String raw) {
    try {
      final s = raw.replaceAll(',', '.');
      print('DEBUG_PARSER _parseDouble: raw="$raw" -> s="$s"');
      return double.parse(s);
    } catch (_) {
      return 0.0;
    }
  }
}
