import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/core/routes/app_router.dart';
import 'package:iron_log/features/home/presentation/providers/home_provider.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_update.dart';
import '../providers/routine_provider.dart';
import '../providers/routine_ui_feedback_provider.dart';
import '../components/molecules/routine_card.dart';
import '../widgets/routine_loading_skeletons.dart';

class RoutinesPage extends ConsumerStatefulWidget {
  const RoutinesPage({super.key});

  @override
  ConsumerState<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends ConsumerState<RoutinesPage>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routineNotifierProvider.notifier).loadRoutines();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modal = ModalRoute.of(context);
    if (modal != null) {
      routeObserver.subscribe(this, modal);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Voltamos para esta página (subpágina foi fechada) — recarrega.
    ref.read(routineNotifierProvider.notifier).loadRoutines();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(routineNotifierProvider.notifier).loadRoutines();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(routineUiFeedbackProvider, (previous, next) {
      if (next == null || !mounted) return;

      VoidCallback? onAction;
      if (next.actionLabel != null && next.actionRoutineId != null) {
          final routineId = next.actionRoutineId!;
        onAction = () {
          final routines = ref.read(routineNotifierProvider).routines;
          final index = routines.indexWhere((r) => r.id == routineId);
          if (index >= 0 && mounted) {
            _navigateToRoutineDetail(context, routines[index]);
          }
        };
      }

      switch (next.kind) {
        case RoutineUiFeedbackKind.success:
          AppSnackbar.success(
            context: context,
            title: next.title,
            message: next.message,
            actionLabel: next.actionLabel,
            onAction: onAction,
          );
        case RoutineUiFeedbackKind.warning:
          AppSnackbar.warning(
            context: context,
            title: next.title,
            message: next.message,
          );
        case RoutineUiFeedbackKind.error:
          AppSnackbar.error(
            context: context,
            title: next.title,
            message: next.message,
          );
      }
      ref.read(routineUiFeedbackProvider.notifier).clear();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Rotinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(routineNotifierProvider.notifier).loadRoutines(),
            tooltip: 'Recarregar rotinas',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateRoutineDialog(context, ref),
            tooltip: 'Criar nova rotina',
          ),
        ],
      ),
      // Isola rebuilds da lista: ignora selectedRoutine e não rebuilda o AppBar.
      body: Consumer(
        builder: (context, ref, _) {
          final view = ref.watch(
            routineNotifierProvider.select(
              (s) => (
                isLoading: s.isLoading,
                error: s.error,
                routines: s.routines,
              ),
            ),
          );
          return _buildBody(view);
        },
      ),
    );
  }

  Widget _buildBody(
    ({bool isLoading, String? error, List<Routine> routines}) view,
  ) {
    if (view.isLoading) {
      return const RoutinesListSkeleton();
    }

    if (view.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erro: ${view.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(routineNotifierProvider.notifier).loadRoutines(),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (view.routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma rotina encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreateRoutineDialog(context, ref),
              child: const Text('Criar Primeira Rotina'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: view.routines.length,
      itemBuilder: (context, index) {
        final routine = view.routines[index];
        return RoutineCard(
          routine: routine,
          onTap: () => _navigateToRoutineDetail(context, routine),
          onSetActive: () => _setActiveRoutine(context, ref, routine),
          onEdit: () => _showEditRoutineDialog(context, ref, routine),
          onDelete: () => _showDeleteConfirmation(context, ref, routine),
        );
      },
    );
  }

  void _showCreateRoutineDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final divisionSuggestions = <String>[
      'Push/Pull/Legs',
      'Upper/Lower',
      'Full Body',
      'Personalizado',
    ];

    var showNameError = false;
    var isSubmitting = false;
    String? selectedDivision;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(
                          sheetContext,
                        ).colorScheme.outline.withValues(alpha: .18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Criar rotina',
                                    style: Theme.of(sheetContext).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Monte sua divisão agora e ajuste sessões depois.',
                                    style: Theme.of(sheetContext).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Passo 1',
                          style: Theme.of(sheetContext).textTheme.labelMedium?.copyWith(
                            color: Theme.of(sheetContext).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nome da rotina',
                          style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (showNameError) {
                              setState(() => showNameError = false);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Nome da rotina',
                            hintText: 'Ex: Hipertrofia 2026',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  sheetContext,
                                ).colorScheme.outline.withValues(alpha: .3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(sheetContext).colorScheme.primary,
                              ),
                            ),
                            errorText: showNameError
                                ? 'Por favor insira um nome para a rotina'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Divisão',
                          style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Como você divide seus treinos?',
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: divisionSuggestions.map((suggestion) {
                            final selected = selectedDivision == suggestion;
                            return SizedBox(
                              height: 34,
                              child: ChoiceChip(
                                label: Text(
                                  suggestion,
                                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                ),
                                selected: selected,
                                visualDensity: VisualDensity.compact,
                                selectedColor: Theme.of(
                                  sheetContext,
                                ).colorScheme.primaryContainer,
                                side: BorderSide(
                                  color: selected
                                      ? Theme.of(sheetContext).colorScheme.primary.withValues(alpha: .24)
                                      : Theme.of(sheetContext).colorScheme.outline.withValues(alpha: .24),
                                ),
                                onSelected: (_) {
                                  selectedDivision = selected ? null : suggestion;
                                  setState(() {});
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(sheetContext).colorScheme.primaryContainer.withValues(
                              alpha: .35,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.primary.withValues(alpha: .22),
                            ),
                          ),
                          child: Text(
                            '✨ Você pode montar manualmente e editar sessões/exercícios depois.',
                            style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                              color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            side: BorderSide(
                              color: Theme.of(sheetContext).colorScheme.outline.withValues(alpha: .3),
                            ),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) {
                                    setState(() => showNameError = true);
                                    return;
                                  }

                                  setState(() => isSubmitting = true);

                                  final created = await ref
                                      .read(routineNotifierProvider.notifier)
                                      .createRoutine(
                                        name: name,
                                        division: selectedDivision,
                                      );

                                  if (created == null) {
                                    if (sheetContext.mounted) {
                                      setState(() => isSubmitting = false);
                                    }
                                    final err = ref
                                        .read(routineNotifierProvider)
                                        .error;
                                    showRoutineUiFeedback(
                                      ref,
                                      RoutineUiFeedbackMessage.error(
                                        title: 'Erro ao criar',
                                        message:
                                            err ?? 'Não foi possível criar a rotina',
                                      ),
                                    );
                                    return;
                                  }

                                  ref.read(homeProvider.notifier).refresh();

                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }

                                  showRoutineUiFeedback(
                                    ref,
                                    RoutineUiFeedbackMessage.success(
                                      title: 'Rotina criada',
                                      message: 'Rotina criada com sucesso',
                                      actionLabel: 'Adicionar sessões',
                                      actionRoutineId: created.id,
                                    ),
                                  );
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Criar rotina'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _setActiveRoutine(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    try {
      await ref.read(routineRepositoryProvider).setActiveRoutine(routine.id);
      // Reload so isActive reflects correctly in all cards.
      if (!context.mounted) return;
      await ref.read(routineNotifierProvider.notifier).loadRoutines();
      // Also refresh home so today's session reflects the new active routine.
      ref.read(homeProvider.notifier).refresh();
      showRoutineUiFeedback(
        ref,
        RoutineUiFeedbackMessage.success(
          title: 'Rotina ativa',
          message: '"${routine.name}" definida como rotina ativa',
        ),
      );
    } catch (e) {
      showRoutineUiFeedback(
        ref,
        RoutineUiFeedbackMessage.error(
          title: 'Erro',
          message: 'Erro ao definir rotina ativa: $e',
        ),
      );
    }
  }

  void _showEditRoutineDialog(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) {
    final nameController = TextEditingController(text: routine.name);
    final divisionController = TextEditingController(
      text: routine.division ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Rotina'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome da Rotina'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: divisionController,
              decoration: const InputDecoration(
                labelText: 'Divisão (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updates = RoutineUpdate(
                  name: nameController.text,
                  division: divisionController.text.isEmpty
                      ? null
                      : divisionController.text,
                );
                ref
                    .read(routineNotifierProvider.notifier)
                    .updateRoutine(routine.id, updates);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a rotina "${routine.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref
                  .read(routineNotifierProvider.notifier)
                  .deleteRoutine(routine.id);
              Navigator.of(context).pop();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _navigateToRoutineDetail(BuildContext context, Routine routine) {
    context.push('/routines/${routine.id}/edit', extra: routine);
  }
}
