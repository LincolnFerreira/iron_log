import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/core/widgets/app_error_fallback.dart';

void main() {
  testWidgets('AppErrorFallback shows pt-BR friendly message', (tester) async {
    final details = FlutterErrorDetails(
      exception: Exception('build failed'),
      stack: StackTrace.current,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppErrorFallback(details: details),
      ),
    );

    expect(find.text('Algo deu errado'), findsOneWidget);
    expect(
      find.textContaining('Não foi possível exibir esta parte do app'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
