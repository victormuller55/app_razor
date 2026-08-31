import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:muller_package/muller_package.dart';

class PesquisaBarbeariasPage extends StatelessWidget {
  const PesquisaBarbeariasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return scaffold(
      title: AppStrings.barbearias,
      background: local.AppColors.background,
      appBarColor: local.AppColors.primary,
      body: Center(
        child: homeEmptyState(message: 'Em breve'),
      ),
    );
  }
}
