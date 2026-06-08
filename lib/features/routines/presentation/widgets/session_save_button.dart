import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';

class SessionSaveButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  const SessionSaveButton({
    super.key,
    required this.enabled,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isLoading && onPressed != null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: canTap ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: canTap ? AppColors.blue100 : AppColors.gray20,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray20,
          disabledForegroundColor: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Salvar',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
      ),
    );
  }
}
