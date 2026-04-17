import 'dart:async';

import 'package:flutter/material.dart';

class EnrollmentSuccessEffect extends StatelessWidget {
  const EnrollmentSuccessEffect({super.key, required this.title});

  final String title;

  static Future<void> show(
    BuildContext context, {
    required String title,
  }) async {
    final navigator = Navigator.of(context);
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'enrollment-success',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (navigator.mounted && navigator.canPop()) {
            navigator.pop();
          }
        });
        return Center(child: EnrollmentSuccessEffect(title: title));
      },
      transitionBuilder:
          (transitionContext, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.84, end: 1).animate(curved),
                child: child,
              ),
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDCFCE7),
              border: Border.all(color: const Color(0xFF16A34A), width: 1.4),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 38,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Đăng ký thành công',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
