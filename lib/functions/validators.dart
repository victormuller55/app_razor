import 'package:muller_package/muller_package.dart';

class AppValidators {
  static String? required(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Este campo é obrigatório';
    }
    return null;
  }

  static String? email(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? 'Email é obrigatório';
    }
    if (value.trim().length > 180) {
      return errorMessage ?? 'E-mail deve ter no máximo 180 caracteres';
    }
    if (!validaEmail(value)) {
      return errorMessage ?? 'Email inválido';
    }
    return null;
  }

  static String? nome(String? value, {String? errorMessage}) {
    final String? requiredError = required(value, errorMessage: errorMessage);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length > 150) {
      return errorMessage ?? 'O nome deve ter no máximo 150 caracteres';
    }
    return null;
  }

  static String? senhaCadastro(String? value, {String? errorMessage}) {
    final String? requiredError = required(value, errorMessage: errorMessage);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.length < 8 || value.length > 128) {
      return errorMessage ?? 'A senha deve ter entre 8 e 128 caracteres';
    }
    return null;
  }

  static String? confirmacaoSenha(
    String? value,
    String senha, {
    String? errorMessage,
  }) {
    if (value != senha) {
      return errorMessage ?? AppStrings.asSenhasNaoSaoIguais;
    }
    return null;
  }
}
