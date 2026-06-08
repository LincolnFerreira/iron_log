import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:iron_log/core/components/exercise_search/exercise_search.dart';

import 'package:iron_log/core/components/exercise_search/unified_exercise_search.dart';

import 'package:iron_log/core/app_colors.dart';

import '../../domain/entities/routine.dart';

import '../../domain/entities/search_exercise.dart';

import '../../data/models/session_exercise_update_dto.dart';

import 'available_exercises_list.dart';

import 'selected_exercises_section.dart';

import '../providers/session_selection_provider.dart';

import '../providers/exercise_browse_provider.dart';

import '../providers/session_provider.dart';

import '../providers/session_editor_state.dart';

import 'session_exercise_loading.dart';

import 'session_muscle_chip.dart';

import 'session_screen_styles.dart';

import 'session_section_title.dart';



class SessionDetailContent extends ConsumerStatefulWidget {

  final Routine routine;

  final Session? session;

  final TextEditingController sessionNameController;

  final void Function(Future<void> Function())? registerSaveCallback;

  final ValueChanged<bool>? onSavingChanged;



  const SessionDetailContent({

    super.key,

    required this.routine,

    this.session,

    required this.sessionNameController,

    this.registerSaveCallback,

    this.onSavingChanged,

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

      widget.registerSaveCallback?.call(() => _onSave());

    });

  }



  @override

  void reassemble() {

    super.reassemble();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!mounted) return;

      _initializeExercises();

    });

  }



  void _setSaving(bool value) {

    if (_isSaving == value) return;

    setState(() => _isSaving = value);

    widget.onSavingChanged?.call(value);

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

    ref.read(sessionEditorBaselineProvider.notifier).state =
        widget.session != null
        ? SessionEditorSnapshot.fromSession(widget.session!)
        : SessionEditorSnapshot.empty();

    ref.read(sessionEditorNameProvider.notifier).state =
        widget.sessionNameController.text;

    ref.read(sessionEditorMusclesTextProvider.notifier).state =
        _musclesController.text;

    ref.read(sessionEditorIsNewProvider.notifier).state =
        widget.session == null;

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

    final muscleFilter = ref.watch(sessionMuscleFilterProvider);

    final browseAsync = ref.watch(exerciseBrowseProvider);



    return ListView(

      padding: EdgeInsets.fromLTRB(

        18,

        SessionScreenStyles.spacingMd,

        18,

        MediaQuery.of(context).viewInsets.bottom + SessionScreenStyles.spacingLg,

      ),

      children: [

        const SessionSectionTitle('Nome da sessão'),

        const SizedBox(height: SessionScreenStyles.spacingXs),

        ValueListenableBuilder<TextEditingValue>(

          valueListenable: widget.sessionNameController,

          builder: (context, value, child) {

            return SizedBox(

              height: SessionScreenStyles.fieldHeight,

              child: TextField(

                controller: widget.sessionNameController,

                style: const TextStyle(

                  fontSize: 18,

                  fontWeight: FontWeight.w500,

                  color: AppColors.textPrimaryLight,

                ),

                onChanged: (value) {

                  ref.read(sessionEditorNameProvider.notifier).state = value;

                  if (_nameError != null) {

                    setState(() => _nameError = null);

                  }

                },

                decoration: SessionScreenStyles.nameFieldDecoration(

                  hintText: 'Peito e tríceps',

                  errorText: _nameError,

                ),

              ),

            );

          },

        ),

        const SizedBox(height: SessionScreenStyles.spacingMd),



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

          const SizedBox(height: SessionScreenStyles.spacingLg),

        ] else ...[

          Container(

            width: double.infinity,

            padding: const EdgeInsets.symmetric(

              horizontal: SessionScreenStyles.spacingLg,

              vertical: 20,

            ),

            decoration: BoxDecoration(

              color: SessionScreenStyles.emptyBackground,

              borderRadius: BorderRadius.circular(18),

              border: Border.all(color: SessionScreenStyles.emptyBorder),

            ),

            child: Column(

              children: [

                Text(

                  'Adicione exercícios para começar',

                  textAlign: TextAlign.center,

                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                    color: SessionScreenStyles.emptyText,

                    fontWeight: FontWeight.w500,

                  ),

                ),

                const SizedBox(height: SessionScreenStyles.spacingXs),

                Text(

                  'Busque, filtre ou monte por voz',

                  textAlign: TextAlign.center,

                  style: Theme.of(context).textTheme.bodySmall?.copyWith(

                    color: SessionScreenStyles.emptySubtext,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(height: SessionScreenStyles.spacingLg),

        ],



        const SessionSectionTitle('Adicionar exercícios'),

        const SizedBox(height: SessionScreenStyles.spacingSm),

        UnifiedExerciseSearch(

          hintText: 'Pesquisar exercícios...',

          useSearchAnchor: false,

          appearance: ExerciseSearchAppearance.soft,

          onExerciseSelected: (exercise) {

            ref

                .read(sessionExerciseSelectionNotifierProvider.notifier)

                .toggleExercise(exercise);

          },

        ),

        const SizedBox(height: SessionScreenStyles.spacingSm),

        browseAsync.when(

          skipLoadingOnRefresh: false,

          data: (browse) => SizedBox(

            height: 48,

            child: SingleChildScrollView(

              scrollDirection: Axis.horizontal,

              child: Row(

                children: browse.muscles.map((name) {

                  final selected = muscleFilter.contains(name);

                  return Padding(

                    padding: const EdgeInsets.only(right: 10),

                    child: SessionMuscleChip(

                      label: name,

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

                    ),

                  );

                }).toList(),

              ),

            ),

          ),

          loading: () => const ExerciseFilterChipsSkeleton(),

          error: (_, __) => const SizedBox.shrink(),

        ),

        const SizedBox(height: SessionScreenStyles.spacingMd),

        Text(

          'Exercícios encontrados',

          style: SessionScreenStyles.sectionHeading(context),

        ),

        const SizedBox(height: SessionScreenStyles.spacingSm),

        AvailableExercisesList(

          onExerciseSelected: (exercise) {

            ref

                .read(sessionExerciseSelectionNotifierProvider.notifier)

                .toggleExercise(exercise);

          },

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

      });

      _setSaving(false);

      return;

    }



    final selectedExerciseIds = ref.read(sessionAllExerciseIdsProvider);



    if (selectedExerciseIds.isEmpty) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Selecione pelo menos um exercício')),

      );

      _setSaving(false);

      return;

    }



    _setSaving(true);



    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);

    final isEditing = widget.session != null;

    final selectedExercises = ref.read(sessionAllExercisesProvider);



    Session? result;

    if (isEditing) {

      result = await sessionNotifier.updateSession(

        widget.session!.id,

        name: sessionName,

        muscles: muscles,

      );

    } else {

      final newOrder = widget.routine.sessions.length + 1;

      result = await sessionNotifier.createSession(

        routineId: widget.routine.id,

        name: sessionName,

        order: newOrder,

        muscles: muscles,

      );

    }



    if (!mounted) return;



    if (result != null) {

      final exercisesData = selectedExercises.asMap().entries.map((entry) {

        return SessionExerciseUpdateDto(

          exerciseId: entry.value.id,

          order: entry.key,

          customName: null,

          config: {},

        );

      }).toList();



      final updateSuccess = await sessionNotifier.updateSessionExercises(

        result.id,

        exercisesData,

      );



      _setSaving(false);



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

        final error = ref.read(sessionNotifierProvider).error;

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(error ?? 'Erro ao salvar exercícios da sessão'),

            duration: const Duration(seconds: 3),

          ),

        );

      }

    } else {

      _setSaving(false);



      final error = ref.read(sessionNotifierProvider).error;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(error ?? 'Erro ao salvar sessão'),

          duration: const Duration(seconds: 3),

        ),

      );

    }

  }

}


