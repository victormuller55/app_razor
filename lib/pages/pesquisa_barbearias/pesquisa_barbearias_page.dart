import 'dart:convert';

import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/functions/gps.dart';
import 'package:app_razor/models/barbearia_model.dart';
import 'package:app_razor/pages/barbearia_perfil/barbearia_perfil_page.dart';
import 'package:app_razor/pages/barbearias/barbearias_service.dart';
import 'package:app_razor/pages/home/widgets/home_empty_state.dart';
import 'package:app_razor/pages/home/widgets/home_proxima_card.dart';
import 'package:app_razor/widgets/app_error_razor.dart';
import 'package:app_razor/widgets/app_campo_busca.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muller_package/muller_package.dart';

/// Máximo de itens por página aceito pela API.
const int _itensBusca = 100;

const Map<String, String> _semAcento = <String, String>{
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

String _normalizar(String? texto) {
  if (texto == null) {
    return '';
  }

  final StringBuffer buffer = StringBuffer();

  for (final String letra in texto.toLowerCase().trim().split('')) {
    buffer.write(_semAcento[letra] ?? letra);
  }

  return buffer.toString();
}

/// Busca de barbearias por nome, bairro ou cidade.
///
/// A API ainda não tem busca por texto, então a tela carrega as barbearias
/// (até [_itensBusca]) uma vez e filtra localmente enquanto o usuário digita.
class PesquisaBarbeariasPage extends StatefulWidget {
  const PesquisaBarbeariasPage({super.key});

  @override
  State<PesquisaBarbeariasPage> createState() => _PesquisaBarbeariasPageState();
}

class _PesquisaBarbeariasPageState extends State<PesquisaBarbeariasPage> {
  final TextEditingController _controller = TextEditingController();

  List<BarbeariaModel> _barbearias = <BarbeariaModel>[];
  ErrorModel? _erro;
  bool _carregando = true;
  String _termo = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    GpsPosition? gps;

    try {
      gps = await getCurrentGps();
    } catch (_) {
      // Sem localização a busca funciona, só sem a distância.
      gps = null;
    }

    try {
      final AppResponse response = await getBarbearias(
        itensPag: _itensBusca,
        latitude: gps?.latitude,
        longitude: gps?.longitude,
      );

      final dynamic decoded = jsonDecode(response.body);
      final dynamic itens = decoded is Map ? decoded['itens'] : null;

      if (itens is! List) {
        throw const FormatException('Resposta inválida da API');
      }

      _barbearias = itens
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                BarbeariaModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      _erro = errorModelFromApi(e);
    }

    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  List<BarbeariaModel> get _resultados {
    final String termo = _normalizar(_termo);

    if (termo.isEmpty) {
      return _barbearias;
    }

    return _barbearias.where((BarbeariaModel barbearia) {
      return _normalizar(barbearia.nome).contains(termo) ||
          _normalizar(barbearia.bairro).contains(termo) ||
          _normalizar(barbearia.cidade).contains(termo);
    }).toList();
  }

  void _abrir(BarbeariaModel barbearia) {
    final int? id = barbearia.id;

    if (id == null) {
      showSnackbarWarning(message: 'Barbearia indisponível');
      return;
    }

    FocusScope.of(context).unfocus();
    openBarbeariaPerfil(barbeariaId: id, nome: barbearia.nome);
  }

  void _limpar() {
    _controller.clear();
    setState(() => _termo = '');
  }

  Widget _campo() {
    return Container(
      height: appCampoBuscaAltura,
      decoration: BoxDecoration(
        color: AppEstilo.campoFundo,
        borderRadius: BorderRadius.circular(AppEstilo.raioCampo),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        onChanged: (String valor) => setState(() => _termo = valor),
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15,
          color: local.AppColors.text,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: 'Nome, bairro ou cidade',
          hintStyle: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 15,
            color: AppEstilo.campoIcone,
          ),
          prefixIcon: Icon(
            Phosphor.magnifyingGlass,
            size: 20,
            color: AppEstilo.campoIcone,
          ),
          suffixIcon: _termo.isEmpty
              ? null
              : IconButton(
                  onPressed: _limpar,
                  icon: Icon(
                    Phosphor.x,
                    size: 18,
                    color: AppEstilo.campoIcone,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _topo() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.small,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.normal,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Phosphor.arrowLeft,
              color: local.AppColors.text,
              size: 24,
            ),
          ),
          Expanded(child: _campo()),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return appLoadingRazor();
    }

    final ErrorModel? erro = _erro;

    if (erro != null) {
      return appErrorRazor(erro, function: _carregar);
    }

    final List<BarbeariaModel> resultados = _resultados;

    if (resultados.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: AppSpacing.giant),
        child: Align(
          alignment: Alignment.topCenter,
          child: homeEmptyState(
            message: _termo.trim().isEmpty
                ? AppStrings.nenhumaBarbeariaEncontrada
                : 'Nenhuma barbearia encontrada para "${_termo.trim()}"',
            icon: Phosphor.magnifyingGlass,
            iconSize: 44,
          ),
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.giant,
      ),
      itemCount: resultados.length,
      separatorBuilder: (_, _) => appSizedBox(height: AppSpacing.normal),
      itemBuilder: (BuildContext context, int index) {
        final BarbeariaModel barbearia = resultados[index];

        return homeProximaCard(
          barbearia: barbearia,
          onTap: () => _abrir(barbearia),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: local.AppColors.iconesBarraStatus,
        statusBarBrightness: local.AppColors.brilhoBarraStatus,
      ),
      child: Scaffold(
        backgroundColor: local.AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topo(),
              Expanded(child: _conteudo()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
