import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/auth/auth_message_banner.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/auth/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .forgotPassword(_emailController.text.trim());
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mã OTP đã được gửi. Vui lòng kiểm tra email.'),
      ),
    );
    final email = Uri.encodeComponent(_emailController.text.trim());
    context.go('${RoutePaths.verifyResetOtp}?email=$email');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Quên mật khẩu',
      subtitle: 'Nhập email để nhận hướng dẫn đặt lại mật khẩu.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authState.errorMessage != null) ...[
              AuthMessageBanner(message: authState.errorMessage!),
              const SizedBox(height: 12),
            ],
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@gmail.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Vui lòng nhập email';
                final ok = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(email);
                if (!ok) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Gửi mã OTP',
              isLoading: authState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
