import 'package:iron_log/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> login(String email, String password) {
    throw remoteDataSource.login(email, password);
  }
}
