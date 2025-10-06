import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/repositories/routine_repository_impl.dart';
import 'domain/repositories/routine_repository.dart';
import 'presentation/bloc/routine_provider.dart';

// Provider para o Dio configurado
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  // Para emulador Android: 10.0.2.2 é o alias para localhost do host
  // Para iOS Simulator: localhost funciona
  // Para dispositivo físico: use o IP da máquina host
  dio.options.baseUrl = 'http://10.0.2.2:3000';
  dio.options.headers.addAll({
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  });

  // Adicionar interceptor para token de autenticação
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // Silenciar erros de token
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

// Provider para o repositório
final routineRepositoryProviderImpl = Provider<RoutineRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RoutineRepositoryImpl(dio);
});

// Override do provider abstrato
final routineRepositoryOverride = routineRepositoryProvider.overrideWith(
  (ref) => ref.watch(routineRepositoryProviderImpl),
);

// Lista de overrides para configurar os providers
final routineProvidersOverrides = [routineRepositoryOverride];
