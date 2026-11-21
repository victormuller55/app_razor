import 'dart:math' as math;

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/permissoes.dart';
import 'package:flutter/material.dart';

/// Animação em loop de cada permissão: pin quicando (localização), foto sendo
/// tirada (câmera), fotos se abrindo em leque (galeria) e sino tocando (avisos).
class PermissaoAnimacao extends StatefulWidget {
  const PermissaoAnimacao({super.key, required this.permissao, this.size = 200});

  final PermissaoApp permissao;
  final double size;

  @override
  State<PermissaoAnimacao> createState() => _PermissaoAnimacaoState();
}

class _PermissaoAnimacaoState extends State<PermissaoAnimacao>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  /// 0 → 1 → 0 no trecho [inicio, fim] do ciclo, 0 fora dele.
  static double _pulso(double v, double inicio, double fim) {
    if (v < inicio || v > fim) return 0;
    return math.sin((v - inicio) / (fim - inicio) * math.pi);
  }

  /// 0 → 1 no trecho [inicio, fim] do ciclo.
  static double _trecho(double v, double inicio, double fim) {
    return ((v - inicio) / (fim - inicio)).clamp(0.0, 1.0);
  }

  Widget _medalhao(IconData icone, {double escala = 1}) {
    final double s = widget.size;

    return Transform.scale(
      scale: escala,
      child: Container(
        width: s * 0.4,
        height: s * 0.4,
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
        child: Icon(icone, color: local.AppColors.white, size: s * 0.2),
      ),
    );
  }

  /// Anel que sai do centro e some.
  Widget _anel(double t, {double de = 0.4, double ate = 0.95}) {
    final double tamanho = widget.size * (de + (ate - de) * t);

    return Opacity(
      opacity: (1 - t) * 0.55,
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: local.AppColors.primaryLight, width: 2),
        ),
      ),
    );
  }

  /// Halo suave atrás do medalhão, respirando.
  Widget _halo(double v) {
    final double respira = (math.sin(v * 2 * math.pi) + 1) / 2;
    final double tamanho = widget.size * (0.62 + 0.06 * respira);

    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: local.AppColors.primary.withValues(alpha: 0.07 + 0.03 * respira),
      ),
    );
  }

  Widget _localizacao(double v) {
    final double s = widget.size;
    // Sobe e desce suave: 0 no chão, 1 no topo.
    final double pulo = (math.sin(v * 2 * math.pi) + 1) / 2;

    Widget onda(double t) {
      final double tamanho = s * (0.35 + 0.65 * t);
      return Opacity(
        opacity: (1 - t) * 0.5,
        child: Container(
          width: tamanho,
          height: tamanho * 0.42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(tamanho, tamanho * 0.42)),
            border: Border.all(color: local.AppColors.primaryLight, width: 2),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: s * 0.06,
          child: SizedBox(
            width: s,
            height: s * 0.42,
            child: Stack(
              alignment: Alignment.center,
              children: [for (int i = 0; i < 3; i++) onda((v + i / 3) % 1)],
            ),
          ),
        ),
        // Sombra encolhe quando o pin sobe.
        Positioned(
          bottom: s * 0.23,
          child: Container(
            width: s * (0.24 - 0.08 * pulo),
            height: s * 0.05,
            decoration: BoxDecoration(
              color: local.AppColors.primary.withValues(alpha: 0.18 - 0.08 * pulo),
              borderRadius: BorderRadius.circular(s),
            ),
          ),
        ),
        Positioned(
          bottom: s * 0.25 + s * 0.12 * pulo,
          child: _medalhao(PhosphorFill.mapPin),
        ),
      ],
    );
  }

  Widget _camera(double v) {
    // Clique do obturador em 55%–68% do ciclo: o medalhão afunda, pisca e
    // solta um anel.
    final double clique = _pulso(v, 0.55, 0.68);
    final double flash = _pulso(v, 0.57, 0.75);
    final double anel = _trecho(v, 0.6, 1);

    return Stack(
      alignment: Alignment.center,
      children: [
        _halo(v),
        if (v >= 0.6) _anel(anel, ate: 1),
        _medalhao(PhosphorFill.camera, escala: 1 - 0.1 * clique),
        // Flash.
        IgnorePointer(
          child: Opacity(
            opacity: flash * 0.85,
            child: Container(
              width: widget.size * 0.4,
              height: widget.size * 0.4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: local.AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _galeria(double v) {
    final double s = widget.size;
    // Abre o leque, segura e fecha.
    final double abre = Curves.easeOutBack.transform(_trecho(v, 0.05, 0.35));
    final double fecha = Curves.easeInCubic.transform(_trecho(v, 0.75, 0.98));
    final double leque = (abre - fecha).clamp(0.0, 1.2);

    Widget foto(double angulo, double deslocamento, double opacidade) {
      return Transform.translate(
        offset: Offset(deslocamento * s * 0.16 * leque, s * 0.02 * leque),
        child: Transform.rotate(
          angle: angulo * leque,
          child: Container(
            width: s * 0.36,
            height: s * 0.44,
            decoration: BoxDecoration(
              color: local.AppColors.primaryLight.withValues(alpha: opacidade),
              borderRadius: BorderRadius.circular(s * 0.06),
              border: Border.all(color: local.AppColors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: local.AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _halo(v),
        foto(-0.32, -1, 0.55),
        foto(0.32, 1, 0.75),
        Container(
          width: s * 0.36,
          height: s * 0.44,
          decoration: BoxDecoration(
            color: local.AppColors.primary,
            borderRadius: BorderRadius.circular(s * 0.06),
            border: Border.all(color: local.AppColors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: local.AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(PhosphorFill.images, color: local.AppColors.white, size: s * 0.17),
        ),
      ],
    );
  }

  Widget _avisos(double v) {
    final double s = widget.size;
    // Toca nos primeiros 45% do ciclo, balançando cada vez menos.
    final double toque = _trecho(v, 0, 0.45);
    final double balanco = v < 0.45
        ? math.sin(toque * math.pi * 6) * 0.32 * (1 - toque)
        : 0;
    final double selo = Curves.elasticOut.transform(_trecho(v, 0.02, 0.4));

    return Stack(
      alignment: Alignment.center,
      children: [
        _halo(v),
        if (v < 0.7) _anel(_trecho(v, 0.05, 0.7)),
        if (v > 0.15 && v < 0.85) _anel(_trecho(v, 0.15, 0.85)),
        Transform.rotate(
          angle: balanco,
          alignment: const Alignment(0, -0.6),
          child: _medalhao(PhosphorFill.bell),
        ),
        Positioned(
          top: s * 0.3,
          right: s * 0.3,
          child: Transform.scale(
            scale: v < 0.02 ? 0 : selo,
            child: Container(
              width: s * 0.1,
              height: s * 0.1,
              decoration: BoxDecoration(
                color: local.AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: local.AppColors.surface, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double v = _controller.value;
          switch (widget.permissao) {
            case PermissaoApp.localizacao:
              return _localizacao(v);
            case PermissaoApp.camera:
              return _camera(v);
            case PermissaoApp.galeria:
              return _galeria(v);
            case PermissaoApp.notificacoes:
              return _avisos(v);
          }
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
