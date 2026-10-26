import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:flutter/widgets.dart';

enum CadastroPasso {
  nome,
  email,
  senha,
  confirmacao,
}

extension CadastroPassoExt on CadastroPasso {
  int get indice => CadastroPasso.values.indexOf(this);

  bool get ultimo => indice == CadastroPasso.values.length - 1;

  String get titulo {
    switch (this) {
      case CadastroPasso.nome:
        return 'Como podemos\nte chamar?';
      case CadastroPasso.email:
        return 'Qual é o seu\ne-mail?';
      case CadastroPasso.senha:
        return 'Crie uma\nsenha segura';
      case CadastroPasso.confirmacao:
        return 'Quase lá!\nConfirme sua senha';
    }
  }

  String get subtitulo {
    switch (this) {
      case CadastroPasso.nome:
        return 'É assim que o barbeiro vai te chamar.';
      case CadastroPasso.email:
        return 'Usaremos para seu acesso e lembretes.';
      case CadastroPasso.senha:
        return 'Mínimo de 8 caracteres.';
      case CadastroPasso.confirmacao:
        return 'Digite novamente e aceite os termos.';
    }
  }

  String get rotulo {
    switch (this) {
      case CadastroPasso.nome:
        return 'Seu nome';
      case CadastroPasso.email:
        return 'Seu e-mail';
      case CadastroPasso.senha:
        return 'Sua senha';
      case CadastroPasso.confirmacao:
        return 'Confirmação';
    }
  }

  IconData get icone {
    switch (this) {
      case CadastroPasso.nome:
        return Phosphor.user;
      case CadastroPasso.email:
        return Phosphor.envelope;
      case CadastroPasso.senha:
        return Phosphor.lock;
      case CadastroPasso.confirmacao:
        return Phosphor.shieldCheck;
    }
  }

  CadastroPasso? get anterior {
    if (indice <= 0) return null;
    return CadastroPasso.values[indice - 1];
  }

  CadastroPasso? get proximo {
    if (ultimo) return null;
    return CadastroPasso.values[indice + 1];
  }
}
