// TEMP: remover após validar log de erros no back-end (ApiErrorLog).
// Acesso: Configurações → "[TEMP] Teste log API" (só debug).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/core/env.dart';
import 'package:iron_log/core/services/auth_service.dart';

/// Dispara erros HTTP intencionais para validar persistência no servidor.
class TempApiErrorLogTestPage extends StatefulWidget {
  const TempApiErrorLogTestPage({super.key});

  @override
  State<TempApiErrorLogTestPage> createState() =>
      _TempApiErrorLogTestPageState();
}

class _TempApiErrorLogTestPageState extends State<TempApiErrorLogTestPage> {
  final _log = <String>[];
  bool _busy = false;

  void _append(String line) {
    setState(() {
      _log.insert(0, '${DateTime.now().toIso8601String()} — $line');
      if (_log.length > 20) _log.removeLast();
    });
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _append('✓ $label (requisição concluída — veja status abaixo)');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _append('$label → HTTP ${status ?? 'sem status'} (${e.type.name})');
      if (mounted) {
        AppSnackbar.warning(
          context: context,
          title: label,
          message: 'Erro esperado: status ${status ?? e.type.name}',
        );
      }
    } catch (e) {
      _append('$label → falha: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _trigger401NoToken() async {
    final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    await dio.get(ApiEndpoints.routines);
  }

  Future<void> _trigger401BadToken() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {'Authorization': 'Bearer token-invalido-teste'},
      ),
    );
    await dio.get(ApiEndpoints.routines);
  }

  Future<void> _trigger404Authenticated() async {
    await AuthService().get('${ApiEndpoints.routines}/invalid-routine-id-test');
  }

  Future<void> _trigger400BadPayload() async {
    await AuthService().post(ApiEndpoints.workouts, data: {'invalid': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[TEMP] Teste log API'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend: ${Env.apiBaseUrl}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cada botão gera um erro HTTP no servidor. '
                    'Confira a tabela ApiErrorLog (Prisma Studio) ou:\n'
                    'GET /internal/api-error-logs com header X-Ops-Api-Key',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _TestButton(
            label: '401 — sem Authorization',
            onPressed: _busy ? null : () => _run('401 sem token', _trigger401NoToken),
          ),
          _TestButton(
            label: '401 — Bearer inválido',
            onPressed:
                _busy ? null : () => _run('401 token inválido', _trigger401BadToken),
          ),
          _TestButton(
            label: '404 — rotina inexistente (autenticado)',
            onPressed: _busy
                ? null
                : () => _run('404 rotina', _trigger404Authenticated),
          ),
          _TestButton(
            label: '400 — POST /workout payload inválido',
            onPressed:
                _busy ? null : () => _run('400 workout', _trigger400BadPayload),
          ),
          const SizedBox(height: 24),
          Text(
            'Últimos resultados',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_log.isEmpty)
            const Text('Nenhum teste executado ainda.')
          else
            ..._log.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(e, style: const TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
      ),
    );
  }
}
