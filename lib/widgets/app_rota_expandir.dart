import 'package:flutter/material.dart';

/// Abre [tela] por cima de tudo (inclusive da barra de navegação), sem esconder a tela de trás: quem
/// controla a entrada é a própria [tela] (o mapa aparece só depois de desenhado). Na volta, some com fade.
/// Usada depois que o mapa da home já cresceu até a tela inteira.
Future<T?> abrirComFade<T>({
  required BuildContext context,
  required Widget tela,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => tela,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(opacity: animation, child: child);
          },
    ),
  );
}
