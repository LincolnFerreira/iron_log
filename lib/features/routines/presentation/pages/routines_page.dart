import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/routes/app_router.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/home/state/home_provider.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_update.dart';
import '../bloc/routine_provider.dart';
import '../components/molecules/routine_card.dart';

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
    final routineState = ref.watch(routineNotifierProvider);

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
      body: _buildBody(routineState),
    );
  }

  Widget _buildBody(RoutineState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erro: ${state.error}',
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

    if (state.routines.isEmpty) {
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
      itemCount: state.routines.length,
      itemBuilder: (context, index) {
        final routine = state.routines[index];
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
    final divisionController = TextEditingController();

    var showNameError = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Nova Rotina'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uma rotina agrupa sessões (ex.: Push/Pull/Legs). Você poderá adicionar sessões e exercícios depois.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nome da Rotina',
                    hintText: 'Ex: Treino ABC',
                    errorText: showNameError
                        ? 'Por favor insira um nome para a rotina'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: divisionController,
                  decoration: const InputDecoration(
                    labelText: 'Divisão (opcional)',
                    hintText: 'Ex: Push/Pull/Legs',
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
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    setState(() => showNameError = true);
                    return;
                  }

                  // Create the routine and update state
                  await ref
                      .read(routineNotifierProvider.notifier)
                      .createRoutine(
                        name: name,
                        division: divisionController.text.isEmpty
                            ? null
                            : divisionController.text.trim(),
                      );

                  // Nova rotina é auto-ativada no backend — sincroniza Home.
                  ref.read(homeProvider.notifier).refresh();

                  Navigator.of(context).pop();

                  // Try to find the created routine by name in current state
                  final routines = ref.read(routineNotifierProvider).routines;
                  final matches = routines
                      .where((r) => r.name == name)
                      .toList();
                  final created = matches.isNotEmpty ? matches.last : null;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Rotina criada'),
                      action: SnackBarAction(
                        label: 'Adicionar sessões',
                        onPressed: () {
                          if (created != null) {
                            _navigateToRoutineDetail(context, created);
                          }
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Criar'),
              ),
            ],
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
      await AuthService().patch(
        ApiEndpoints.userActiveRoutine(routine.id),
      );
      // Reload so isActive reflects correctly in all cards.
      if (!context.mounted) return;
      await ref.read(routineNotifierProvider.notifier).loadRoutines();
      // Also refresh home so today's session reflects the new active routine.
      ref.read(homeProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${routine.name}" definida como rotina ativa')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao definir rotina ativa: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
