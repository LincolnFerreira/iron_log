import 'package:flutter/material.dart';
import 'package:iron_log/core/widgets/page_header_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../widgets/session_detail_content.dart';

class SessionDetailPage extends ConsumerStatefulWidget {
  final Routine routine;
  final String? sessionId;

  const SessionDetailPage({super.key, required this.routine, this.sessionId});

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
  late final TextEditingController _sessionNameController;

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
      ),
      body: SessionDetailContent(
        routine: widget.routine,
        session: session,
        sessionNameController: _sessionNameController,
      ),
    );
  }
}
