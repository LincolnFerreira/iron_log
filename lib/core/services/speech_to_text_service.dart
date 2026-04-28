import 'dart:async';
import 'dart:math';

import 'package:speech_to_text/speech_to_text.dart';

/// Lightweight wrapper around `speech_to_text` exposing a simple stream
/// of partial/final transcription results. Supports an optional simulation
/// mode that emits a predetermined transcript instead of using the device
/// microphone (useful for local testing).
class SpeechResult {
  final String text;
  final bool isFinal;

  SpeechResult({required this.text, required this.isFinal});
}

class SpeechToTextService {
  final SpeechToText _speech = SpeechToText();
  final StreamController<SpeechResult> _controller =
      StreamController.broadcast();
  final StreamController<double> _levelController =
      StreamController.broadcast();
  bool _initialized = false;

  // Simulation configuration
  final bool simulate;
  final String? simulationText;
  final List<Timer> _simTimers = [];
  bool _simFinalEmitted = false;

  SpeechToTextService({this.simulate = false, this.simulationText});

  /// Stream of transcription events (partial + final).
  Stream<SpeechResult> get onResult => _controller.stream;

  /// Stream of sound level (amplitude) values emitted while listening.
  Stream<double> get onSoundLevel => _levelController.stream;

  bool get isInitialized => _initialized;

  static const String _defaultSimulationText =
      'supino reto comecei com 20 quilos fiz 15 repetições de aquecimento depois fui pra 40 fiz 10 depois 60 fiz 6 e finalizei com 80 fiz 5 senti um leve desconforto no ombro';

  /// Initializes the underlying plugin. Returns true if available.
  Future<bool> init() async {
    try {
      if (simulate) {
        _initialized = true;
      } else {
        _initialized = await _speech.initialize(
          onStatus: (status) {},
          onError: (err) {},
        );
      }
    } catch (e) {
      _initialized = false;
    }
    return _initialized;
  }

  /// Starts listening and emits partial/final results through [onResult].
  /// Default locale is pt_BR.
  Future<void> startListening({
    String localeId = 'pt_BR',
    Duration? listenFor,
    bool keepListening = false,
  }) async {
    if (!_initialized) await init();
    if (!_initialized) return;

    if (simulate) {
      _startSimulation(keepListening: keepListening);
      return;
    }

    // If keepListening is requested, use a very long timeout to avoid
    // auto-stopping during pauses. Using 1 hour is a pragmatic choice.
    final effectiveListenFor = keepListening
        ? const Duration(hours: 1)
        : (listenFor ?? const Duration(seconds: 60));

    await _speech.listen(
      onResult: (result) {
        _controller.add(
          SpeechResult(
            text: result.recognizedWords,
            isFinal: result.finalResult,
          ),
        );
      },
      onSoundLevelChange: (level) {
        try {
          _levelController.add(level);
        } catch (_) {}
      },
      localeId: localeId,
      listenFor: effectiveListenFor,
      partialResults: true,
      cancelOnError: true,
    );
  }

  void _startSimulation({required bool keepListening}) {
    // Cancel any previous simulation timers
    for (final t in _simTimers) {
      t.cancel();
    }
    _simTimers.clear();
    _simFinalEmitted = false;

    final fullText = simulationText ?? _defaultSimulationText;
    final words = fullText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // Emit a few progressive partial updates and then a final result.
    final updates = min(5, max(1, (words.length / 6).ceil())); // ~5 updates
    final chunkSize = (words.length / updates).ceil();

    for (var i = 0; i < updates; i++) {
      final end = min((i + 1) * chunkSize, words.length);
      final partial = words.sublist(0, end).join(' ');
      // schedule partial updates spaced by 300ms
      final t = Timer(Duration(milliseconds: 300 * (i + 1)), () {
        _controller.add(SpeechResult(text: partial, isFinal: false));
        // emit a random sound level for the UI
        try {
          _levelController.add(Random().nextDouble() * 12.0);
        } catch (_) {}
      });
      _simTimers.add(t);
    }

    final finalTimer = Timer(Duration(milliseconds: 300 * (updates + 1)), () {
      _controller.add(SpeechResult(text: fullText, isFinal: true));
      // emit a short sequence of levels to simulate ending
      try {
        _levelController.add(6.0);
        Timer(
          const Duration(milliseconds: 100),
          () => _levelController.add(0.0),
        );
      } catch (_) {}
      _simFinalEmitted = true;
    });
    _simTimers.add(finalTimer);
  }

  Future<void> stopListening() async {
    try {
      if (simulate) {
        // If final text hasn't been emitted yet, emit it now
        if (!_simFinalEmitted) {
          final fullText = simulationText ?? _defaultSimulationText;
          _controller.add(SpeechResult(text: fullText, isFinal: true));
          _simFinalEmitted = true;
        }
        for (final t in _simTimers) {
          t.cancel();
        }
        _simTimers.clear();
        // reset level to zero
        try {
          _levelController.add(0.0);
        } catch (_) {}
        return;
      }
      await _speech.stop();
      try {
        _levelController.add(0.0);
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      if (simulate) {
        for (final t in _simTimers) {
          t.cancel();
        }
        _simTimers.clear();
        try {
          _levelController.add(0.0);
        } catch (_) {}
        return;
      }
      await _speech.cancel();
    } catch (_) {}
  }

  void dispose() {
    for (final t in _simTimers) {
      t.cancel();
    }
    _simTimers.clear();
    try {
      _controller.close();
    } catch (_) {}
    try {
      _levelController.close();
    } catch (_) {}
    try {
      _speech.cancel();
    } catch (_) {}
  }
}
