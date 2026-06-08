import 'package:flutter/material.dart';
import 'google_icon.dart';
import '../../auth_test_keys.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        key: AuthTestKeys.googleSignIn,
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[700],
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          disabledBackgroundColor: Colors.grey[100],
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[600],
                ),
              )
            : Row(
                children: [
                  const GoogleIcon(size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Continuar com Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[500]),
                ],
              ),
      ),
    );
  }
}
