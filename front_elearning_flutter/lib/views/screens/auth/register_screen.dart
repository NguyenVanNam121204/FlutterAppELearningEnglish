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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _dateOfBirthError;
  String _gender = 'male';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    var isValid = _formKey.currentState!.validate();
    if (_dateOfBirth == null) {
      setState(() => _dateOfBirthError = 'Vui lòng chọn ngày sinh');
      isValid = false;
    }
    if (!isValid) return;
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          isMale: _gender == 'male',
          dateOfBirth: _dateOfBirth,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công. Vui lòng xác thực email.'),
        ),
      );
      final email = Uri.encodeComponent(_emailController.text.trim());
      context.go('${RoutePaths.verifyEmailOtp}?email=$email');
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _dateOfBirth = selected;
        _dateOfBirthError = null;
      });
    }
  }

  String _dobLabel() {
    final d = _dateOfBirth;
    if (d == null) return 'Chọn ngày sinh';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Taọ tài khoản của bạn',
      subtitle: 'Bắt đầu hành trình học tiếng Anh ngay hôm nay.',
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
              controller: _firstNameController,
              label: 'Họ',
              hint: 'Nguyen',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _lastNameController,
              label: 'Tên',
              hint: 'Van A',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên';
                return null;
              },
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hint: 'Tối thiểu 6 ký tự',
              obscureText: true,
              validator: (v) {
                final p = (v ?? '').trim();
                if (p.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (p.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu',
              hint: 'Nhập lại mật khẩu',
              obscureText: true,
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return 'Vui lòng nhập lại mật khẩu';
                }
                if (v!.trim() != _passwordController.text.trim()) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hint: '0xxxxxxxxx',
              keyboardType: TextInputType.phone,
              validator: (v) {
                final phone = (v ?? '').trim();
                if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
                if (!RegExp(r'^[0-9]{9,11}$').hasMatch(phone)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDateOfBirth,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_dobLabel()),
            ),
            if (_dateOfBirthError != null) Text(_dateOfBirthError!),
            const SizedBox(height: 14),
            RadioGroup<String>(
              groupValue: _gender,
              onChanged: (v) => setState(() => _gender = v ?? 'male'),
              child: const Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'male',
                      title: Text('Nam'),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'female',
                      title: Text('Nữ'),
                    ),
                  ),
                ],
              ),
            ),
            AuthPrimaryButton(
              label: 'Đăng ký',
              isLoading: authState.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            AuthSwitchLink(
              question: 'Đã có tài khoản?',
              actionLabel: 'Đăng nhập',
              onTap: () => context.go(RoutePaths.login),
            ),
          ],
        ),
      ),
    );
  }
}
