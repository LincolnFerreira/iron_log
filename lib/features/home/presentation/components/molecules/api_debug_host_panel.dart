import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/env.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/home/presentation/providers/home_provider.dart';

class _Candidate {
  const _Candidate(this.label, this.url);
  final String label;
  final String url;
}

class _Row {
  const _Row({
    required this.label,
    required this.url,
    required this.ok,
    required this.detail,
  });
  final String label;
  final String url;
  final bool ok;
  final String detail;
}

/// Debug-only: testa hosts locais/cloud e aplica o primeiro que responder.
class ApiDebugHostPanel extends ConsumerStatefulWidget {
  const ApiDebugHostPanel({super.key});

  @override
  ConsumerState<ApiDebugHostPanel> createState() => _ApiDebugHostPanelState();
}

class _ApiDebugHostPanelState extends ConsumerState<ApiDebugHostPanel> {
  bool _running = false;
  List<_Row> _rows = const [];
  String? _applied;

  List<_Candidate> get _candidates {
    final map = <String, String>{
      'ADB reverse': 'http://127.0.0.1:3000',
      'Emulador': 'http://10.0.2.2:3000',
      'LAN .22': 'http://192.168.1.22:3000',
      'Cloud': 'https://iron-log-back-end.onrender.com',
      'Env': Env.apiBaseUrl,
    };
    final seen = <String>{};
    return [
      for (final e in map.entries)
        if (seen.add(e.value.replaceAll(RegExp(r'/+$'), '')))
          _Candidate(e.key, e.value.replaceAll(RegExp(r'/+$'), '')),
    ];
  }

  Future<_Row> _probe(_Candidate c) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: c.url,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 5),
        validateStatus: (_) => true,
      ),
    );
    final sw = Stopwatch()..start();
    try {
      final res = await dio.get('/api');
      sw.stop();
      final ok = res.statusCode != null && res.statusCode! < 500;
      return _Row(
        label: c.label,
        url: c.url,
        ok: ok,
        detail: 'HTTP ${res.statusCode} · ${sw.elapsedMilliseconds}ms',
      );
    } catch (e) {
      sw.stop();
      return _Row(
        label: c.label,
        url: c.url,
        ok: false,
        detail: '${sw.elapsedMilliseconds}ms · ${e.toString().split('\n').first}',
      );
    } finally {
      dio.close(force: true);
    }
  }

  Future<void> _testAll() async {
    setState(() {
      _running = true;
      _rows = const [];
      _applied = null;
    });
    final results = await Future.wait(_candidates.map(_probe));
    if (!mounted) return;

    const prefer = [
      'http://127.0.0.1:3000',
      'http://10.0.2.2:3000',
      'http://192.168.1.22:3000',
      'https://iron-log-back-end.onrender.com',
    ];
    _Row? winner;
    for (final url in prefer) {
      for (final r in results) {
        if (r.ok && r.url == url) {
          winner = r;
          break;
        }
      }
      if (winner != null) break;
    }
    winner ??= results.where((r) => r.ok).firstOrNull;

    setState(() {
      _rows = results;
      _running = false;
    });

    if (winner != null) {
      await _use(winner);
    }
  }

  Future<void> _use(_Row row) async {
    HttpService().dio.options.baseUrl = row.url;
    setState(() => _applied = '${row.label} → ${row.url}');
    await ref.read(homeProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final current = HttpService().dio.options.baseUrl;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'API debug — testar todos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              'Atual: $current',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: scheme.primary,
                  ),
            ),
            if (_applied != null) ...[
              const SizedBox(height: 4),
              Text(
                'Aplicado: $_applied',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.tertiary,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _running ? null : _testAll,
              icon: _running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
              label: Text(
                _running ? 'Testando…' : 'Testar todas as alternativas',
              ),
            ),
            if (_rows.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final row in _rows)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    row.ok ? Icons.check_circle : Icons.cancel,
                    color: row.ok ? Colors.green : scheme.error,
                    size: 20,
                  ),
                  title: Text(row.label),
                  subtitle: Text(
                    '${row.url}\n${row.detail}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                  isThreeLine: true,
                  trailing: row.ok
                      ? TextButton(
                          onPressed: () => _use(row),
                          child: const Text('Usar'),
                        )
                      : null,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
