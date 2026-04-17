import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/auth/auth_message_banner.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/auth/otp_verifier_form.dart';

class VerifyResetOtpScreen extends ConsumerStatefulWidget {
  const VerifyResetOtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyResetOtpScreen> createState() => _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends ConsumerState<VerifyResetOtpScreen> {
  Future<void> _verify(String code) async {
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .verifyResetOtp(email: widget.email, otpCode: code);
    if (!mounted || !ok) return;
    final email = Uri.encodeComponent(widget.email);
    final otpCode = Uri.encodeComponent(code);
    context.go('${RoutePaths.resetPassword}?email=$email&otpCode=$otpCode');
  }

  Future<void> _resend() async {
    final ok = await ref.read(authViewModelProvider.notifier).forgotPassword(widget.email);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Da gui lai OTP moi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Xac thuc OTP',
      subtitle: 'Nhập mã OTP đã gửi đến ${widget.email}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.errorMessage != null) ...[
            AuthMessageBanner(message: authState.errorMessage!),
            const SizedBox(height: 12),
          ],
          OtpVerifierForm(
            loading: authState.isLoading,
            onVerify: _verify,
            onResend: _resend,
            verifyLabel: 'Tiep tuc',
          ),
        ],
      ),
    );
  }
}

