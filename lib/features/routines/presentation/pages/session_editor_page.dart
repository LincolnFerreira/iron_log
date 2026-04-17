import 'package:flutter/material.dart';
import 'package:iron_log/core/widgets/page_header_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../widgets/session_detail_content.dart';
import '../providers/session_selection_provider.dart';

class SessionEditorPage extends ConsumerStatefulWidget {
  final Routine routine;
  final String? sessionId;

  const SessionEditorPage({super.key, required this.routine, this.sessionId});

  @override
  ConsumerState<SessionEditorPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionEditorPage> {
  late final TextEditingController _sessionNameController;
  Future<void> Function()? _externalSave;

  @override
  void initState() {
    super.initState();
    final session = widget.sessionId != null
        ? widget.routine.sessions.firstWhere((s) => s.id == widget.sessionId)
        : null;

    _sessionNameController = TextEditingController(text: session?.name ?? '');
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionId != null
        ? widget.routine.sessions.firstWhere(
            (s) => s.id == widget.sessionId,
            orElse: () => throw Exception('Sessão não encontrada'),
          )
        : null;

    final selectedExerciseIds = ref.watch(sessionAllExerciseIdsProvider);
    final hasSelectedExercises = selectedExerciseIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _sessionNameController,
          builder: (context, value, child) {
            final displayName = value.text.trim();
            return PageHeaderTitle(
              title: session != null ? 'Editar Sessão' : 'Nova Sessão',
              subtitle: displayName,
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _sessionNameController,
            builder: (context, value, child) {
              final hasName = value.text.trim().isNotEmpty;
              final canSave =
                  hasSelectedExercises && hasName && _externalSave != null;
              return IconButton(
                color: AppColors.primaryDark,
                icon: const Icon(Icons.save_rounded),
                onPressed: canSave ? () => _externalSave!.call() : null,
                tooltip: 'Salvar Sessão',
              );
            },
          ),
        ],
      ),
      body: SessionDetailContent(
        routine: widget.routine,
        session: session,
        sessionNameController: _sessionNameController,
        registerSaveCallback: (fn) => _externalSave = fn,
      ),
    );
  }
}
