import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pino da barbearia no mapa: etiqueta com o nome em cima e um ponto na cor do app embaixo.
class AppMarcadorBarbearia {
  AppMarcadorBarbearia._();

  static const double _larguraMaxTexto = 140;
  static const double _fonte = 12;
  static const double _paddingH = 9;
  static const double _paddingV = 5;
  static const double _seta = 6;
  static const double _espaco = 2;
  static const double _raioPonto = 9;
  static const double _bordaPonto = 3;
  static const double _sombra = 3;

  static final Map<String, Future<({BitmapDescriptor icone, Offset ancora})>>
  _cache = <String, Future<({BitmapDescriptor icone, Offset ancora})>>{};

  static final Map<String, ({BitmapDescriptor icone, Offset ancora})> _prontos =
      <String, ({BitmapDescriptor icone, Offset ancora})>{};

  /// Ícone e âncora (centro do ponto) para o nome. Fica em cache por nome.
  static Future<({BitmapDescriptor icone, Offset ancora})> gerar(String nome) {
    return _cache.putIfAbsent(nome, () async {
      final ({BitmapDescriptor icone, Offset ancora}) marcador =
          await _desenhar(nome);
      _prontos[nome] = marcador;
      return marcador;
    });
  }

  /// Pino já desenhado, sem esperar: um mapa novo usa no primeiro quadro e os pinos não piscam.
  static ({BitmapDescriptor icone, Offset ancora})? pronto(String nome) {
    return _prontos[nome];
  }

  static Future<({BitmapDescriptor icone, Offset ancora})> _desenhar(
    String nome,
  ) async {
    final double escala = ui.PlatformDispatcher.instance.views.isEmpty
        ? 3
        : ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    const Color cor = local.AppColors.primaryBrand;

    final TextPainter texto = TextPainter(
      text: TextSpan(
        text: nome,
        style: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: _fonte,
          fontWeight: FontWeight.w700,
          color: local.AppColors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: _larguraMaxTexto);

    final double larguraEtiqueta = texto.width + _paddingH * 2;
    final double alturaEtiqueta = texto.height + _paddingV * 2;
    final double diametro = (_raioPonto + _bordaPonto) * 2;
    final double largura = larguraEtiqueta + _sombra * 2;
    final double altura =
        alturaEtiqueta + _seta + _espaco + diametro + _sombra * 2;
    final double centroX = largura / 2;

    final ui.PictureRecorder gravador = ui.PictureRecorder();
    final Canvas canvas = Canvas(gravador)..scale(escala);
    final Paint sombra = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final Paint fundo = Paint()..color = cor;

    // Etiqueta com a setinha apontando para o ponto.
    final RRect etiqueta = RRect.fromRectAndRadius(
      Rect.fromLTWH(_sombra, _sombra, larguraEtiqueta, alturaEtiqueta),
      const Radius.circular(8),
    );
    final double baseEtiqueta = _sombra + alturaEtiqueta;
    final Path seta = Path()
      ..moveTo(centroX - _seta, baseEtiqueta - 1)
      ..lineTo(centroX + _seta, baseEtiqueta - 1)
      ..lineTo(centroX, baseEtiqueta + _seta)
      ..close();
    final Path formaEtiqueta = Path()
      ..addRRect(etiqueta)
      ..addPath(seta, Offset.zero);

    canvas.drawPath(formaEtiqueta.shift(const Offset(0, 1)), sombra);
    canvas.drawPath(formaEtiqueta, fundo);
    texto.paint(canvas, Offset(_sombra + _paddingH, _sombra + _paddingV));

    // Ponto: borda branca e miolo na cor do app.
    final Offset centroPonto = Offset(
      centroX,
      baseEtiqueta + _seta + _espaco + diametro / 2,
    );
    canvas.drawCircle(centroPonto.translate(0, 1), diametro / 2, sombra);
    canvas.drawCircle(
      centroPonto,
      diametro / 2,
      Paint()..color = local.AppColors.white,
    );
    canvas.drawCircle(centroPonto, _raioPonto, fundo);

    final ui.Image imagem = await gravador.endRecording().toImage(
      (largura * escala).ceil(),
      (altura * escala).ceil(),
    );
    final ByteData? bytes = await imagem.toByteData(
      format: ui.ImageByteFormat.png,
    );
    imagem.dispose();

    return (
      icone: BitmapDescriptor.bytes(
        bytes!.buffer.asUint8List(),
        imagePixelRatio: escala,
      ),
      ancora: Offset(0.5, centroPonto.dy / altura),
    );
  }
}
