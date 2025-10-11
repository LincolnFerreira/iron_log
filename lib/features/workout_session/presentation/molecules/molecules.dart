import 'package:flutter/material.dart';
import '../atoms/atoms.dart';

class WorkoutHeader extends StatelessWidget {
  final String subtitle;
  const WorkoutHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(
              child: Text(
                'Treino de Hoje',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}

class TopTimerCard extends StatelessWidget {
  final String timeText;
  final double progress;
  final VoidCallback onAddSet;
  const TopTimerCard({
    super.key,
    required this.timeText,
    required this.progress,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Tempo de Treino',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeText,
                  style: const TextStyle(
                    color: Color(0xFF0A66C2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ThinProgressBar(value: progress),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '+ Nova Série',
            icon: Icons.add,
            backgroundColor: const Color(0xFF0A66C2),
            onPressed: onAddSet,
          ),
        ],
      ),
    );
  }
}

class ExerciseRow extends StatelessWidget {
  final String name;
  final String progressText;
  final String weightText;
  final String repsText;
  final int count;
  final VoidCallback onIncrement;
  const ExerciseRow({
    super.key,
    required this.name,
    required this.progressText,
    required this.weightText,
    required this.repsText,
    required this.count,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      progressText,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      weightText,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      repsText,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircularCounter(count: count, onTap: onIncrement),
          IconButton(onPressed: () {}, icon: const Icon(Icons.expand_more)),
        ],
      ),
    );
  }
}

class WorkoutSummaryCard extends StatelessWidget {
  final String totalVolume;
  final String topSets;
  final String avgRir;
  const WorkoutSummaryCard({
    super.key,
    required this.totalVolume,
    required this.topSets,
    required this.avgRir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do Treino',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric('Volume Total', totalVolume, const Color(0xFF0A66C2)),
              _metric('Top Sets', topSets, const Color(0xFF1B873E)),
              _metric('RIR Médio', avgRir, const Color(0xFFFB8C00)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
