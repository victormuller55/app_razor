import 'package:app_razor/functions/abrir_link.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Texto de aceite dos termos em que "termos de uso e a política de
/// privacidade" abre a política no navegador dentro do app. O toque no
/// restante do texto segue para quem estiver em volta (marcar o aceite).
class AppTextoTermos extends StatefulWidget {
  final String prefixo;
  final TextStyle style;
  final TextStyle linkStyle;

  const AppTextoTermos({
    super.key,
    required this.prefixo,
    required this.style,
    required this.linkStyle,
  });

  @override
  State<AppTextoTermos> createState() => _AppTextoTermosState();
}

class _AppTextoTermosState extends State<AppTextoTermos> {
  late final TapGestureRecognizer _link = TapGestureRecognizer()
    ..onTap = abrirPoliticaPrivacidade;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: widget.prefixo),
          TextSpan(
            text: 'termos de uso e a política de privacidade',
            style: widget.linkStyle,
            recognizer: _link,
          ),
        ],
      ),
    );
  }
}
