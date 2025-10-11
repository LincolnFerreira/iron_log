import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/routine.dart';
import 'session_card.dart';

class ReorderableSessionList extends ConsumerStatefulWidget {
  final Routine routine;

  const ReorderableSessionList({super.key, required this.routine});

  @override
  ConsumerState<ReorderableSessionList> createState() =>
      _ReorderableSessionListState();
}

class _ReorderableSessionListState
    extends ConsumerState<ReorderableSessionList> {
  late List<Session> sessions;

  @override
  void initState() {
    super.initState();
    sessions = List.from(widget.routine.sessions);
  }

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organize suas sessões',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Arraste as sessões para reorganizar a ordem do seu treino',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
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
    // TODO: Persistir a nova ordem no backend
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
              icon: Icons.edit,
              title: 'Editar',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar edição
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

  void _navigateToSessionDetail(Session session) {
    // Navegar para página de detalhes da sessão
    context.push(
      '/routines/${widget.routine.id}/sessions/${session.id}',
      extra: widget.routine,
    );
  }
}
