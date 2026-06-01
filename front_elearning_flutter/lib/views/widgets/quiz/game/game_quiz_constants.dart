import 'package:flutter/material.dart';

class GameQuizColors {
  static const Color background = Color(0xFF0F0C29);
  static const Color surface = Color(0xFF1B1B3A);
  static const Color primary = Color(0xFF7B61FF); // Neon Violet
  static const Color secondary = Color(0xFF00F0FF); // Neon Blue

  static const Color correct = Color(0xFF00FF94); // Neon Green
  static const Color incorrect = Color(0xFFFF3D71); // Neon Red

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A0C0);

  static List<Color> bgGradient = [
    const Color(0xFF0F0C29),
    const Color(0xFF302B63),
    const Color(0xFF24243E),
  ];
}

class GameQuizStyles {
  static BoxDecoration glassDecoration({
    Color? color,
    double opacity = 0.1,
    double blur = 10,
    double borderRadius = 16,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (borderColor ?? Colors.white).withValues(alpha: 0.2),
        width: 1.5,
      ),
    );
  }

  static List<BoxShadow> neonShadow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.5),
        blurRadius: 12,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 20,
        spreadRadius: 4,
      ),
    ];
  }
}
