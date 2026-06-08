import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../widgets/session_detail_content.dart';
import '../widgets/session_save_button.dart';
import '../widgets/session_screen_styles.dart';
import '../providers/session_editor_state.dart';
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
  bool _isSaving = false;

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
    ref.read(sessionExerciseSelectionNotifierProvider.notifier).clearAll();
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

    final canSave = ref.watch(sessionEditorCanSaveProvider);

    return Scaffold(
      backgroundColor: SessionScreenStyles.screenBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: SessionScreenStyles.divider),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimaryLight,
          onPressed: () => context.pop(),
        ),
        title: Text(
          session != null ? 'Editar sessão' : 'Nova sessão',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          SessionSaveButton(
            enabled: canSave && _externalSave != null,
            isLoading: _isSaving,
            onPressed: canSave && _externalSave != null
                ? () => _externalSave!.call()
                : null,
          ),
        ],
      ),
      body: SessionDetailContent(
        routine: widget.routine,
        session: session,
        sessionNameController: _sessionNameController,
        registerSaveCallback: (fn) => _externalSave = fn,
        onSavingChanged: (isSaving) {
          if (_isSaving != isSaving) {
            setState(() => _isSaving = isSaving);
          }
        },
      ),
    );
  }
}
