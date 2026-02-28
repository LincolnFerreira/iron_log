import 'package:flutter/material.dart';
import '../atoms/google_signin_button.dart';

class AuthButtonsSection extends StatelessWidget {
  final VoidCallback? onGoogleSignIn;
  final bool isLoading;

  const AuthButtonsSection({
    super.key,
    required this.onGoogleSignIn,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GoogleSignInButton(onPressed: onGoogleSignIn, isLoading: isLoading),
      ],
    );
  }
}
