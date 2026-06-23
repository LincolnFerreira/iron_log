import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout_draft.dart';
import '../providers/workout_draft_providers.dart';

class PendingWorkoutDraftsSheet extends ConsumerWidget {
  const PendingWorkoutDraftsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PendingWorkoutDraftsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingWorkoutDraftsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treinos pendentes de envio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e'),
              data: (drafts) {
                if (drafts.isEmpty) {
                  return const Text('Nenhum treino pendente.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: drafts.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final draft = drafts[index];
                    return ListTile(
                      title: Text(
                        'Treino ${draft.startedAt.toLocal()}'.split('.').first,
                      ),
                      subtitle: Text(_statusLabel(draft)),
                      trailing: IconButton(
                        icon: const Icon(Icons.cloud_upload_outlined),
                        onPressed: () async {
                          await ref
                              .read(workoutDraftSyncServiceProvider)
                              .flushPendingUploads();
                          ref.invalidate(pendingWorkoutDraftsProvider);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(WorkoutDraft draft) {
    if (draft.lastErrorStatusCode != null) {
      return 'Última falha: HTTP ${draft.lastErrorStatusCode}';
    }
    return 'Aguardando envio';
  }
}
