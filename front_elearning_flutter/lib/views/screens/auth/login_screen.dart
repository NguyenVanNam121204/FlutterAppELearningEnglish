import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/auth/auth_message_banner.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_shell.dart';
import '../../widgets/auth/auth_switch_link.dart';
import '../../widgets/auth/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authViewModelProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return AuthShell(
      title: 'Chào mừng trở lại',
      subtitle: 'Đăng nhập để tiếp tục hành trình học tiếng Anh.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authState.errorMessage != null) ...[
              AuthMessageBanner(message: authState.errorMessage!),
              const SizedBox(height: 14),
            ],
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@gmail.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập email';
                }
                const pattern = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';
                if (!RegExp(pattern).hasMatch(value.trim())) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hint: 'Nhập mật khẩu của bạn',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(color: Color(0xFF5E6A80)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(RoutePaths.forgotPassword),
                  child: const Text('Quên mật khẩu?'),
                ),
              ],
            ),
            AuthPrimaryButton(
              label: 'Đăng nhập',
              isLoading: authState.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            AuthSwitchLink(
              question: 'Chưa có tài khoản?',
              actionLabel: 'Đăng ký',
              onTap: () => context.go(RoutePaths.register),
            ),
          ],
        ),
      ),
    );
  }
}
