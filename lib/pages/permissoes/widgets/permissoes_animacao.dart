import 'dart:math' as math;

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:flutter/material.dart';

/// Pin de localização "quicando" com ondas saindo do chão, em loop.
class PermissoesAnimacao extends StatefulWidget {
  const PermissoesAnimacao({super.key, this.size = 160});

  final double size;

  @override
  State<PermissoesAnimacao> createState() => _PermissoesAnimacaoState();
}

class _PermissoesAnimacaoState extends State<PermissoesAnimacao>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  static const int _ondas = 3;

  Widget _onda(double t) {
    final double tamanho = widget.size * (0.35 + 0.65 * t);

    return Opacity(
      opacity: (1 - t) * 0.5,
      child: Container(
        width: tamanho,
        height: tamanho * 0.42,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.elliptical(tamanho, tamanho * 0.42)),
          border: Border.all(color: local.AppColors.primaryLight, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double v = _controller.value;
          // Sobe e desce suave: 0 no chão, 1 no topo.
          final double pulo = (math.sin(v * 2 * math.pi) + 1) / 2;

          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: s * 0.08,
                child: SizedBox(
                  width: s,
                  height: s * 0.42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < _ondas; i++)
                        _onda((v + i / _ondas) % 1),
                    ],
                  ),
                ),
              ),
              // Sombra encolhe quando o pin sobe.
              Positioned(
                bottom: s * 0.25,
                child: Container(
                  width: s * (0.26 - 0.08 * pulo),
                  height: s * 0.05,
                  decoration: BoxDecoration(
                    color: local.AppColors.primary
                        .withValues(alpha: 0.18 - 0.08 * pulo),
                    borderRadius: BorderRadius.circular(s),
                  ),
                ),
              ),
              Positioned(
                bottom: s * 0.27 + s * 0.12 * pulo,
                child: Container(
                  width: s * 0.42,
                  height: s * 0.42,
                  decoration: BoxDecoration(
                    color: local.AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: local.AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    PhosphorFill.mapPin,
                    color: local.AppColors.white,
                    size: s * 0.22,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
