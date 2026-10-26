import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Faz o filho "tremer" para os lados, usado quando um passo é inválido.
class CadastroTremor extends StatefulWidget {
  final Widget child;

  const CadastroTremor({super.key, required this.child});

  @override
  State<CadastroTremor> createState() => CadastroTremorState();
}

class CadastroTremorState extends State<CadastroTremor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  void tremer() {
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final double t = _controller.value;
        final double dx = math.sin(t * math.pi * 5) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
