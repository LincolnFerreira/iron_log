import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/auth/auth.dart';
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final controller = ref.read(authControllerProvider.notifier);
    try {
      final user = await controller.signInWithGoogle();
      if (user == null) return; // user cancelled

      try {
        await controller.syncBackendUser(user);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no login: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
