// Gera o ícone do app, uma navalha de barbeiro (assets/logos/icon*.png).
// Depois de mudar o desenho:
//   flutter test tool/gerar_icone_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Color primaryDark = Color(0xFF12263C);
const Color primary = Color(0xFF1C3A5A);
const Color destaque = Color(0xFF7FB3E6);
const Color branco = Colors.white;

const double tamanho = 1024;

void _fundo(Canvas canvas) {
  final Rect rect = const Rect.fromLTWH(0, 0, tamanho, tamanho);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary],
      ).createShader(rect),
  );

  // Mesmas formas translúcidas giradas do cabeçalho do app.
  void forma(double cx, double cy, double lado, double alpha) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.pi / 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: lado, height: lado),
        Radius.circular(lado * 0.22),
      ),
      Paint()..color = branco.withValues(alpha: alpha),
    );
    canvas.restore();
  }

  forma(140, -60, 560, 0.045);
  forma(1000, 1010, 560, 0.04);
  forma(-60, 760, 300, 0.03);
}

/// Pino da articulação, origem do desenho da navalha.
const Offset _pino = Offset.zero;

/// Navalha de barbeiro aberta: lâmina para a direita, cabo para baixo/esquerda.
void _navalha(Canvas canvas) {
  // Cabo: peça alongada e arredondada que sai do pino.
  canvas.save();
  canvas.translate(_pino.dx, _pino.dy);
  canvas.rotate(math.pi - math.pi * 0.22);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(-34, -42, 330, 42),
      const Radius.circular(42),
    ),
    Paint()..color = destaque,
  );
  canvas.restore();

  // Espiga atrás do pino: o "rabinho" que identifica a navalha.
  canvas.drawPath(
    Path()
      ..moveTo(40, -48)
      ..cubicTo(-10, -50, -60, -62, -92, -26),
    Paint()
      ..color = branco
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round,
  );

  // Lâmina: dorso reto, ponta arredondada e fio levemente côncavo.
  final Path lamina = Path()
    ..moveTo(-40, 0)
    ..cubicTo(-40, -44, -14, -62, 30, -62)
    ..lineTo(330, -62)
    ..arcToPoint(
      const Offset(372, -20),
      radius: const Radius.circular(42),
    )
    ..lineTo(372, 22)
    ..cubicTo(372, 50, 352, 62, 324, 62)
    ..quadraticBezierTo(180, 38, 40, 38)
    ..cubicTo(6, 38, -40, 30, -40, 0)
    ..close();
  canvas.drawPath(lamina, Paint()..color = branco);

  // Fio da lâmina em destaque.
  canvas.save();
  canvas.clipPath(lamina);
  final Path fio = Path()
    ..moveTo(40, 38)
    ..quadraticBezierTo(180, 38, 324, 62)
    ..cubicTo(352, 62, 372, 50, 372, 22);
  canvas.drawPath(
    fio,
    Paint()
      ..color = destaque
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30,
  );
  canvas.restore();

  // Pino da articulação.
  canvas.drawCircle(_pino, 13, Paint()..color = primary);
}

void _marca(Canvas canvas, {required double escala}) {
  canvas.save();
  canvas.translate(tamanho / 2, tamanho / 2);
  canvas.scale(escala);
  // Centraliza o conjunto (lâmina + cabo) no ícone.
  canvas.translate(-72, -56);
  canvas.rotate(-math.pi / 10);
  _navalha(canvas);
  canvas.restore();
}

Future<void> _salvar(
  String caminho,
  void Function(Canvas canvas) desenhar,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  desenhar(Canvas(recorder));
  final ui.Image imagem = await recorder
      .endRecording()
      .toImage(tamanho.toInt(), tamanho.toInt());
  final ByteData? bytes = await imagem.toByteData(
    format: ui.ImageByteFormat.png,
  );
  File(caminho).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('gera ícones', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Ícone completo (iOS e Android legado).
      await _salvar('assets/logos/icon.png', (Canvas canvas) {
        _fundo(canvas);
        _marca(canvas, escala: 1.08);
      });

      // Android adaptativo: o sistema recorta, então a marca fica menor para
      // caber na área segura (66% central).
      await _salvar('assets/logos/icon_background.png', _fundo);
      await _salvar('assets/logos/icon_foreground.png', (Canvas canvas) {
        _marca(canvas, escala: 0.74);
      });
    });
  });
}
