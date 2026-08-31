import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1C3A5A);
  static const Color primaryDark = Color(0xFF12263C);
  static const Color primaryLight = Color(0xFF8B2E2E);
  static const Color secondary = Color(0xFF2A3F55);

  static const Color background = Colors.white;
  static const Color inputBackground = Color.fromRGBO(236, 236, 240, 1);

  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5C5C5C);

  static const Color iconMuted = secondary;
  static const Color border = Color(0xFFE0E0E0);
  static const Color loading = primary;
  static const Color white = Colors.white;
  static const Color danger = Color(0xFFC62828);

  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );

  static const Color statusAberto = Color(0xFF157A3F);
  static const Color statusFechado = Color(0xFF9E9E9E);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primary],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );
}
