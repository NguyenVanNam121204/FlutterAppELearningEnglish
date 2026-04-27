import 'package:flutter/material.dart';

class QuizQuestionStyles {
  const QuizQuestionStyles._();

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : Colors.white;
  }

  static Color cardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);
  }

  static Color subtleBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
  }

  static Color infoBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF102A43)
        : const Color(0xFFEFF6FF);
  }

  static Color activeBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B3B76)
        : const Color(0xFFEFF6FF);
  }

  static Color successBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF064E3B)
        : const Color(0xFFECFDF5);
  }
}
