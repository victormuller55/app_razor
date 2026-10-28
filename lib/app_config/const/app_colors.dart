import 'package:flutter/material.dart';

/// Cores do app. As que mudam com o tema são getters que leem [escuro];
/// quem troca o tema ([TemaController]) reconstrói a árvore inteira.
class AppColors {
  /// Modo escuro ativo. Só o controlador de tema deve mudar isso.
  static bool escuro = false;

  static Color _modo(Color claro, Color noEscuro) => escuro ? noEscuro : claro;

  /// Azul da marca, igual nos dois modos (barra inferior, cabeçalhos).
  static const Color primaryBrand = Color(0xFF1C3A5A);

  /// Azul de destaque: no escuro fica mais claro para ler sobre o fundo.
  static Color get primary => _modo(primaryBrand, const Color(0xFF4A7FB8));
  static const Color primaryDark = Color(0xFF12263C);
  static const Color primaryLight = Color(0xFF2E5C8A);
  static const Color secondary = Color(0xFF2A3F55);

  static Color get background =>
      _modo(const Color(0xFFF4F4F6), const Color(0xFF0D0F12));
  static Color get inputBackground =>
      _modo(const Color.fromRGBO(236, 236, 240, 1), const Color(0xFF262A31));

  /// Fundo das telas e folhas (branco no modo claro).
  static Color get surface => _modo(Colors.white, const Color(0xFF15181D));

  static Color get text =>
      _modo(const Color(0xFF1A1A1A), const Color(0xFFECEEF1));
  static Color get textSecondary =>
      _modo(const Color(0xFF5C5C5C), const Color(0xFFA3A9B3));

  static Color get iconMuted => _modo(secondary, const Color(0xFF9DB0C6));
  static Color get border =>
      _modo(const Color(0xFFE0E0E0), const Color(0xFF2C3139));

  /// Divisórias finas e contornos neutros.
  static Color get divisor =>
      _modo(const Color(0xFFE3E6EB), const Color(0xFF2C3139));

  /// Contorno de itens não selecionados (chips, horários, caixas).
  static Color get contorno =>
      _modo(const Color(0xFFD5DAE1), const Color(0xFF3A3F48));

  static Color get loading => primary;

  /// Ícones da barra de status sobre o fundo das telas.
  static Brightness get iconesBarraStatus =>
      escuro ? Brightness.light : Brightness.dark;
  static Brightness get brilhoBarraStatus =>
      escuro ? Brightness.dark : Brightness.light;

  /// Branco puro: conteúdo sobre o azul, sobre fotos e sobre cores sólidas.
  static const Color white = Colors.white;
  static Color get danger => _modo(const Color(0xFFC62828), const Color(0xFFE5484D));

  static Color get statusAberto =>
      _modo(const Color(0xFF157A3F), const Color(0xFF34A867));
  static const Color statusFechado = Color(0xFF9E9E9E);

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [primary, primary],
      );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryBrand, primaryLight],
  );
}
