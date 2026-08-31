import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/models/agendamento_model.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

String inicialProfissional(String? nome) {
  if (nome == null || nome.trim().isEmpty) {
    return '?';
  }

  return nome.trim().substring(0, 1).toUpperCase();
}

Widget profissionalSelectCard({
  required AgendamentoFuncionarioOpcao funcionario,
  required bool selecionado,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: appContainer(
      width: 122,
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
      backgroundColor: selecionado
          ? local.AppColors.primary.withValues(alpha: 0.12)
          : local.AppColors.inputBackground,
      radius: BorderRadius.circular(AppRadius.medium),
      border: selecionado ? Border.all(color: local.AppColors.primary) : null,
      child: Column(
        children: [
          _foto(funcionario),
          appSizedBox(height: 8),
          appText(
            funcionario.nome ?? AppStrings.vazio,
            bold: true,
            maxLines: 2,
            overflow: true,
            textAlign: TextAlign.center,
            color: selecionado ? local.AppColors.primary : local.AppColors.text,
            fontSize: AppFontSizes.verySmall,
          ),
        ],
      ),
    ),
  );
}

Widget _foto(AgendamentoFuncionarioOpcao funcionario) {
  final String? imagem = funcionario.foto;
  final bool temFoto = imagem != null && imagem.isNotEmpty;

  return SizedBox(
    width: 72,
    height: 72,
    child: ClipOval(
      child: temFoto
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              width: 72,
              height: 72,
              errorBuilder: (_, _, _) => _fotoFallback(funcionario),
            )
          : _fotoFallback(funcionario),
    ),
  );
}

Widget _fotoFallback(AgendamentoFuncionarioOpcao funcionario) {
  return ColoredBox(
    color: local.AppColors.primary.withValues(alpha: 0.12),
    child: Center(
      child: appText(
        inicialProfissional(funcionario.nome),
        bold: true,
        fontSize: AppFontSizes.medium,
        color: local.AppColors.primary,
      ),
    ),
  );
}
