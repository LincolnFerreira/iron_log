import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/core/services/google_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iron_log/features/auth/presentation/components/molecules/auth_buttons_section.dart';
import 'package:iron_log/features/auth/presentation/components/molecules/login_footer.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo + título lado a lado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 84,
                    height: 84,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Iron Log',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tagline com "Progresso real." em azul
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Registro preciso. ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Progresso real.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 64),

              // Botões de autenticação
              AuthButtonsSection(
                onGoogleSignIn: _signInWithGoogle,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),

              const Spacer(flex: 3),

              // Rodapé
              LoginFooter(
                onCreateAccount: _createAccount,
                onForgotPassword: _forgotPassword,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos de autenticação
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = GoogleAuthService();
      final result = await authService.signInWithGoogle(
        serverClientId:
            '222174717889-qcdugbpqpmebh8j86q2t0rhfjqi48s64.apps.googleusercontent.com',
      );

      if (result == null) return; // user cancelled

      // Após login bem-sucedido, sincroniza/cria o usuário no backend
      final http = ref.read(httpServiceProvider);
      final user = result.user ?? FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await http.post(
            '/user',
            data: {
              'firebaseId': user.uid,
              'email': user.email ?? '',
              'name': user.displayName,
            },
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuário sincronizado com o servidor'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao sincronizar usuário: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no login: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        print('Login error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _createAccount() {
    // Reutiliza o fluxo de login com Google para criar conta
    _signInWithGoogle();
  }

  void _forgotPassword() {
    // TODO: Implementar recuperação de senha
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperação de senha em breve!'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
