import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

class PoliticaPrivacidadePage extends StatelessWidget {
  const PoliticaPrivacidadePage({super.key});

  Widget _secao(String titulo, String texto) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appText(
            titulo,
            bold: true,
            fontSize: AppFontSizes.small,
            color: local.AppColors.text,
          ),
          appSizedBox(height: AppSpacing.small),
          appText(
            texto,
            fontSize: AppFontSizes.verySmall,
            color: local.AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return scaffold(
      title: 'Política de privacidade',
      background: local.AppColors.background,
      appBarColor: local.AppColors.primary,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.normal),
        children: [
          appText(
            'Razor',
            bold: true,
            fontSize: AppFontSizes.medium,
            color: local.AppColors.text,
          ),
          appSizedBox(height: AppSpacing.small),
          appText(
            'Esta política descreve como o aplicativo Razor trata os dados pessoais no cadastro, login e agendamentos.',
            fontSize: AppFontSizes.verySmall,
            color: local.AppColors.textSecondary,
          ),
          appSizedBox(height: AppSpacing.medium),
          _secao(
            '1. Dados que coletamos',
            'Nome, e-mail, senha (armazenada de forma criptografada), foto de perfil opcional e os agendamentos que você faz nas barbearias.',
          ),
          _secao(
            '2. Como usamos',
            'Usamos esses dados para autenticar sua conta, exibir seu perfil, confirmar horários e melhorar a experiência no app. Não vendemos seus dados.',
          ),
          _secao(
            '3. Foto de perfil',
            'A foto é opcional. Você pode alterar ou remover a qualquer momento em Perfil. O arquivo fica armazenado apenas para exibição no aplicativo.',
          ),
          _secao(
            '4. Compartilhamento',
            'A barbearia em que você agenda vê as informações necessárias para o atendimento (nome e horário). Prestadores de infraestrutura (hospedagem e e-mail, quando houver) processam dados sob contrato.',
          ),
          _secao(
            '5. Seus direitos',
            'Você pode atualizar nome, e-mail, senha e foto no próprio app. Também pode encerrar a conta em Excluir conta. Para outros pedidos relacionados à LGPD, fale com o suporte Convertix.',
          ),
          _secao(
            '6. Segurança',
            'O acesso às rotas do app exige um token de sessão. A senha nunca é devolvida pela API. Encerrar a conta desativa o login imediatamente.',
          ),
        ],
      ),
    );
  }
}
