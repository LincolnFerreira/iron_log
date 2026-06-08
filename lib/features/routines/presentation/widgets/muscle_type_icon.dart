import 'package:flutter/material.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'package:iron_log/features/routines/presentation/widgets/session_screen_styles.dart';

/// Mapeia nomes/slugs de grupos musculares para assets em [assets/type-muscles/].
///
/// A chave do mapa deve ser o nome do arquivo PNG (sem extensão).
abstract final class MuscleTypeAssets {
  static const basePath = 'assets/type-muscles';

  /// asset filename (sem .png) -> aliases aceitos (slug EN, nome PT, variações)
  static const Map<String, List<String>> _aliases = {
    'chest': [
      'chest',
      'peito',
      'peitoral',
      'peitorais',
      'pectorals',
      'upper chest',
      'lower chest',
    ],
    'abs': [
      'abs',
      'abdominal',
      'abdominais',
      'abdomen',
      'core',
      'reto abdominal',
      'six pack',
    ],
    'lower_abs': ['lower abs', 'infra abdominal', 'abdomen inferior'],
    'obliques': ['obliques', 'obliquos', 'obliquo', 'obliqua'],
    'shoulders': [
      'ombro',
      'ombros',
      'shoulders',
      'shoulder',
      'deltoid',
      'deltoids',
      'deltoide',
      'deltoides',
      'front delts',
      'side delts',
    ],
    'rear_delts': [
      'rear delts',
      'posterior deltoid',
      'deltoide posterior',
      'deltoide posteriores',
    ],
    'biceps': ['biceps', 'bíceps', 'bicep', 'braço anterior'],
    'triceps': ['triceps', 'tríceps', 'tricep', 'braço posterior'],
    'forearms': [
      'forearms',
      'forearm',
      'antebraço',
      'antebraços',
      'antebracos',
    ],
    'quadriceps': [
      'quadriceps',
      'quadríceps',
      'quad',
      'quads',
      'coxa frente',
      'coxa anterior',
    ],
    'adductors': [
      'adutores',
      'adutor',
      'adductors',
      'adductor',
      'inner thigh',
      'parte interna da coxa',
    ],
    'calves': [
      'calves',
      'calf',
      'panturrilha',
      'panturrilhas',
      'gastrocnemius',
      'soleus',
    ],
    'glutes': [
      'glute',
      'glutes',
      'glúteo',
      'glúteos',
      'gluteus',
      'gluteos',
      'bunda',
    ],
    'traps': [
      'traps',
      'trap',
      'trapézio',
      'trapezio',
      'trapezius',
      'upper traps',
    ],
    'lower_back': [
      'lower back',
      'lombar',
      'lumbar',
      'erectors',
      'spinal erectors',
      'eretores',
      'inferior das costas',
      'inferior-das-costas',
    ],
    'back': [
      'back',
      'costas',
      'dorsais',
      'dorsal',
      'lats',
      'latissimus',
      'latissimus dorsi',
      'meio das costas',
      'meio-das-costas',
      'middle back',
      'mid back',
      'romboides',
      'rhomboids',
    ],
  };

  static String? slugFor(String? muscle) {
    if (muscle == null || muscle.trim().isEmpty) return null;

    final normalized = _normalize(muscle);
    final pairs = <({String asset, String alias})>[];

    for (final entry in _aliases.entries) {
      for (final alias in entry.value) {
        pairs.add((asset: entry.key, alias: alias));
      }
    }

    pairs.sort((a, b) => b.alias.length.compareTo(a.alias.length));

    for (final pair in pairs) {
      final aliasNorm = _normalize(pair.alias);
      if (normalized == aliasNorm ||
          normalized.startsWith('$aliasNorm ') ||
          normalized.endsWith(' $aliasNorm') ||
          normalized.contains(' $aliasNorm ')) {
        return pair.asset;
      }
    }

    return null;
  }

  static String? pathFor(String? muscle) {
    final slug = slugFor(muscle);
    if (slug == null) return null;
    return '$basePath/$slug.png';
  }

  static String? resolveFromExercise(
    SearchExercise exercise, {
    String? muscleGroup,
  }) {
    final candidates = [
      exercise.primaryMuscle,
      if (exercise.muscles.isNotEmpty) exercise.muscles.first,
      muscleGroup,
    ];

    for (final candidate in candidates) {
      final path = pathFor(candidate);
      if (path != null) return path;
    }
    return null;
  }

  static String _normalize(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    var result = value.toLowerCase().trim();
    accents.forEach((from, to) {
      result = result.replaceAll(from, to);
    });
    return result.replaceAll('-', ' ');
  }
}

class MuscleTypeIcon extends StatelessWidget {
  final SearchExercise exercise;
  final String? muscleGroup;
  final double size;

  const MuscleTypeIcon({
    super.key,
    required this.exercise,
    this.muscleGroup,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = MuscleTypeAssets.resolveFromExercise(
      exercise,
      muscleGroup: muscleGroup,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SessionScreenStyles.cardIconBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: assetPath != null
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => _fallbackIcon(),
              ),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: size * 0.45,
        color: SessionScreenStyles.metaColor,
      ),
    );
  }
}
