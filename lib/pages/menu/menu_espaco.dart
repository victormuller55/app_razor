import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Espaço que o fim das abas do menu precisa deixar livre para a barra de navegação.
///
/// No iOS a barra de vidro fica por cima do conteúdo (Scaffold com `extendBody`), e a altura real dela
/// (com a área do indicador de início) chega pelo `padding.bottom`. No Android a barra já fica
/// fora do corpo e o padding vem zerado, então vale a altura padrão de folga.
double espacoBarraMenu(BuildContext context) {
  return math.max(kBottomNavigationBarHeight, MediaQuery.paddingOf(context).bottom);
}
