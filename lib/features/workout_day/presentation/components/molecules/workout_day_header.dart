import 'package:flutter/material.dart';

class WorkoutDayHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onMorePressed;
  final String title;

  const WorkoutDayHeader({
    super.key,
    this.onBackPressed,
    this.onMorePressed,
    //TODO: deveria ser passado o titulo do treino passado pelo usuário, ou o nome do treino do dia
    this.title = 'Exercícios do Dia',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: onMorePressed ?? () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}
