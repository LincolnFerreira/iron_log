import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/features/auth/auth.dart';
import 'package:iron_log/features/auth/presentation/components/molecules/auth_buttons_section.dart';
import 'package:iron_log/features/auth/presentation/components/molecules/login_footer.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.feedback), (
      previous,
      next,
    ) {
      if (next == null) return;
      switch (next.kind) {
        case AuthFeedbackKind.success:
          AppSnackbar.success(
            context: context,
            title: next.title,
            message: next.message,
          );
        case AuthFeedbackKind.warning:
          AppSnackbar.warning(
            context: context,
            title: next.title,
            message: next.message,
          );
        case AuthFeedbackKind.error:
          AppSnackbar.error(
            context: context,
            title: next.title,
            message: next.message,
          );
      }
      ref.read(authControllerProvider.notifier).clearFeedback();
    });

    final isSigningIn = ref.watch(
      authControllerProvider.select((s) => s.isSigningIn),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

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

              AuthButtonsSection(
                onGoogleSignIn: _signInWithGoogle,
                isLoading: isSigningIn,
              ),

              const SizedBox(height: 24),

              const Spacer(flex: 3),

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
    final controller = ref.read(authControllerProvider.notifier);
    final user = await controller.signInWithGoogle();
    if (user == null) return;
    await controller.syncBackendUser(user);
  }

  void _createAccount() {
    _signInWithGoogle();
  }

  void _forgotPassword() {
    AppSnackbar.warning(
      context: context,
      title: 'Em breve',
      message: 'Recuperação de senha em breve!',
    );
  }
}
