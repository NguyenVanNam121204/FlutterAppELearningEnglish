import 'package:flutter/material.dart';

class EnrollCourseModal extends StatelessWidget {
  const EnrollCourseModal({
    super.key,
    required this.courseTitle,
    required this.priceLabel,
    required this.onConfirm,
    this.isLoading = false,
  });

  final String courseTitle;
  final String priceLabel;
  final VoidCallback onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D9E6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Đăng ký khóa học',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              courseTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Giá: $priceLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4A5875),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Bạn có chắc chắn muốn đăng ký khóa học này? Sau khi đăng ký, khóa học sẽ được thêm vào danh sách khóa học của bạn.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading ? null : onConfirm,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác nhận đăng ký'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
