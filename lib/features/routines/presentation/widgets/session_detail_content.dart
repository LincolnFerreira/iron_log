// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
// import '../../domain/entities/routine.dart';
// import 'selected_exercises_section.dart';
// import '../providers/session_selection_provider.dart';

// class SessionDetailContent extends ConsumerStatefulWidget {
//   final Routine routine;
//   final Session session;

//   const SessionDetailContent({
//     super.key,
//     required this.routine,
//     required this.session,
//   });

//   @override
//   ConsumerState<SessionDetailContent> createState() =>
//       _SessionDetailContentState();
// }

// class _SessionDetailContentState extends ConsumerState<SessionDetailContent> {
//   @override
//   Widget build(BuildContext context) {
//     final selectedExerciseIds = ref.watch(sessionSelectedExerciseIdsProvider);
//     final hasSelectedExercises = selectedExerciseIds.isNotEmpty;

//     return Scaffold(
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Header com botão de busca
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.surface,
//               border: Border(
//                 bottom: BorderSide(
//                   color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
//                   width: 1,
//                 ),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Configurar ${widget.session.name}',
//                         style: Theme.of(context).textTheme.headlineSmall
//                             ?.copyWith(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Selecione os exercícios para esta sessão',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSurface.withOpacity(0.7),
//                         ),
//                       ),
//                       SizedBox(
//                         width: 200,
//                         child: UnifiedExerciseSearch(
//                           hintText: 'Buscar exercícios para adicionar...',
//                           useSearchAnchor: true,
//                           onExerciseSelected: (exercise) {
//                             // Usar o helper para adicionar exercício
//                             ref
//                                 .read(
//                                   sessionExerciseSelectionNotifierProvider
//                                       .notifier,
//                                 )
//                                 .addExercise(exercise);
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Botão de busca usando componente unificado com largura limitada
//               ],
//             ),
//           ),

//           // Exercícios selecionados (ocupa toda a tela restante)
//           Expanded(child: SelectedExercisesSection(session: widget.session)),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: hasSelectedExercises ? _onConcluir : null,
//         icon: const Icon(Icons.check),
//         label: const Text('Concluir'),
//         backgroundColor: hasSelectedExercises
//             ? Theme.of(context).colorScheme.primary
//             : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
//         foregroundColor: hasSelectedExercises
//             ? Theme.of(context).colorScheme.onPrimary
//             : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
//       ),
//     );
//   }

//   void _onConcluir() {
//     // TODO: Salvar configuração da sessão no backend
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Sessão configurada com sucesso!'),
//         duration: Duration(seconds: 2),
//       ),
//     );

//     // Voltar para a tela anterior
//     context.pop();
//   }
// }
