import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iron_log/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:iron_log/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:iron_log/features/auth/domain/usecases/login_usecase.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          // Remova o getIt e crie a instância diretamente
          create: (context) => AuthBloc(
            loginUseCase: LoginUseCase(
              AuthRepositoryImpl(
                remoteDataSource: AuthRemoteDataSourceImpl(dio: Dio()),
              ),
            ),
          ),
          child: const LoginView(),
        ),
      ),
    );
  }
}
