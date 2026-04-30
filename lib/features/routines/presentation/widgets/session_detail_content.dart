import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/search_exercise.dart';
import '../../data/models/session_exercise_update_dto.dart';
import 'available_exercises_list.dart';
import 'selected_exercises_section.dart';
import '../providers/session_selection_provider.dart';
import '../providers/exercise_browse_provider.dart';
import '../providers/session_provider.dart';
import 'session_section_title.dart';

class SessionDetailContent extends ConsumerStatefulWidget {
  final Routine routine;
  final Session? session;
  final TextEditingController sessionNameController;
  // Callback used by the parent to register a save function exposed by this widget
  final void Function(Future<void> Function())? registerSaveCallback;

  const SessionDetailContent({
    super.key,
    required this.routine,
    this.session,
    required this.sessionNameController,
    this.registerSaveCallback,
  });

  @override
  ConsumerState<SessionDetailContent> createState() =>
      _SessionDetailContentState();
}

class _SessionDetailContentState extends ConsumerState<SessionDetailContent> {
  late TextEditingController _musclesController;
  bool _isSaving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _musclesController = TextEditingController(
      text: widget.session?.muscles.join(', ') ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeExercises();
      // Expose the internal save method to the parent via the provided callback
      widget.registerSaveCallback?.call(() => _onSave());
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload: Riverpod reseta os StateProviders mas initState não roda de novo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeExercises();
    });
  }

  void _initializeExercises() {
    final notifier = ref.read(
      sessionExerciseSelectionNotifierProvider.notifier,
    );

    if (widget.session != null && widget.session!.exercises.isNotEmpty) {
      final searchExercises = widget.session!.exercises.map((se) {
        return SearchExercise(
          id: se.exerciseId,
          name: se.exercise.name,
          description: se.exercise.description,
          primaryMuscle: se.exercise.primaryMuscle,
          equipment: se.exercise.equipment,
          category: se.exercise.tags.isNotEmpty ? se.exercise.tags.first : null,
        );
      }).toList();

      notifier.initWithSessionExercises(searchExercises);
    } else {
      notifier.clearAll();
    }
  }

  @override
  void dispose() {
    _musclesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedExerciseIds = ref.watch(sessionAllExerciseIdsProvider);
    final hasSelectedExercises = selectedExerciseIds.isNotEmpty && !_isSaving;
    final hasName = widget.sessionNameController.text.trim().isNotEmpty;
    // Filtro de músculos via chips
    final muscleFilter = ref.watch(sessionMuscleFilterProvider);
    final browseAsync = ref.watch(exerciseBrowseProvider);

    return Column(
      children: [
        // Conteúdo scrollável
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            children: [
              // Nome da Sessão
              const SessionSectionTitle('NOME DA SESSÃO'),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.sessionNameController,
                builder: (context, value, child) {
                  return TextField(
                    controller: widget.sessionNameController,
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Ex: Peito e Tríceps',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.edit),
                      errorText: _nameError,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Exercícios Selecionados (Preview com Drag & Drop)
              if (hasSelectedExercises) ...[
                SelectedExercisesSection(
                  session: Session(
                    id: widget.session?.id ?? 'temp',
                    name: '',
                    order: 0,
                    muscles: [],
                    exercises: [],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 32,
                        color: AppColors.primaryLight.withOpacity(0.7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adicione exercícios para criar uma nova sessão',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'ADICIONAR EXERCÍCIOS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: UnifiedExerciseSearch(
                  hintText: 'Pesquisar exercícios...',
                  useSearchAnchor: false,
                  onExerciseSelected: (exercise) {
                    ref
                        .read(sessionExerciseSelectionNotifierProvider.notifier)
                        .toggleExercise(exercise);
                  },
                ),
              ),
              // Filtros rápidos por músculo (chips)
              browseAsync.when(
                skipLoadingOnRefresh: false,
                data: (groups) => SizedBox(
                  height: 48,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: groups.map((g) {
                        final name = g.muscle;
                        final selected = muscleFilter.contains(name);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              name,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? AppColors.primaryLight
                                        : null,
                                  ),
                            ),
                            selected: selected,
                            onSelected: (sel) {
                              final notifier = ref.read(
                                sessionMuscleFilterProvider.notifier,
                              );
                              final current = Set<String>.from(notifier.state);
                              if (sel) {
                                current.add(name);
                              } else {
                                current.remove(name);
                              }
                              notifier.state = current;
                            },
                            selectedColor: AppColors.primaryLight.withOpacity(
                              0.12,
                            ),
                            checkmarkColor: AppColors.primaryLight,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Exercícios Disponíveis
              Text(
                'Exercícios Encontrados',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AvailableExercisesList(
                onExerciseSelected: (exercise) {
                  ref
                      .read(sessionExerciseSelectionNotifierProvider.notifier)
                      .toggleExercise(exercise);
                },
              ),
              const SizedBox(height: 24),

              // Botão de salvar agora faz parte do conteúdo e rola com a tela
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasSelectedExercises
                            ? AppColors.blue100
                            : AppColors.gray20,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: hasSelectedExercises && hasName
                          ? () {
                              setState(() {
                                _isSaving = true;
                              });
                              _onSave();
                            }
                          : hasSelectedExercises && !hasName
                          ? () {
                              setState(
                                () => _nameError =
                                    'Informe um nome para a sessão',
                              );
                            }
                          : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.save_rounded,
                                  color: hasSelectedExercises
                                      ? Colors.white
                                      : AppColors.gray50,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Salvar Sessão',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: hasSelectedExercises
                                            ? Colors.white
                                            : AppColors.gray50,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    final sessionName = widget.sessionNameController.text.trim();
    final muscles = _musclesController.text
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    if (sessionName.isEmpty) {
      setState(() {
        _nameError = 'Informe um nome para a sessão';
        _isSaving = false;
      });
      return;
    }

    final selectedExerciseIds = ref.read(sessionAllExerciseIdsProvider);

    if (selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um exercício')),
      );
      return;
    }

    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
    final isEditing = widget.session != null;
    final selectedExercises = ref.read(sessionAllExercisesProvider);

    Session? result;
    if (isEditing) {
      // Atualizar sessão existente
      result = await sessionNotifier.updateSession(
        widget.session!.id,
        name: sessionName,
        muscles: muscles,
      );
    } else {
      // Criar nova sessão
      final newOrder = widget.routine.sessions.length + 1;
      result = await sessionNotifier.createSession(
        routineId: widget.routine.id,
        name: sessionName,
        order: newOrder,
        muscles: muscles,
      );
    }

    if (!mounted) return;

    // Se a sessão foi salva com sucesso, atualizar os exercícios
    if (result != null) {
      // Formatar exercícios para o backend como DTOs tipados
      final exercisesData = selectedExercises.asMap().entries.map((entry) {
        return SessionExerciseUpdateDto(
          exerciseId: entry.value.id,
          order: entry.key,
          customName: null,
          config: {},
        );
      }).toList();

      // Atualizar exercícios da sessão
      final updateSuccess = await sessionNotifier.updateSessionExercises(
        result.id,
        exercisesData,
      );

      setState(() {
        _isSaving = false;
      });

      if (updateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Sessão atualizada com sucesso!'
                  : 'Sessão criada com sucesso!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      } else {
        final error = ref.watch(sessionNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erro ao salvar exercícios da sessão'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() {
        _isSaving = false;
      });

      final error = ref.watch(sessionNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erro ao salvar sessão'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
