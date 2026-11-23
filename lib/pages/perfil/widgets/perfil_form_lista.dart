import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

/// Altura do aviso, dos campos e do botão nas telas de configuração do perfil.
const double perfilAlturaItem = 54;

/// Espaço entre os itens das telas de configuração do perfil.
const double perfilEspacoItens = 14;

/// Lista das telas de configuração do perfil com o mesmo espaço entre todos os
/// itens (aviso, campos e botão).
Widget perfilFormLista({required List<Widget> itens}) {
  return ListView.separated(
    padding: EdgeInsets.all(AppSpacing.normal),
    itemCount: itens.length,
    itemBuilder: (BuildContext context, int index) => itens[index],
    separatorBuilder: (BuildContext context, int index) =>
        const SizedBox(height: perfilEspacoItens),
  );
}
