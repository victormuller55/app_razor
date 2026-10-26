import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Campo grande do cadastro: rótulo flutuante, ícone em selo que vira um
/// "check" quando o valor é válido e sublinhado que cresce ao focar.
class CadastroCampo extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String rotulo;
  final String hint;
  final IconData icone;
  final bool valido;
  final String? erro;
  final bool senha;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const CadastroCampo({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.rotulo,
    required this.hint,
    required this.icone,
    this.valido = false,
    this.erro,
    this.senha = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<CadastroCampo> createState() => _CadastroCampoState();
}

class _CadastroCampoState extends State<CadastroCampo> {
  bool _focado = false;
  bool _ocultar = true;

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focado = widget.focusNode.hasFocus);
  }

  @override
  void initState() {
    super.initState();
    _focado = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant CadastroCampo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  Color get _corDestaque {
    if (widget.erro != null) return local.AppColors.danger;
    if (widget.valido) return local.AppColors.statusAberto;
    return local.AppColors.primary;
  }

  Widget _selo() {
    final bool ativo = _focado || widget.valido;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: widget.valido
            ? local.AppColors.statusAberto
            : ativo
                ? local.AppColors.primary
                : AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(ativo ? 14 : 22),
        boxShadow: ativo
            ? [
                BoxShadow(
                  color: _corDestaque.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: RotationTransition(
            turns: Tween<double>(begin: -0.15, end: 0).animate(animation),
            child: child,
          ),
        ),
        child: Icon(
          widget.valido ? Phosphor.check : widget.icone,
          key: ValueKey(widget.valido),
          size: 20,
          color: ativo ? local.AppColors.white : AppEstilo.campoIcone,
        ),
      ),
    );
  }

  Widget _rotulo() {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 220),
      style: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: _focado || widget.valido ? _corDestaque : AppEstilo.campoIcone,
      ),
      child: Text(widget.rotulo.toUpperCase()),
    );
  }

  Widget _botaoOlho() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _ocultar = !_ocultar),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            _ocultar ? Phosphor.eyeSlash : Phosphor.eye,
            key: ValueKey(_ocultar),
            size: 22,
            color: AppEstilo.campoIcone,
          ),
        ),
      ),
    );
  }

  Widget _sublinhado() {
    final bool cheio = _focado || widget.controller.text.isNotEmpty;

    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppEstilo.alca,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            widthFactor: cheio || widget.erro != null ? 1 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_corDestaque, _corDestaque.withValues(alpha: 0.55)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _erro() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: widget.erro == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(
                    Phosphor.warningCircle,
                    size: 16,
                    color: local.AppColors.danger,
                  ),
                  appSizedBox(width: 6),
                  Expanded(
                    child: appText(
                      widget.erro!,
                      fontSize: 12,
                      color: local.AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _selo(),
            appSizedBox(width: 14),
            _rotulo(),
          ],
        ),
        appSizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                obscureText: widget.senha && _ocultar,
                autocorrect: !widget.senha,
                enableSuggestions: !widget.senha,
                maxLines: 1,
                cursorColor: local.AppColors.primary,
                cursorWidth: 2.4,
                cursorRadius: const Radius.circular(2),
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSubmitted?.call(),
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: local.AppColors.text,
                  letterSpacing: widget.senha && _ocultar ? 3 : 0,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: AppEstilo.campoIcone.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            if (widget.senha) _botaoOlho(),
          ],
        ),
        _sublinhado(),
        _erro(),
      ],
    );
  }
}
