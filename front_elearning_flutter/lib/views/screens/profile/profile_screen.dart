import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../core/result/result.dart';
import '../../../models/user/user_model.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_reveal.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/profile/profile_action_tile.dart';
import '../../widgets/profile/profile_header_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUpdatingAvatar = false;
  bool _isSaving = false;

  Future<void> _showChangePasswordDialog() async {
    final rootContext = context;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Đổi mật khẩu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                      ),
                    ),
                    if ((errorText ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final currentPassword = currentCtrl.text.trim();
                          final newPassword = newCtrl.text.trim();
                          final confirm = confirmCtrl.text.trim();

                          if (currentPassword.isEmpty ||
                              newPassword.isEmpty ||
                              confirm.isEmpty) {
                            setStateDialog(() {
                              errorText = 'Vui lòng nhập đầy đủ thông tin.';
                            });
                            return;
                          }
                          if (newPassword.length < 6) {
                            setStateDialog(() {
                              errorText = 'Mật khẩu mới tối thiểu 6 ký tự.';
                            });
                            return;
                          }
                          if (newPassword != confirm) {
                            setStateDialog(() {
                              errorText = 'Mật khẩu xác nhận không khớp.';
                            });
                            return;
                          }

                          setState(() => _isSaving = true);
                          final result = await ref
                              .read(profileFeatureViewModelProvider)
                              .changePassword(
                                currentPassword: currentPassword,
                                newPassword: newPassword,
                              );
                          setState(() => _isSaving = false);

                          if (!mounted) return;
                          if (!rootContext.mounted) return;
                          switch (result) {
                            case Success<void>():
                              Navigator.of(rootContext).pop();
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Đổi mật khẩu thành công'),
                                ),
                              );
                            case Failure<void>(:final error):
                              setStateDialog(() {
                                errorText = error.message;
                              });
                          }
                        },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showUpdateProfileDialog(UserModel currentUser) async {
    final rootContext = context;
    final firstNameCtrl = TextEditingController(
      text: currentUser.firstName ?? '',
    );
    final lastNameCtrl = TextEditingController(
      text: currentUser.lastName ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: currentUser.phoneNumber ?? '',
    );
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Chỉnh sửa thông tin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Họ'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                    ),
                    if ((errorText ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final firstName = firstNameCtrl.text.trim();
                          final lastName = lastNameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();

                          if (firstName.isEmpty || lastName.isEmpty) {
                            setStateDialog(() {
                              errorText = 'Tên và họ không được để trống.';
                            });
                            return;
                          }

                          setState(() => _isSaving = true);
                          final result = await ref
                              .read(profileFeatureViewModelProvider)
                              .updateProfile(
                                firstName: firstName,
                                lastName: lastName,
                                phoneNumber: phone,
                              );
                          setState(() => _isSaving = false);

                          if (!mounted) return;
                          if (!rootContext.mounted) return;
                          switch (result) {
                            case Success<UserModel>():
                              ref.invalidate(profileDataProvider);
                              await ref
                                  .read(authViewModelProvider.notifier)
                                  .refreshProfile(silent: true);
                              if (!mounted) return;
                              if (!rootContext.mounted) return;
                              Navigator.of(rootContext).pop();
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cập nhật thông tin thành công',
                                  ),
                                ),
                              );
                            case Failure<UserModel>(:final error):
                              setStateDialog(() {
                                errorText = error.message;
                              });
                          }
                        },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (file == null) return;

    final fileSize = await file.length();
    const maxAvatarSize = 2 * 1024 * 1024;
    if (fileSize > maxAvatarSize) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kích thước ảnh không được vượt quá 2MB.'),
        ),
      );
      return;
    }

    setState(() => _isUpdatingAvatar = true);
    final result = await ref
        .read(profileFeatureViewModelProvider)
        .updateAvatar(filePath: file.path, fileName: file.name);
    setState(() => _isUpdatingAvatar = false);

    if (!mounted) return;
    switch (result) {
      case Success<UserModel>():
        ref.invalidate(profileDataProvider);
        await ref
            .read(authViewModelProvider.notifier)
            .refreshProfile(silent: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật avatar thành công')),
        );
      case Failure<UserModel>(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final asyncProfile = ref.watch(profileDataProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (!authState.isAuthenticated) {
      return CatalunyaScaffold(
        appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
        body: Center(
          child: CatalunyaCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmptyStateView(
                  message: 'Bạn cần đăng nhập để xem tài khoản',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(RoutePaths.login),
                  child: const Text('Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: asyncProfile.when(
        data: (user) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          final bottomNavSafePadding = bottomInset + 74 + 20;
          final joinedRoles = user.roles.isEmpty
              ? (user.role ?? '-')
              : user.roles.join(', ');

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomNavSafePadding),
            children: [
              CatalunyaReveal(
                child: ProfileHeaderCard(
                  user: user,
                  onEditAvatar: _pickAndUploadAvatar,
                  isUpdatingAvatar: _isUpdatingAvatar,
                ),
              ),
              const SizedBox(height: 12),
              CatalunyaReveal(
                delay: const Duration(milliseconds: 80),
                child: ProfileActionTile(
                  title: 'Họ tên',
                  subtitle: user.displayName,
                  icon: Icons.person_rounded,
                  onTap: () => _showUpdateProfileDialog(user),
                ),
              ),
              CatalunyaReveal(
                delay: const Duration(milliseconds: 130),
                child: ProfileActionTile(
                  title: 'Email',
                  subtitle: user.email,
                  icon: Icons.email_rounded,
                  onTap: () {},
                ),
              ),
              CatalunyaReveal(
                delay: const Duration(milliseconds: 180),
                child: ProfileActionTile(
                  title: 'Vai trò',
                  subtitle: joinedRoles,
                  icon: Icons.badge_rounded,
                  onTap: () {},
                ),
              ),
              if ((user.phoneNumber ?? '').trim().isNotEmpty)
                CatalunyaReveal(
                  delay: const Duration(milliseconds: 220),
                  child: ProfileActionTile(
                    title: 'Số điện thoại',
                    subtitle: user.phoneNumber,
                    icon: Icons.phone_rounded,
                    onTap: () => _showUpdateProfileDialog(user),
                  ),
                ),
              CatalunyaReveal(
                delay: const Duration(milliseconds: 280),
                child: ProfileActionTile(
                  title: 'Đổi mật khẩu',
                  subtitle: 'Cập nhật mật khẩu tài khoản',
                  icon: Icons.key_rounded,
                  onTap: _showChangePasswordDialog,
                ),
              ),
              CatalunyaReveal(
                delay: const Duration(milliseconds: 310),
                child: ProfileActionTile(
                  title: 'Nâng cấp tài khoản',
                  subtitle: 'Mở thêm quyền lợi Premium',
                  icon: Icons.workspace_premium_rounded,
                  onTap: () => context.push(RoutePaths.pro),
                ),
              ),
              CatalunyaReveal(
                delay: const Duration(milliseconds: 325),
                child: ProfileActionTile(
                  title: 'Chế độ tối',
                  subtitle: 'Đổi giao diện sang nền tối',
                  icon: themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (isDark) {
                      ref.read(themeModeProvider.notifier).toggleTheme(isDark);
                    },
                  ),
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .toggleTheme(themeMode != ThemeMode.dark);
                  },
                ),
              ),
              const SizedBox(height: 14),
              CatalunyaReveal(
                delay: const Duration(milliseconds: 340),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authViewModelProvider.notifier).logout();
                    if (!context.mounted) return;
                    context.go(RoutePaths.login);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}
