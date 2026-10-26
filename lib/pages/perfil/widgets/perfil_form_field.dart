import 'package:app_razor/widgets/app_auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Campo das telas de perfil, no mesmo estilo dos formulários de login/cadastro.
AppFormField criarCampoPerfil({
  required BuildContext context,
  required String hint,
  required IconData icon,
  TextInputType textInputType = TextInputType.text,
  String? Function(String?)? validator,
  bool? showContent,
}) {
  return appAuthFormField(
    context: context,
    hint: hint,
    icon: icon,
    textInputType: textInputType,
    validator: validator,
    senha: showContent == false,
  );
}
