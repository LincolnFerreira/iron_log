import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/routine.dart';
import '../widgets/reorderable_session_list.dart';

class SessionEditPage extends ConsumerWidget {
  final Routine routine;

  const SessionEditPage({super.key, required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text('Editar ${routine.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ReorderableSessionList(routine: routine),
    );
  }
}
