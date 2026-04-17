import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/routine.dart';
import '../providers/session_provider.dart';
import 'session_card.dart';

class ReorderableSessionList extends ConsumerStatefulWidget {
  final Routine routine;

  /// Chamado no initState para registrar a função de salvar no pai.

  const ReorderableSessionList({super.key, required this.routine});

  @override
  ConsumerState<ReorderableSessionList> createState() =>
      _ReorderableSessionListState();
}

class _ReorderableSessionListState
    extends ConsumerState<ReorderableSessionList> {
  late List<Session> sessions;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    sessions = List.from(widget.routine.sessions);
  }

  @override
  void didUpdateWidget(ReorderableSessionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quando o pai passa uma routine atualizada (após rebusca no didPopNext),
    // sincroniza a lista local preservando a ordem visual atual do drag-and-drop.
    if (oldWidget.routine != widget.routine) {
      final currentIds = sessions.map((s) => s.id).toList();
      final newSessions = widget.routine.sessions;
      final reordered = [
        ...currentIds
            .map((id) => newSessions.where((s) => s.id == id).firstOrNull)
            .whereType<Session>(),
        ...newSessions.where((s) => !currentIds.contains(s.id)),
      ];
      setState(() => sessions = reordered);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return sessions.isEmpty ? _buildEmptyState() : _buildSessionsList();
  }

  Widget _buildSessionsList() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organize suas sessões',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Arraste as sessões para reorganizar a ordem do seu treino',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Reorderable list
        Expanded(
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onReorder: _onReorder,
            children: sessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              return ReorderableDragStartListener(
                index: index,
                key: ValueKey(session.id),
                child: _buildDraggableItem(session, index),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma sessão encontrada',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta rotina não possui sessões',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateSessionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Criar Primeira Sessão'),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(Session session, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SessionCard(
        session: session,
        isDraggable: true,
        onMenuPressed: () => _showSessionMenu(session),
        onTap: () => _navigateToSessionDetail(session),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final session = sessions.removeAt(oldIndex);
      sessions.insert(newIndex, session);
    });

    // Debounce: aguarda 800ms após última mudança antes de persistir
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _persistSessionsOrder();
    });
  }

  Future<void> _persistSessionsOrder() async {
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);

    // Atualiza a ordem de cada sessão no backend
    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final newOrder = i + 1; // ordem baseada em 1

      if (session.order != newOrder) {
        await sessionNotifier.updateSession(session.id, order: newOrder);
      }
    }
  }

  void _showSessionMenu(Session session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              session.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.add,
              title: 'Adicionar Sessão',
              onTap: () {
                Navigator.pop(context);
                _showCreateSessionDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.edit,
              title: 'Editar',
              onTap: () {
                Navigator.pop(context);
                _showEditSessionDialog(session);
              },
            ),
            _buildMenuOption(
              icon: Icons.delete,
              title: 'Excluir',
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a sessão "${session.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                sessions.remove(session);
              });
              Navigator.pop(context);
              // TODO: Persistir no backend
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showEditSessionDialog(Session session) {
    final nameController = TextEditingController(text: session.name);
    final musclesController = TextEditingController(
      text: session.muscles.join(', '),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Sessão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Sessão',
                hintText: 'Ex: Push, Pull, Pernas',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: musclesController,
              decoration: const InputDecoration(
                labelText: 'Grupos Musculares (opcional)',
                hintText: 'Ex: peito, ombros, tríceps',
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
                _updateSession(
                  session,
                  nameController.text,
                  musclesController.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _updateSession(Session session, String name, String musclesText) async {
    final muscles = musclesText.isNotEmpty
        ? musclesText.split(',').map((m) => m.trim()).toList()
        : <String>[];

    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
    final updatedSession = await sessionNotifier.updateSession(
      session.id,
      name: name,
      muscles: muscles,
    );

    if (updatedSession != null) {
      setState(() {
        final index = sessions.indexWhere((s) => s.id == session.id);
        if (index != -1) {
          sessions[index] = updatedSession;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sessão "${updatedSession.name}" atualizada com sucesso!',
          ),
        ),
      );
    } else {
      final sessionState = ref.read(sessionNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionState.error ?? 'Erro ao atualizar sessão'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateSessionDialog() {
    // Navegar para a página de criar nova sessão
    context.push(
      '/routines/${widget.routine.id}/sessions/new',
      extra: widget.routine,
    );
  }

  void _navigateToSessionDetail(Session session) {
    // Navegar para página de detalhes da sessão
    context.push(
      '/routines/${widget.routine.id}/sessions/${session.id}',
      extra: widget.routine,
    );
  }
}
