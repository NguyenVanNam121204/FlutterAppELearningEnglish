import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/auth/auth_message_banner.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/auth/auth_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otpCode,
  });
  final String email;
  final String otpCode;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .setNewPassword(
          email: widget.email,
          otpCode: widget.otpCode,
          newPassword: _passwordController.text.trim(),
          confirmPassword: _confirmController.text.trim(),
        );
    if (!mounted || !ok) return;
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Đặt lại mật khẩu',
      subtitle: 'Tạo mật khẩu mới cho tài khoản ${widget.email}',
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
              controller: _passwordController,
              label: 'Mật khẩu mới',
              hint: 'Nhập mật khẩu mới',
              obscureText: true,
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 8) return 'Mật khẩu tối thiểu 8 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmController,
              label: 'Xác nhận mật khẩu',
              hint: 'Nhập lại mật khẩu',
              obscureText: true,
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) return 'Vui lòng nhập lại mật khẩu';
                if (v != _passwordController.text.trim()) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Đặt lại mật khẩu',
              isLoading: authState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
