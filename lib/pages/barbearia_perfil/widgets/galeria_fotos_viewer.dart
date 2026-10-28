import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Imagem de rede com fundo neutro enquanto carrega e ícone em caso de erro.
Widget imagemRedeBarbearia(String url, {BoxFit fit = BoxFit.cover}) {
  return Image.network(
    url,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    loadingBuilder: (_, Widget child, ImageChunkEvent? progresso) {
      if (progresso == null) {
        return child;
      }
      return ColoredBox(color: AppEstilo.campoFundo);
    },
    errorBuilder: (_, _, _) => ColoredBox(
      color: AppEstilo.campoFundo,
      child: Center(
        child: Icon(Phosphor.image, size: 28, color: AppEstilo.campoIcone),
      ),
    ),
  );
}

/// Abre as [fotos] em tela cheia a partir de [inicial].
void abrirGaleriaFotos(
  BuildContext context, {
  required List<String> fotos,
  int inicial = 0,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          GaleriaFotosViewer(fotos: fotos, inicial: inicial),
      transitionsBuilder: (_, Animation<double> animacao, _, Widget child) =>
          FadeTransition(opacity: animacao, child: child),
    ),
  );
}

class GaleriaFotosViewer extends StatefulWidget {
  const GaleriaFotosViewer({super.key, required this.fotos, this.inicial = 0});

  final List<String> fotos;
  final int inicial;

  @override
  State<GaleriaFotosViewer> createState() => _GaleriaFotosViewerState();
}

class _GaleriaFotosViewerState extends State<GaleriaFotosViewer> {
  late final PageController _controller;
  late int _atual;

  @override
  void initState() {
    super.initState();
    _atual = widget.inicial;
    _controller = PageController(initialPage: widget.inicial);
  }

  Widget _miniatura(int index) {
    final bool selecionada = index == _atual;

    return GestureDetector(
      onTap: () => _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.interno + 2),
          border: Border.all(
            color: selecionada ? local.AppColors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Opacity(
          opacity: selecionada ? 1 : 0.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.interno - 2),
            child: imagemRedeBarbearia(widget.fotos[index]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.small,
                vertical: AppSpacing.small,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Phosphor.x,
                      color: local.AppColors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  appText(
                    '${_atual + 1} / ${widget.fotos.length}',
                    bold: true,
                    color: local.AppColors.white,
                    fontSize: AppFontSizes.verySmall + 1,
                  ),
                  appSizedBox(width: AppSpacing.medium),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.fotos.length,
                onPageChanged: (int index) => setState(() => _atual = index),
                itemBuilder: (BuildContext context, int index) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: imagemRedeBarbearia(
                      widget.fotos[index],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.normal,
                ),
                itemCount: widget.fotos.length,
                separatorBuilder: (_, _) => appSizedBox(width: 8),
                itemBuilder: (_, int index) => _miniatura(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
