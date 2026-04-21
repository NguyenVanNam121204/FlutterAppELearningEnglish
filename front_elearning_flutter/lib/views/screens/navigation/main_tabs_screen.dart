import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';

class MainTabsScreen extends StatelessWidget {
  const MainTabsScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 74,
        elevation: 6,
        backgroundColor: isDark
            ? const Color(0xFF111827)
            : Theme.of(context).colorScheme.surface,
        indicatorColor: isDark
            ? const Color(0xFF93C5FD)
            : const Color(0xFFD6ECFF),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = Theme.of(context).textTheme.labelMedium;
          return base?.copyWith(
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF14213D))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: index,
        onDestinationSelected: (value) {
          navigationShell.goBranch(
            value,
            initialLocation: value == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Khóa học',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Ôn tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book_rounded),
            label: 'Sổ tay',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton.small(
              onPressed: () => context.push(RoutePaths.search),
              child: const Icon(Icons.search),
            )
          : null,
    );
  }
}
