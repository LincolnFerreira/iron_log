import 'package:flutter/material.dart';

class LoginFooter extends StatelessWidget {
  final VoidCallback? onCreateAccount;
  final VoidCallback? onForgotPassword;

  const LoginFooter({super.key, this.onCreateAccount, this.onForgotPassword});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Links de ação
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onCreateAccount,
              child: Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 14,
              color: Colors.grey[400],
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            TextButton(
              onPressed: onForgotPassword,
              child: Text(
                'Esqueci a senha',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Termos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
