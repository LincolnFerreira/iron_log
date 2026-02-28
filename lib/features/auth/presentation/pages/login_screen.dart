import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iron_log/features/auth/presentation/components/atoms/app_icon_widget.dart';
import 'package:iron_log/features/auth/presentation/components/molecules/auth_buttons_section.dart';
import 'package:iron_log/features/auth/presentation/components/molecules/login_footer.dart';
import 'package:iron_log/features/auth/presentation/components/molecules/title_section.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

              // Ícone do app
              const AppIconWidget(),

              const SizedBox(height: 48),

              // Título e tagline
              const TitleSection(),

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

  Widget _buildAppIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.fitness_center, size: 40, color: Colors.white),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
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
        const SizedBox(height: 8),
        Text(
          'Registro preciso. Progresso real.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // Métodos de autenticação
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
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
    // TODO: Implementar criação de conta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Criação de conta em breve!'),
        backgroundColor: Colors.green,
      ),
    );
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
