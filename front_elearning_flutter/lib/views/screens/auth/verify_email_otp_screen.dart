import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/auth/auth_message_banner.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/auth/otp_verifier_form.dart';

class VerifyEmailOtpScreen extends ConsumerStatefulWidget {
  const VerifyEmailOtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyEmailOtpScreen> createState() => _VerifyEmailOtpScreenState();
}

class _VerifyEmailOtpScreenState extends ConsumerState<VerifyEmailOtpScreen> {
  Future<void> _submit(String otpCode) async {
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .verifyEmailOtp(email: widget.email, otpCode: otpCode);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Xac thuc email thanh cong')),
    );
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Xac thuc email',
      subtitle: 'Nhập mã OTP 6 số đã gửi đến ${widget.email}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.errorMessage != null) ...[
            AuthMessageBanner(message: authState.errorMessage!),
            const SizedBox(height: 12),
          ],
          OtpVerifierForm(
            loading: authState.isLoading,
            onVerify: _submit,
            verifyLabel: 'Xac minh',
          ),
        ],
      ),
    );
  }
}

