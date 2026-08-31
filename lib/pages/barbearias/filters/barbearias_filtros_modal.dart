import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

void showBarbeariasFiltrosModal({
  required BuildContext context,
  required BarbeariasFiltros filtros,
  required void Function(BarbeariasFiltros filtros) onApply,
  bool temLocalizacao = true,
}) {
  showModalEmpty(
    context,
    initialHeight: 0.7,
    minHeight: 0.5,
    maxHeight: 0.95,
    backgroundColor: local.AppColors.background,
    child: BarbeariasFiltrosModal(
      filtros: filtros,
      onApply: onApply,
      temLocalizacao: temLocalizacao,
    ),
  );
}

class BarbeariasFiltrosModal extends StatefulWidget {
  const BarbeariasFiltrosModal({
    super.key,
    required this.filtros,
    required this.onApply,
    this.temLocalizacao = true,
  });

  final BarbeariasFiltros filtros;
  final void Function(BarbeariasFiltros filtros) onApply;
  final bool temLocalizacao;

  @override
  State<BarbeariasFiltrosModal> createState() => _BarbeariasFiltrosModalState();
}

class _BarbeariasFiltrosModalState extends State<BarbeariasFiltrosModal> {
  bool? _aberto;
  late double _distancia;
  late double _nota;

  @override
  void initState() {
    super.initState();
    _aberto = widget.filtros.aberto;
    _distancia = BarbeariasFiltrosOpcoes.distanciaSliderDe(
      widget.filtros.distanciaMaxima,
    );
    _nota = BarbeariasFiltrosOpcoes.notaSliderDe(widget.filtros.notaMinima);
  }

  void _selectAberto(bool? value) {
    setState(() {
      _aberto = value;
    });
  }

  void _limpar() {
    setState(() {
      _aberto = null;
      _distancia = BarbeariasFiltrosOpcoes.distanciaSliderMax;
      _nota = BarbeariasFiltrosOpcoes.notaSliderMin;
    });
  }

  void _applyFiltros() {
    final BarbeariasFiltros filtros = BarbeariasFiltros.fromQuery(
      BarbeariasFiltros(
        aberto: _aberto,
        notaMinima: BarbeariasFiltrosOpcoes.notaQueryDe(_nota),
        distanciaMaxima: BarbeariasFiltrosOpcoes.distanciaQueryDe(_distancia),
      ).toQuery(),
    );

    Navigator.of(context).pop();
    widget.onApply(filtros);
  }

  Widget _card({
    required String titulo,
    String? valor,
    required Widget child,
  }) {
    return appContainer(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.normal),
      backgroundColor: local.AppColors.white,
      radius: BorderRadius.circular(AppRadius.medium),
      shadow: local.AppColors.cardShadow,
      border: Border.all(color: local.AppColors.border),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: appText(
                    titulo,
                    bold: true,
                    fontSize: AppFontSizes.verySmall,
                    color: local.AppColors.text,
                  ),
                ),
                if (valor != null)
                  appText(
                    valor,
                    fontSize: AppFontSizes.verySmall,
                    color: local.AppColors.primary,
                    bold: true,
                  ),
              ],
            ),
            appSizedBox(height: AppSpacing.normal),
            child,
          ],
        ),
      ),
    );
  }

  SliderThemeData get _sliderTheme {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: local.AppColors.primary,
      inactiveTrackColor: local.AppColors.inputBackground,
      thumbColor: local.AppColors.primary,
      overlayColor: local.AppColors.primary.withValues(alpha: 0.12),
      trackHeight: 4,
      padding: EdgeInsets.zero,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: SliderComponentShape.noOverlay,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
    );
  }

  Widget _slider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: _sliderTheme,
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        padding: EdgeInsets.zero,
        onChanged: onChanged,
      ),
    );
  }

  Widget _cardDistancia() {
    return _card(
      titulo: 'Distância',
      valor: BarbeariasFiltrosOpcoes.rotuloDistancia(_distancia),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slider(
            value: _distancia,
            min: BarbeariasFiltrosOpcoes.distanciaSliderMin,
            max: BarbeariasFiltrosOpcoes.distanciaSliderMax,
            divisions: (BarbeariasFiltrosOpcoes.distanciaSliderMax -
                    BarbeariasFiltrosOpcoes.distanciaSliderMin)
                .round(),
            onChanged: (double value) {
              setState(() {
                _distancia = value.roundToDouble();
              });
            },
          ),
          Row(
            children: [
              appText(
                '${BarbeariasFiltrosOpcoes.distanciaSliderMin.toStringAsFixed(0)} km',
                color: local.AppColors.textSecondary,
                fontSize: 12,
              ),
              const Spacer(),
              appText(
                '${BarbeariasFiltrosOpcoes.distanciaSliderMax.toStringAsFixed(0)} km',
                color: local.AppColors.textSecondary,
                fontSize: 12,
              ),
            ],
          ),
          if (!widget.temLocalizacao)
            appText(
              'Ative a localização para filtrar por distância.',
              color: local.AppColors.textSecondary,
              fontSize: 12,
            ),
        ],
      ),
    );
  }

  Widget _cardNota() {
    return _card(
      titulo: 'Nota mínima',
      valor: BarbeariasFiltrosOpcoes.rotuloNota(_nota),
      child: _slider(
        value: _nota,
        min: BarbeariasFiltrosOpcoes.notaSliderMin,
        max: BarbeariasFiltrosOpcoes.notaSliderMax,
        divisions: 10,
        onChanged: (double value) {
          setState(() {
            _nota = (value * 2).round() / 2;
          });
        },
      ),
    );
  }

  Widget _cardAberto() {
    return _card(
      titulo: 'Funcionamento',
      child: Row(
        children: [
          _opcaoAberto(label: AppStrings.todos, value: null),
          appSizedBox(width: AppSpacing.normal),
          _opcaoAberto(label: 'Aberto', value: true),
          appSizedBox(width: AppSpacing.normal),
          _opcaoAberto(label: 'Fechado', value: false),
        ],
      ),
    );
  }

  Widget _opcaoAberto({
    required String label,
    required bool? value,
  }) {
    final bool selected = _aberto == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAberto(value),
        child: appContainer(
          height: 42,
          backgroundColor: selected
              ? local.AppColors.primary
              : local.AppColors.inputBackground,
          radius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: selected ? local.AppColors.primary : local.AppColors.border,
          ),
          child: Center(
            child: appText(
              label,
              bold: selected,
              fontSize: AppFontSizes.verySmall,
              color: selected ? local.AppColors.white : local.AppColors.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionsBotoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _limpar,
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.small,
                bottom: AppSpacing.small,
              ),
              child: appText(
                'Limpar filtros',
                bold: true,
                fontSize: AppFontSizes.verySmall,
                color: local.AppColors.primary,
              ),
            ),
          ),
        ),
        appElevatedButtonRazor(
          title: 'Aplicar',
          padding: 0,
          onTap: _applyFiltros,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appText(
            'Filtros',
            bold: true,
            fontSize: AppFontSizes.medium,
            color: local.AppColors.text,
          ),
          appSizedBox(height: AppSpacing.medium),
          _cardDistancia(),
          _cardNota(),
          _cardAberto(),
          _actionsBotoes(),
        ],
      ),
    );
  }
}
