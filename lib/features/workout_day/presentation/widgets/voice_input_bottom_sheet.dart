import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/workout_day/presentation/providers/voice_input_provider.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_day_provider.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';

class VoiceInputBottomSheet extends ConsumerStatefulWidget {
  final String? sessionId;
  const VoiceInputBottomSheet({super.key, this.sessionId});

  @override
  ConsumerState<VoiceInputBottomSheet> createState() =>
      _VoiceInputBottomSheetState();
}

class _VoiceInputBottomSheetState extends ConsumerState<VoiceInputBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  final Map<int, List<TextEditingController>> _weightCtrls = {};
  final Map<int, List<TextEditingController>> _repCtrls = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // dispose controllers
    for (final list in _weightCtrls.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in _repCtrls.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  String _formatWeight(double w) {
    return (w % 1 == 0) ? w.toInt().toString() : w.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputProvider);
    final notifier = ref.read(voiceInputProvider.notifier);
    final asyncExercises = ref.read(workoutDayExercisesProvider);
    final sessionExercises = asyncExercises is AsyncData<List<dynamic>>
        ? asyncExercises.value!
        : <dynamic>[];

    final isRecording = state.status == VoiceInputStatus.recording;
    final isTranscribing = state.status == VoiceInputStatus.transcribing;
    final isActive = isRecording || isTranscribing;
    final isContinuous = state.isContinuous;

    // Control pulse animation based on recording state (avoid ref.listen in initState)
    if (isRecording) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gravar entrada por voz',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'IA Assistida',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Simulation / mock buttons kept for testing
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Simular'),
                    onPressed: isActive
                        ? null
                        : () async {
                            await notifier.startRecording(simulate: true);
                          },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_circle),
                    label: const Text('Simular contínuo'),
                    onPressed: isActive
                        ? null
                        : () async {
                            await notifier.startRecording(
                              simulate: true,
                              keepListening: true,
                            );
                          },
                  ),
                ],
              ),

              // Central mic with pulse animation
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (isActive) {
                          await notifier.stopRecording();
                        } else {
                          await notifier.startRecording();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          // prefer real amplitude if present, otherwise fall back to pulse
                          final rawAmp = (state as dynamic).amplitude;
                          double amp = 0.0;
                          if (rawAmp is num) {
                            amp = rawAmp.toDouble();
                            if (amp.isNaN) amp = 0.0;
                            if (amp < 0.0) amp = 0.0;
                            if (amp > 1.0) amp = 1.0;
                          }
                          final pulseFactor =
                              _pulseAnim.value - 1.0; // 0.0..0.12
                          final scale =
                              1.0 +
                              (amp * 0.5) +
                              (amp < 0.02 && isRecording ? pulseFactor : 0.0);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: isRecording
                                    ? Colors.redAccent
                                    : (isTranscribing
                                          ? AppColors.primaryLight
                                          : AppColors.gray20),
                                shape: BoxShape.circle,
                                boxShadow: isRecording
                                    ? [
                                        BoxShadow(
                                          color: Colors.redAccent.withOpacity(
                                            0.25,
                                          ),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                isActive ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRecording
                          ? (isContinuous
                                ? 'Gravando contínuo...'
                                : 'Gravando...')
                          : isTranscribing
                          ? 'Transcrevendo...'
                          : 'Toque para gravar',
                      style: TextStyle(
                        color: isRecording
                            ? Colors.redAccent
                            : AppColors.gray70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Simple waveform bars
                    SizedBox(
                      height: 28,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final base = 6.0 + i * 4.0;
                          // use amplitude to modulate height
                          final rawAmp = (state as dynamic).amplitude;
                          double amp = 0.0;
                          if (rawAmp is num) {
                            amp = rawAmp.toDouble();
                            if (amp.isNaN) amp = 0.0;
                            if (amp < 0.0) amp = 0.0;
                            if (amp > 1.0) amp = 1.0;
                          }
                          final scale = 1.0 + amp * (1.2 + i * 0.2);
                          return Container(
                            width: 6,
                            height: base * scale,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryLight
                                  : AppColors.gray40,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Transcription styled quote
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dark30
                      : AppColors.gray10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.transcript.isEmpty
                      ? 'Nenhuma transcrição ainda'
                      : '"${state.transcript}"',
                  style: TextStyle(
                    fontStyle: state.transcript.isEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                    color: AppColors.gray70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Resolved exercises list (inline)
              if (state.resolved.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Exercícios Identificados',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'IA Assistida',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (ctx, idx) {
                    final resolved = state.resolved[idx];
                    final title =
                        resolved.matchedExerciseName ?? resolved.parsed.name;

                    // ensure controllers exist for this resolved index
                    if (!_weightCtrls.containsKey(idx)) {
                      final wCtrls = <TextEditingController>[];
                      final rCtrls = <TextEditingController>[];
                      for (var s = 0; s < resolved.parsed.weights.length; s++) {
                        final w = resolved.parsed.weights[s];
                        final wText = _formatWeight(w);
                        final rText = (resolved.parsed.reps.length > s)
                            ? resolved.parsed.reps[s].toString()
                            : '';
                        wCtrls.add(TextEditingController(text: wText));
                        rCtrls.add(TextEditingController(text: rText));
                      }
                      _weightCtrls[idx] = wCtrls;
                      _repCtrls[idx] = rCtrls;
                    }

                    final weights = _weightCtrls[idx]!
                        .map((c) => c.text)
                        .join(', ');

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                resolved.isResolved
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : const Icon(
                                        Icons.help_outline,
                                        color: Colors.orange,
                                      ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(title)),
                                const SizedBox(width: 8),
                                if (!resolved.isResolved)
                                  PopupMenuButton<String>(
                                    onSelected: (id) {
                                      final name = sessionExercises
                                          .firstWhere((e) => e.id == id)
                                          .name;
                                      notifier.assignExercise(idx, id, name);
                                    },
                                    itemBuilder: (_) {
                                      final items =
                                          resolved.candidates.isNotEmpty
                                          ? resolved.candidates
                                          : sessionExercises
                                                .map(
                                                  (e) => {
                                                    'id': e.id,
                                                    'name': e.name,
                                                  },
                                                )
                                                .toList();
                                      return items.map<PopupMenuItem<String>>((
                                        c,
                                      ) {
                                        return PopupMenuItem(
                                          value: c['id']!,
                                          child: Text(c['name']!),
                                        );
                                      }).toList();
                                    },
                                    child: const Text('Selecionar'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Séries: $weights ${resolved.parsed.weightUnit}',
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: List.generate(
                                _weightCtrls[idx]!.length,
                                (sIdx) {
                                  final wCtrl = _weightCtrls[idx]![sIdx];
                                  final rCtrl = _repCtrls[idx]![sIdx];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller: wCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Peso',
                                            ),
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: rCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Reps',
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _weightCtrls[idx]!
                                                  .removeAt(sIdx)
                                                  .dispose();
                                              _repCtrls[idx]!
                                                  .removeAt(sIdx)
                                                  .dispose();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemCount: state.resolved.length,
                ),
                const SizedBox(height: 14),
              ],

              // CTA row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        notifier.reRecord();
                        Navigator.of(context).maybePop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.resolved.isEmpty
                          ? null
                          : () async {
                              try {
                                // build overrides from local controllers
                                final overrides = <int, List<SeriesEntry>>{};
                                for (
                                  var idx = 0;
                                  idx < state.resolved.length;
                                  idx++
                                ) {
                                  if (!_weightCtrls.containsKey(idx)) continue;
                                  final wList = _weightCtrls[idx]!;
                                  final rList = _repCtrls[idx]!;
                                  final entries = <SeriesEntry>[];
                                  for (var s = 0; s < wList.length; s++) {
                                    final weightText = wList[s].text.trim();
                                    final repsText = (s < rList.length)
                                        ? rList[s].text.trim()
                                        : '';
                                    entries.add(
                                      SeriesEntry(
                                        index: s,
                                        weight: weightText,
                                        reps: repsText,
                                      ),
                                    );
                                  }
                                  overrides[idx] = entries;
                                }

                                await notifier.applyParsedToInputs(
                                  sessionId: widget.sessionId,
                                  seriesOverrides: overrides,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Campos preenchidos com sucesso',
                                    ),
                                  ),
                                );
                                Navigator.of(context).maybePop();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao aplicar: $e'),
                                  ),
                                );
                              }
                            },
                      child: const Text('Aplicar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: state.resolved.isEmpty
                          ? null
                          : () async {
                              try {
                                // build overrides from local controllers
                                final overrides = <int, List<SeriesEntry>>{};
                                for (
                                  var idx = 0;
                                  idx < state.resolved.length;
                                  idx++
                                ) {
                                  if (!_weightCtrls.containsKey(idx)) continue;
                                  final wList = _weightCtrls[idx]!;
                                  final rList = _repCtrls[idx]!;
                                  final entries = <SeriesEntry>[];
                                  for (var s = 0; s < wList.length; s++) {
                                    final weightText = wList[s].text.trim();
                                    final repsText = (s < rList.length)
                                        ? rList[s].text.trim()
                                        : '';
                                    entries.add(
                                      SeriesEntry(
                                        index: s,
                                        weight: weightText,
                                        reps: repsText,
                                      ),
                                    );
                                  }
                                  overrides[idx] = entries;
                                }

                                // First apply to inputs (auto-fill)
                                await notifier.applyParsedToInputs(
                                  sessionId: widget.sessionId,
                                  seriesOverrides: overrides,
                                );

                                // Then persist
                                await notifier.confirmAndSave(
                                  sessionId: widget.sessionId,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Registro salvo com sucesso'),
                                  ),
                                );
                                Navigator.of(context).maybePop();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro ao salvar: $e')),
                                );
                              }
                            },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
