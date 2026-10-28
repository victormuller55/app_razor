import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TemaModo { claro, escuro, sistema }

/// Guarda o modo de tema escolhido no perfil e o salva no aparelho.
/// Sem escolha salva, o app fica no claro.
class TemaController extends ValueNotifier<TemaModo> {
  TemaController() : super(TemaModo.claro);

  static const String chave = 'tema_modo';

  Future<void> carregar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? salvo = prefs.getString(chave);
    value = TemaModo.values.firstWhere(
      (TemaModo modo) => modo.name == salvo,
      orElse: () => TemaModo.claro,
    );
  }

  Future<void> escolher(TemaModo modo) async {
    value = modo;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, modo.name);
  }

  /// Ao sair da conta: volta para o claro e apaga a escolha.
  Future<void> redefinir() async {
    value = TemaModo.claro;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(chave);
  }

  bool escuroCom(Brightness brilhoDoSistema) {
    return switch (value) {
      TemaModo.claro => false,
      TemaModo.escuro => true,
      TemaModo.sistema => brilhoDoSistema == Brightness.dark,
    };
  }
}

final TemaController temaController = TemaController();
