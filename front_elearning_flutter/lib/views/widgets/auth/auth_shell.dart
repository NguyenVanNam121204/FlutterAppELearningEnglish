import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerIcon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData? headerIcon;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F9FF), Color(0xFFF8F6FF), Color(0xFFFDF2F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: -120,
                top: -120,
                child: _BlurBlob(
                  size: screenWidth < 600 ? 260 : 340,
                  colors: const [Color(0xFF6FD5E0), Color(0xFF5BC0EB)],
                ),
              ),
              Positioned(
                right: -110,
                bottom: -130,
                child: _BlurBlob(
                  size: screenWidth < 600 ? 260 : 360,
                  colors: const [Color(0xFFF472B6), Color(0xFFEC4899)],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 600 ? 22 : 30,
                        vertical: screenWidth < 600 ? 24 : 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE5EAF3)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x240F172A),
                            blurRadius: 36,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (headerIcon != null) ...[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF41D6E3),
                                    Color(0xFF06B6D4),
                                  ],
                                ),
                              ),
                              child: Icon(
                                headerIcon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF171A26),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: const Color(0xFF5C6881),
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
        ),
      ),
    );
  }
}
