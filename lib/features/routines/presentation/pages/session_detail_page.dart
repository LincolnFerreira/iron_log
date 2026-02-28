// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../domain/entities/routine.dart';
// import '../widgets/session_detail_content.dart';

// class SessionDetailPage extends ConsumerWidget {
//   final Routine routine;
//   final Session session;

//   const SessionDetailPage({
//     super.key,
//     required this.routine,
//     required this.session,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(session.name),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.pop(),
//         ),
//       ),
//       body: SessionDetailContent(
//         routine: routine,
//         session: session,
//       ),
//     );
//   }
// }
