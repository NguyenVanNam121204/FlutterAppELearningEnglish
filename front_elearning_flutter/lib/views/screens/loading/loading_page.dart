import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';

class LoadingPage extends ConsumerStatefulWidget {
  const LoadingPage({super.key});

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await _checkAndNavigate();
    });
  }

  Future<void> _checkAndNavigate() async {
    setState(() => _checking = true);
    final result = await ref
        .read(learningFeatureViewModelProvider)
        .pingSystemCourses();
    if (!mounted) return;
    setState(() => _checking = false);
    if (result is Success<dynamic>) {
      context.go(RoutePaths.mainAppHome);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loi ket noi server'),
        content: const Text(
          'Không thể kết nối đến server. Thử lại hoặc vào app tạm để test UI.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkAndNavigate();
            },
            child: const Text('Thu lai'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RoutePaths.mainAppHome);
            },
            child: const Text('Vao offline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(_checking ? 'Đang kiểm tra kết nối...' : 'Đang khởi động...'),
          ],
        ),
      ),
    );
  }
}
