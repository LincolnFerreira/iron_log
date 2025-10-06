import 'package:flutter/material.dart';
import '../molecules/metodology_card.dart';

class MetodologyList extends StatelessWidget {
  final int? groupValue;
  final ValueChanged<int?> onChanged;

  const MetodologyList({
    super.key,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MetodologyCard(
          title: 'Progressão Linear por Série',
          description:
              'Aumenta a carga a cada série, reduzindo repetições (ex.: 12 reps – carga X, 10 reps – carga X+2kg)',
          value: 1,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        MetodologyCard(
          title: "Carga Fixa",
          description:
              "Usa a mesma carga em todas as séries, mantendo repetições próximas (ex.: 4×10 com 40kg)",
          value: 2,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        MetodologyCard(
          title: "Top Set e Séries Reduzidas",
          description:
              "1 série pesada próxima à falha, seguida de séries com carga reduzida",
          value: 3,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        MetodologyCard(
          title: "Pirâmide Reversa",
          description:
              "Começa com série mais pesada, reduz carga e aumenta repetições",
          value: 4,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        MetodologyCard(
          title: "Pirâmide Tradicional",
          description:
              "Começa leve com mais reps, aumenta carga e diminui repetições",
          value: 5,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        MetodologyCard(
          title: "Progressão Dupla",
          description:
              "Mantém carga até atingir topo da faixa, então aumenta carga",
          value: 6,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        MetodologyCard(
          title: "Repetições na Reserva (RIR)",
          description:
              "Para com repetições \"sobrando\" antes da falha (ex.: RIR 2)",
          value: 7,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
