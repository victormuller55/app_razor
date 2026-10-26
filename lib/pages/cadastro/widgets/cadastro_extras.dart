import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Entrada com atraso: desliza de baixo e aparece, para listas escalonadas.
class CadastroEntrada extends StatelessWidget {
  final Widget child;
  final int ordem;

  const CadastroEntrada({super.key, required this.child, this.ordem = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + ordem * 70),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Barra de progresso em segmentos exibida no cabeçalho.
class CadastroProgresso extends StatelessWidget {
  final int total;
  final int atual;

  const CadastroProgresso({super.key, required this.total, required this.atual});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final bool feito = index < atual;
        final bool corrente = index == atual;

        return Expanded(
          flex: corrente ? 3 : 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            height: corrente ? 6 : 4,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: feito || corrente
                  ? AppEstilo.destaque
                  : local.AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
              boxShadow: corrente
                  ? [
                      BoxShadow(
                        color: AppEstilo.destaque.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ]
                  : const [],
            ),
          ),
        );
      }),
    );
  }
}

/// Atalhos de domínio para completar o e-mail com um toque.
class CadastroSugestoesEmail extends StatelessWidget {
  final String texto;
  final ValueChanged<String> onSelecionar;

  static const List<String> _dominios = [
    'gmail.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
    'yahoo.com.br',
  ];

  const CadastroSugestoesEmail({
    super.key,
    required this.texto,
    required this.onSelecionar,
  });

  List<String> get _sugestoes {
    final String valor = texto.trim();
    if (valor.isEmpty) return const [];
    final int arroba = valor.indexOf('@');
    if (arroba < 0) return _dominios;
    final String parcial = valor.substring(arroba + 1).toLowerCase();
    return _dominios
        .where((d) => d.startsWith(parcial) && d != parcial)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> sugestoes = _sugestoes;
    final String usuario = texto.trim().split('@').first;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: sugestoes.isEmpty
          ? const SizedBox(width: double.infinity)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < sugestoes.length; i++)
                  CadastroEntrada(
                    key: ValueKey(sugestoes[i]),
                    ordem: i,
                    child: _chip(
                      dominio: sugestoes[i],
                      onTap: () => onSelecionar('$usuario@${sugestoes[i]}'),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _chip({required String dominio, required VoidCallback onTap}) {
    return Material(
      color: AppEstilo.campoFundo,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 13,
                color: local.AppColors.primaryLight,
              ),
              children: [
                const TextSpan(
                  text: '@',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: dominio,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Medidor de força da senha com barras e lista de requisitos.
class CadastroForcaSenha extends StatelessWidget {
  final String senha;

  const CadastroForcaSenha({super.key, required this.senha});

  static const List<Color> _cores = [
    Color(0xFFC62828),
    Color(0xFFEF6C00),
    Color(0xFFF9A825),
    Color(0xFF157A3F),
  ];

  static const List<String> _rotulos = ['Fraca', 'Razoável', 'Boa', 'Forte'];

  List<(String, bool)> get _requisitos => [
        ('8 caracteres ou mais', senha.length >= 8),
        ('Uma letra maiúscula', senha.contains(RegExp(r'[A-Z]'))),
        ('Um número', senha.contains(RegExp(r'[0-9]'))),
        ('Um símbolo (!@#...)', senha.contains(RegExp(r'[^A-Za-z0-9]'))),
      ];

  @override
  Widget build(BuildContext context) {
    final List<(String, bool)> requisitos = _requisitos;
    final int nivel = requisitos.where((r) => r.$2).length;
    final Color cor = nivel == 0 ? AppEstilo.alca : _cores[nivel - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 260 + i * 60),
                  curve: Curves.easeOutCubic,
                  height: 6,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: i < nivel ? cor : AppEstilo.campoFundo,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            appSizedBox(width: 12),
            SizedBox(
              width: 64,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(nivel),
                  child: appText(
                    nivel == 0 ? '' : _rotulos[nivel - 1],
                    fontSize: 12,
                    bold: true,
                    color: cor,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
          ],
        ),
        appSizedBox(height: 16),
        for (int i = 0; i < requisitos.length; i++)
          CadastroEntrada(
            ordem: i,
            child: _requisito(texto: requisitos[i].$1, ok: requisitos[i].$2),
          ),
      ],
    );
  }

  Widget _requisito({required String texto, required bool ok}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? local.AppColors.statusAberto : Colors.transparent,
              border: Border.all(
                color: ok ? local.AppColors.statusAberto : AppEstilo.alca,
                width: 2,
              ),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 280),
              curve: Curves.elasticOut,
              scale: ok ? 1 : 0,
              child: const Icon(
                Phosphor.check,
                size: 12,
                color: local.AppColors.white,
              ),
            ),
          ),
          appSizedBox(width: 10),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13,
              fontWeight: ok ? FontWeight.w700 : FontWeight.w400,
              color: ok ? local.AppColors.text : local.AppColors.textSecondary,
            ),
            child: Text(texto),
          ),
        ],
      ),
    );
  }
}

/// Cartão de aceite dos termos com caixa de seleção animada.
class CadastroTermosCard extends StatelessWidget {
  final bool aceito;
  final ValueChanged<bool> onChanged;

  const CadastroTermosCard({
    super.key,
    required this.aceito,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!aceito),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: aceito
              ? local.AppColors.primary.withValues(alpha: 0.06)
              : AppEstilo.campoFundo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: aceito ? local.AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: aceito ? local.AppColors.primary : local.AppColors.white,
                borderRadius: BorderRadius.circular(aceito ? 13 : 8),
                border: Border.all(
                  color: aceito ? local.AppColors.primary : AppEstilo.alca,
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: Curves.elasticOut,
                scale: aceito ? 1 : 0,
                child: const Icon(
                  Phosphor.check,
                  size: 14,
                  color: local.AppColors.white,
                ),
              ),
            ),
            appSizedBox(width: 14),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 13,
                    height: 1.35,
                    color: local.AppColors.textSecondary,
                  ),
                  children: const [
                    TextSpan(text: 'Li e aceito os '),
                    TextSpan(
                      text: 'termos de uso e a política de privacidade',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: local.AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão principal do cadastro: cor sólida, texto que troca suavemente e
/// carregamento dentro dele.
class CadastroBotao extends StatelessWidget {
  final String titulo;
  final bool habilitado;
  final bool carregando;
  final VoidCallback onTap;

  const CadastroBotao({
    super.key,
    required this.titulo,
    required this.onTap,
    this.habilitado = true,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius raio = BorderRadius.circular(AppEstilo.raioCampo);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: habilitado || carregando ? 1 : 0.5,
      child: Material(
        color: local.AppColors.primary,
        borderRadius: raio,
        child: InkWell(
          borderRadius: raio,
          onTap: carregando ? null : onTap,
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: carregando
                    ? const SizedBox(
                        key: ValueKey('carregando'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: local.AppColors.white,
                        ),
                      )
                    : KeyedSubtree(
                        key: ValueKey(titulo),
                        child: appText(
                          titulo.toUpperCase(),
                          bold: true,
                          fontSize: 14,
                          letterSpacing: 0.8,
                          color: local.AppColors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
