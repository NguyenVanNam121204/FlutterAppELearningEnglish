import 'package:flutter/material.dart';

import '../common/catalunya_card.dart';

class SearchQueryBar extends StatelessWidget {
  const SearchQueryBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearchTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return CatalunyaCard(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Nhập tên khóa học...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search_rounded),
              ),
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onSearchTap,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }
}
