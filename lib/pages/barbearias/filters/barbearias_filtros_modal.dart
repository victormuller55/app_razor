import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/pages/barbearias/filters/barbearias_filtros.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

void showBarbeariasFiltrosModal({
  required BuildContext context,
  required BarbeariasFiltros filtros,
  required void Function(BarbeariasFiltros filtros) onApply,
  bool temLocalizacao = true,
  bool avancado = false,
}) {
  showModalEmpty(
    context,
    initialHeight: avancado ? 0.92 : 0.7,
    minHeight: 0.5,
    maxHeight: 0.95,
    backgroundColor: local.AppColors.surface,
    child: BarbeariasFiltrosModal(
      filtros: filtros,
      onApply: onApply,
      temLocalizacao: temLocalizacao,
      avancado: avancado,
    ),
  );
}

class BarbeariasFiltrosModal extends StatefulWidget {
  const BarbeariasFiltrosModal({
    super.key,
    required this.filtros,
    required this.onApply,
    this.temLocalizacao = true,
    this.avancado = false,
  });

  final BarbeariasFiltros filtros;
  final void Function(BarbeariasFiltros filtros) onApply;
  final bool temLocalizacao;
  final bool avancado;

  @override
  State<BarbeariasFiltrosModal> createState() => _BarbeariasFiltrosModalState();
}

class _BarbeariasFiltrosModalState extends State<BarbeariasFiltrosModal> {
  bool? _aberto;
  late double _distancia;
  late double _nota;
  TextEditingController? _cidade;
  TextEditingController? _bairro;
  TextEditingController? _servico;
  TextEditingController? _profissional;
  TextEditingController? _precoMin;
  TextEditingController? _precoMax;

  @override
  void initState() {
    super.initState();
    _aberto = widget.filtros.aberto;
    _distancia = BarbeariasFiltrosOpcoes.distanciaSliderDe(
      widget.filtros.distanciaMaxima,
    );
    _nota = BarbeariasFiltrosOpcoes.notaSliderDe(widget.filtros.notaMinima);
    if (widget.avancado) {
      _cidade = TextEditingController(text: widget.filtros.cidade ?? '');
      _bairro = TextEditingController(text: widget.filtros.bairro ?? '');
      _servico = TextEditingController(text: widget.filtros.servico ?? '');
      _profissional = TextEditingController(text: widget.filtros.profissional ?? '');
      _precoMin = TextEditingController(text: _textoPreco(widget.filtros.precoMin));
      _precoMax = TextEditingController(text: _textoPreco(widget.filtros.precoMax));
    }
  }

  @override
  void dispose() {
    _cidade?.dispose();
    _bairro?.dispose();
    _servico?.dispose();
    _profissional?.dispose();
    _precoMin?.dispose();
    _precoMax?.dispose();
    super.dispose();
  }

  String _textoPreco(double? valor) {
    if (valor == null) {
      return '';
    }
    return valor.toStringAsFixed(valor % 1 == 0 ? 0 : 2).replaceAll('.', ',');
  }

  double? _lerPreco(TextEditingController? controller) {
    final String texto = controller?.text.trim().replaceAll(',', '.') ?? '';
    if (texto.isEmpty) {
      return null;
    }
    return double.tryParse(texto);
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
      _cidade?.clear();
      _bairro?.clear();
      _servico?.clear();
      _profissional?.clear();
      _precoMin?.clear();
      _precoMax?.clear();
    });
  }

  void _applyFiltros() {
    final BarbeariasFiltros filtros = BarbeariasFiltros(
      busca: widget.filtros.busca,
      ordenacao: widget.filtros.ordenacao,
      cidade: widget.avancado ? _cidade?.text : widget.filtros.cidade,
      bairro: widget.avancado ? _bairro?.text : widget.filtros.bairro,
      servico: widget.avancado ? _servico?.text : widget.filtros.servico,
      profissional: widget.avancado ? _profissional?.text : widget.filtros.profissional,
      precoMin: widget.avancado ? _lerPreco(_precoMin) : widget.filtros.precoMin,
      precoMax: widget.avancado ? _lerPreco(_precoMax) : widget.filtros.precoMax,
      aberto: _aberto,
      notaMinima: BarbeariasFiltrosOpcoes.notaQueryDe(_nota),
      distanciaMaxima: widget.avancado &&
              _distancia >= BarbeariasFiltrosOpcoes.distanciaSliderMax
          ? null
          : BarbeariasFiltrosOpcoes.distanciaQueryDe(_distancia),
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
      margin: EdgeInsets.only(bottom: AppSpacing.normal + 2),
      backgroundColor: AppEstilo.campoFundo,
      radius: BorderRadius.circular(AppEstilo.raioCampo + 4),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.medium - 2),
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
      inactiveTrackColor: local.AppColors.escuro
          ? local.AppColors.contorno
          : const Color(0xFFDCE1E8),
      thumbColor: local.AppColors.primary,
      overlayColor: local.AppColors.primary.withValues(alpha: 0.12),
      trackHeight: 4,
      padding: EdgeInsets.zero,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 9,
        elevation: 2,
      ),
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

  Widget _campo(String titulo, TextEditingController? controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.normal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appText(
            titulo,
            bold: true,
            fontSize: AppFontSizes.verySmall,
            color: local.AppColors.text,
          ),
          appSizedBox(height: AppSpacing.small),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: local.AppColors.surface,
              borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.normal),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 15,
                color: local.AppColors.text,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _precos() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.normal + 2),
      child: Row(
        children: [
          Expanded(child: _campo('Preço mínimo', _precoMin)),
          appSizedBox(width: AppSpacing.normal),
          Expanded(child: _campo('Preço máximo', _precoMax)),
        ],
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: selected ? local.AppColors.primary : local.AppColors.surface,
            borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
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
        appElevatedButtonRazor(
          title: 'Aplicar filtros',
          height: 54,
          radius: AppEstilo.raioCampo,
          padding: AppSpacing.small,
          onTap: _applyFiltros,
        ),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _limpar,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.medium - 4),
              child: appText(
                'Limpar filtros',
                bold: true,
                fontSize: AppFontSizes.verySmall,
                color: local.AppColors.primaryLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        appText(
          'Filtros',
          bold: true,
          fontSize: 24,
          color: local.AppColors.text,
        ),
        appSizedBox(height: AppSpacing.small),
        appText(
          'Refine a busca para encontrar a barbearia ideal',
          fontSize: AppFontSizes.verySmall,
          color: local.AppColors.textSecondary,
        ),
        appSizedBox(height: AppSpacing.normal + 2),
        Container(
          width: 46,
          height: 4,
          decoration: BoxDecoration(
            color: AppEstilo.destaque,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium + 4,
        AppSpacing.small,
        AppSpacing.medium + 4,
        AppSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalho(),
          appSizedBox(height: AppSpacing.medium + 4),
          if (widget.avancado) ...<Widget>[
            _campo('Cidade', _cidade),
            _campo('Bairro', _bairro),
            _campo('Serviço', _servico),
            _campo('Profissional', _profissional),
            _precos(),
          ],
          _cardDistancia(),
          _cardNota(),
          _cardAberto(),
          _actionsBotoes(),
        ],
      ),
    );
  }
}
