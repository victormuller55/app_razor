import 'package:app_razor/app_config/const/app_colors.dart';
import 'package:app_razor/app_config/tema_controller.dart';
import 'package:app_razor/functions/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    temaController.value = TemaModo.claro;
    AppColors.escuro = false;
  });

  group('TemaController', () {
    test('sem escolha salva fica no claro', () async {
      final TemaController controller = TemaController();
      await controller.carregar();
      expect(controller.value, TemaModo.claro);
    });

    test('valor salvo inválido cai no claro', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        TemaController.chave: 'roxo',
      });
      final TemaController controller = TemaController();
      await controller.carregar();
      expect(controller.value, TemaModo.claro);
    });

    test('a escolha persiste e volta ao reabrir o app', () async {
      await TemaController().escolher(TemaModo.escuro);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TemaController.chave), 'escuro');

      final TemaController reaberto = TemaController();
      await reaberto.carregar();
      expect(reaberto.value, TemaModo.escuro);

      await reaberto.escolher(TemaModo.sistema);
      final TemaController deNovo = TemaController();
      await deNovo.carregar();
      expect(deNovo.value, TemaModo.sistema);
    });

    test('redefinir volta para o claro e apaga a escolha', () async {
      final TemaController controller = TemaController();
      await controller.escolher(TemaModo.escuro);

      await controller.redefinir();

      expect(controller.value, TemaModo.claro);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(TemaController.chave), isFalse);
    });

    test('avisa quem escuta quando o modo muda', () async {
      final TemaController controller = TemaController();
      int avisos = 0;
      controller.addListener(() => avisos++);

      await controller.escolher(TemaModo.escuro);

      expect(avisos, 1);
    });

    test('escuroCom segue o modo e, no do dispositivo, o sistema', () {
      final TemaController controller = TemaController();

      expect(controller.escuroCom(Brightness.dark), isFalse);

      controller.value = TemaModo.escuro;
      expect(controller.escuroCom(Brightness.light), isTrue);

      controller.value = TemaModo.sistema;
      expect(controller.escuroCom(Brightness.light), isFalse);
      expect(controller.escuroCom(Brightness.dark), isTrue);
    });
  });

  group('sair da conta', () {
    test('clearLocalData volta o tema para o claro e apaga a escolha', () async {
      await temaController.escolher(TemaModo.escuro);

      await clearLocalData();

      expect(temaController.value, TemaModo.claro);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(TemaController.chave), isFalse);

      final TemaController reaberto = TemaController();
      await reaberto.carregar();
      expect(reaberto.value, TemaModo.claro);
    });
  });

  group('AppColors', () {
    test('modo claro mantém as cores originais', () {
      AppColors.escuro = false;
      expect(AppColors.primary, const Color(0xFF1C3A5A));
      expect(AppColors.surface, Colors.white);
      expect(AppColors.text, const Color(0xFF1A1A1A));
      expect(AppColors.background, const Color(0xFFF4F4F6));
    });

    test('modo escuro troca superfície e texto', () {
      AppColors.escuro = true;
      expect(AppColors.surface, isNot(Colors.white));
      expect(AppColors.text, isNot(const Color(0xFF1A1A1A)));
      expect(AppColors.primaryBrand, const Color(0xFF1C3A5A));
      expect(AppColors.white, Colors.white);
    });
  });
}
