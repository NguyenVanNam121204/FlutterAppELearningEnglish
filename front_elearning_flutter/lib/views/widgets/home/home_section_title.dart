import 'package:flutter/material.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF17213A),
          ),
        ),
        const Spacer(),
        // ignore: use_null_aware_elements
        if (trailing != null) trailing!,
      ],
    );
  }
}
