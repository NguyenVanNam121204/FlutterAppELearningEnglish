import 'package:flutter/material.dart';

import '../common/empty_state_view.dart';

class SearchFeedbackPanel extends StatelessWidget {
  const SearchFeedbackPanel({
    super.key,
    required this.message,
    required this.icon,
    this.topSpacing = 120,
  });

  final String message;
  final IconData icon;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: topSpacing),
        EmptyStateView(message: message, icon: icon),
      ],
    );
  }
}
