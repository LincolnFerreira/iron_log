import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/routine.dart';
import '../widgets/session_detail_content.dart';

class SessionDetailPage extends ConsumerWidget {
  final Routine routine;
  final String? sessionId;

  const SessionDetailPage({super.key, required this.routine, this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = sessionId != null
        ? routine.sessions.firstWhere(
            (s) => s.id == sessionId,
            orElse: () => throw Exception('Sessão não encontrada'),
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(session != null ? 'Editar Sessão' : 'Nova Sessão'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SessionDetailContent(routine: routine, session: session),
    );
  }
}
