import 'package:flutter/material.dart';

class CatalunyaScaffold extends StatelessWidget {
  const CatalunyaScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : null,
          gradient: isDark
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3FBFF), Color(0xFFF5F9FF), Color(0xFFF8FCFF)],
                ),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}

