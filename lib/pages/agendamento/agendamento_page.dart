import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/app_radius.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/functions/lembrete_agendamento.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/models/politica_agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_bloc.dart';
import 'package:app_razor/pages/agendamento/agendamento_blocos.dart';
import 'package:app_razor/pages/agendamento/agendamento_event.dart';
import 'package:app_razor/pages/agendamento/agendamento_state.dart';
import 'package:app_razor/pages/agendamento/widgets/ordem_criada_modal.dart';
import 'package:app_razor/pages/agendamento/widgets/profissional_select_card.dart';
import 'package:app_razor/pages/agendamento/widgets/servico_agendamento_card.dart';
import 'package:app_razor/pages/agendamentos/agendamentos_service.dart';
import 'package:app_razor/pages/pagamento/pagamento_modal.dart';
import 'package:app_razor/widgets/app_error_razor.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_header_razor.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

void openAgendamento({
  required int barbeariaId,
  String? nomeBarbearia,
  int? servicoId,
  int? funcionarioId,
}) {
  open(
    screen: AgendamentoPage(
      barbeariaId: barbeariaId,
      nomeBarbearia: nomeBarbearia,
      servicoId: servicoId,
      funcionarioId: funcionarioId,
    ),
  );
}

/// Abre a reserva para trocar serviços, profissionais e horários. Devolve
/// true quando ela foi alterada.
Future<bool> openEditarReserva(
  BuildContext context, {
  required int barbeariaId,
  required AgendamentoEdicao edicao,
  String? nomeBarbearia,
}) async {
  final bool? alterada = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (BuildContext context) => AgendamentoPage(
        barbeariaId: barbeariaId,
        nomeBarbearia: nomeBarbearia,
        edicao: edicao,
      ),
    ),
  );
  return alterada ?? false;
}

class AgendamentoPage extends StatefulWidget {
  const AgendamentoPage({
    super.key,
    required this.barbeariaId,
    this.nomeBarbearia,
    this.servicoId,
    this.funcionarioId,
    this.edicao,
  });

  final int barbeariaId;
  final String? nomeBarbearia;
  final int? servicoId;
  final int? funcionarioId;

  /// Reserva existente sendo alterada; null para uma reserva nova.
  final AgendamentoEdicao? edicao;

  @override
  State<AgendamentoPage> createState() => _AgendamentoPageState();
}

/// Período do dia usado para agrupar os horários.
class _Periodo {
  const _Periodo(this.titulo, this.icone, this.ateHora);

  final String titulo;
  final IconData icone;

  /// Hora (exclusiva) em que o período termina.
  final int ateHora;
}

class _AgendamentoPageState extends State<AgendamentoPage> {
  late final AgendamentoBloc bloc;
  final TextEditingController _observacaoController = TextEditingController();

  /// Com serviço vindo do perfil, a lista completa só abre quando pedida.
  late bool _listaServicosAberta = widget.servicoId == null;

  /// Cliente pediu um profissional diferente para cada serviço.
  bool _separarProfissionais = false;
  bool _mostrarObservacao = false;
  PoliticaAgendamentoModel _politica = PoliticaAgendamentoModel.padrao;
  bool _mostrarRegras = false;

  static const List<String> _diasSemana = <String>[
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

  static const List<String> _meses = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static const List<_Periodo> _periodos = <_Periodo>[
    _Periodo('Manhã', Phosphor.sunHorizon, 12),
    _Periodo('Tarde', Phosphor.sun, 18),
    _Periodo('Noite', Phosphor.moonStars, 24),
  ];

  double get _margem => AppSpacing.medium;

  bool get _editando => widget.edicao != null;

  /// A reserva editada já foi paga pelo app (a diferença é cobrada ou estornada).
  bool get _reservaPaga =>
      widget.edicao?.itens.any((AgendamentoModel item) => item.pago) ?? false;

  @override
  void initState() {
    super.initState();
    bloc = AgendamentoBloc(
      barbeariaId: widget.barbeariaId,
      servicoId: widget.servicoId,
      funcionarioId: widget.funcionarioId,
      edicao: widget.edicao,
    );
    bloc.add(AgendamentoLoadEvent());
    getPoliticaAgendamento().then((PoliticaAgendamentoModel politica) {
      if (mounted) {
        setState(() => _politica = politica);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Dados derivados
  // ---------------------------------------------------------------------------

  DateTime get _hoje {
    final DateTime agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  bool _mesmoDia(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  String _dataCurta(DateTime data) {
    final String semana = _diasSemana[data.weekday - 1];
    final String mes = _meses[data.month - 1].substring(0, 3);
    final String prefixo = _mesmoDia(data, _hoje)
        ? 'Hoje'
        : '${semana[0].toUpperCase()}${semana.substring(1)}';
    return '$prefixo, ${data.day.toString().padLeft(2, '0')} de $mes';
  }

  String _duracaoLabel(int minutos) {
    final int horas = minutos ~/ 60;
    final int resto = minutos % 60;
    if (horas == 0) {
      return '$resto min';
    }
    return resto == 0 ? '${horas}h' : '${horas}h ${resto}min';
  }

  String _primeiroNome(String? nome) => (nome ?? '').trim().split(' ').first;

  AgendamentoServicoOpcao? _servico(AgendamentoState state, int id) {
    final Iterable<AgendamentoServicoOpcao> itens = state.contexto!.servicos
        .where((AgendamentoServicoOpcao item) => item.id == id);
    return itens.isEmpty ? null : itens.first;
  }

  AgendamentoFuncionarioOpcao? _funcionario(AgendamentoState state, int id) {
    final Iterable<AgendamentoFuncionarioOpcao> itens = state
        .contexto!
        .funcionarios
        .where((AgendamentoFuncionarioOpcao item) => item.id == id);
    return itens.isEmpty ? null : itens.first;
  }

  List<AgendamentoFuncionarioOpcao> _aptos(
    AgendamentoState state,
    Iterable<int> idsServicos,
  ) {
    return state.contexto!.funcionarios
        .where(
          (AgendamentoFuncionarioOpcao item) =>
              item.id != null &&
              idsServicos.every((int id) => item.realizaServico(id)),
        )
        .toList();
  }

  double _total(AgendamentoState state) => state.idsServicos.fold<double>(
    0,
    (double soma, int id) => soma + (_servico(state, id)?.preco ?? 0),
  );

  int _duracaoTotal(AgendamentoState state) => state.idsServicos.fold<int>(
    0,
    (int soma, int id) => soma + (_servico(state, id)?.duracaoMinutos ?? 0),
  );

  bool _profissionaisCompletos(AgendamentoState state) =>
      state.idsServicos.isNotEmpty &&
      state.idsServicos.every(state.funcionarioPorServico.containsKey);

  /// Etapas concluídas de 3: serviços, profissional e horário.
  int _etapasConcluidas(AgendamentoState state) {
    return <bool>[
      state.idsServicos.isNotEmpty,
      _profissionaisCompletos(state),
      state.completo,
    ].where((bool feito) => feito).length;
  }

  // ---------------------------------------------------------------------------
  // Estrutura
  // ---------------------------------------------------------------------------

  Widget _progresso(AgendamentoState state) {
    final int concluidas = _etapasConcluidas(state);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _margem,
        AppSpacing.medium,
        _margem,
        AppSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List<Widget>.generate(3, (int index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index < concluidas
                        ? local.AppColors.primary
                        : AppEstilo.campoFundo,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          appSizedBox(height: AppSpacing.small + 3),
          appText(
            concluidas == 3
                ? 'Tudo pronto! Revise e confirme'
                : 'Etapa ${concluidas + 1} de 3',
            bold: true,
            color: concluidas == 3
                ? local.AppColors.statusAberto
                : local.AppColors.textSecondary,
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  Widget _etapa({
    required int numero,
    required String titulo,
    required bool concluida,
    required Widget child,
    String? subtitulo,
    Widget? acao,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.big - 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _margem),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: concluida
                        ? local.AppColors.primary
                        : AppEstilo.campoFundo,
                  ),
                  child: Center(
                    child: concluida
                        ? const Icon(
                            Phosphor.check,
                            size: 13,
                            color: local.AppColors.white,
                          )
                        : appText(
                            '$numero',
                            bold: true,
                            color: local.AppColors.textSecondary,
                            fontSize: 12,
                          ),
                  ),
                ),
                appSizedBox(width: AppSpacing.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      appText(
                        titulo,
                        bold: true,
                        fontSize: AppFontSizes.small + 1,
                        color: local.AppColors.text,
                      ),
                      if (subtitulo != null)
                        appText(
                          subtitulo,
                          color: local.AppColors.textSecondary,
                          fontSize: 12,
                        ),
                    ],
                  ),
                ),
                ?acao,
              ],
            ),
          ),
          appSizedBox(height: AppSpacing.normal + 4),
          child,
        ],
      ),
    );
  }

  Widget _linkAcao(String texto, VoidCallback onTap, {IconData? icone}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 16, color: local.AppColors.primaryLight),
              appSizedBox(width: 5),
            ],
            appText(
              texto,
              bold: true,
              color: local.AppColors.primaryLight,
              fontSize: AppFontSizes.verySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Caixa neutra para quando ainda não há o que escolher.
  Widget _aviso({required IconData icone, required String texto}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _margem),
      child: appContainer(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.normal + 4),
        backgroundColor: AppEstilo.campoFundo,
        radius: BorderRadius.circular(AppRadii.externo),
        child: Row(
          children: [
            appContainer(
              width: 38,
              height: 38,
              backgroundColor: local.AppColors.surface,
              radius: BorderRadius.circular(AppRadii.interno),
              child: Center(
                child: Icon(icone, size: 18, color: AppEstilo.campoIcone),
              ),
            ),
            appSizedBox(width: AppSpacing.normal + 2),
            Expanded(
              child: appText(
                texto,
                color: local.AppColors.textSecondary,
                fontSize: AppFontSizes.verySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Serviços
  // ---------------------------------------------------------------------------

  Widget _cardServico(AgendamentoState state, AgendamentoServicoOpcao servico) {
    final int posicao = servico.id == null
        ? -1
        : state.idsServicos.indexOf(servico.id!);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.small + 3),
      child: servicoAgendamentoCard(
        servico: servico,
        selecionado: posicao >= 0,
        ordem: posicao >= 0 && state.idsServicos.length > 1
            ? posicao + 1
            : null,
        onTap: servico.id == null
            ? null
            : () => bloc.add(AgendamentoToggleServicoEvent(servico.id!)),
      ),
    );
  }

  Widget _servicos(AgendamentoReadyState state) {
    final List<AgendamentoServicoOpcao> todos = state.contexto!.servicos;
    final bool fechada = !_listaServicosAberta && state.idsServicos.isNotEmpty;
    final List<AgendamentoServicoOpcao> visiveis = fechada
        ? state.idsServicos
              .map((int id) => _servico(state, id))
              .whereType<AgendamentoServicoOpcao>()
              .toList()
        : todos;
    final int quantidade = state.idsServicos.length;

    return _etapa(
      numero: 1,
      titulo: quantidade > 1 ? 'Serviços' : 'O que vai fazer?',
      subtitulo: quantidade > 1
          ? '$quantidade escolhidos · ${_duracaoLabel(_duracaoTotal(state))}'
          : 'Pode escolher mais de um',
      concluida: quantidade > 0,
      acao: !_listaServicosAberta || quantidade == 0
          ? null
          : _linkAcao(
              'Pronto',
              () => setState(() => _listaServicosAberta = false),
            ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _margem),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final AgendamentoServicoOpcao servico in visiveis)
              _cardServico(state, servico),
            if (fechada && todos.length > quantidade)
              _linkAcao(
                'Adicionar outro serviço',
                () => setState(() => _listaServicosAberta = true),
                icone: Phosphor.plus,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Profissional
  // ---------------------------------------------------------------------------

  Widget _listaProfissionais({
    required List<AgendamentoFuncionarioOpcao> opcoes,
    required bool Function(int id) selecionado,
    required void Function(int id) onTap,
  }) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: _margem - 4),
        itemCount: opcoes.length,
        separatorBuilder: (_, _) => appSizedBox(width: AppSpacing.small),
        itemBuilder: (BuildContext context, int index) {
          final int id = opcoes[index].id!;
          return profissionalSelectCard(
            funcionario: opcoes[index],
            selecionado: selecionado(id),
            onTap: () => onTap(id),
          );
        },
      ),
    );
  }

  /// Um profissional para todos os serviços, feitos em sequência.
  Widget _profissionalUnico(
    AgendamentoReadyState state,
    List<AgendamentoFuncionarioOpcao> aptos,
  ) {
    return _listaProfissionais(
      opcoes: aptos,
      selecionado: (int id) => state.idsServicos.every(
        (int servico) => state.funcionarioPorServico[servico] == id,
      ),
      onTap: (int id) => bloc.add(AgendamentoSelectFuncionarioEvent(id)),
    );
  }

  /// Um profissional por serviço; quem repete faz os serviços em sequência.
  Widget _profissionalPorServico(AgendamentoReadyState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final int idServico in state.idsServicos) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(_margem, 0, _margem, 6),
            child: Row(
              children: [
                Icon(
                  Phosphor.scissors,
                  size: 14,
                  color: local.AppColors.textSecondary,
                ),
                appSizedBox(width: 5),
                Expanded(
                  child: appText(
                    _servico(state, idServico)?.nome ?? AppStrings.vazio,
                    bold: true,
                    maxLines: 1,
                    overflow: true,
                    color: local.AppColors.text,
                    fontSize: AppFontSizes.verySmall,
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (BuildContext context) {
              final List<AgendamentoFuncionarioOpcao> aptos = _aptos(
                state,
                <int>[idServico],
              );
              if (aptos.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.normal),
                  child: _aviso(
                    icone: Phosphor.user,
                    texto: 'Nenhum profissional faz este serviço agora',
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.small),
                child: _listaProfissionais(
                  opcoes: aptos,
                  selecionado: (int id) =>
                      state.funcionarioPorServico[idServico] == id,
                  onTap: (int id) => bloc.add(
                    AgendamentoSelectFuncionarioEvent(id, idServico: idServico),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _funcionarios(AgendamentoReadyState state) {
    const String titulo = 'Com quem?';

    if (state.idsServicos.isEmpty) {
      return _etapa(
        numero: 2,
        titulo: titulo,
        concluida: false,
        child: _aviso(
          icone: Phosphor.user,
          texto: 'Escolha um serviço para ver os profissionais',
        ),
      );
    }

    final bool varios = state.idsServicos.length > 1;
    final List<AgendamentoFuncionarioOpcao> aptosTodos = _aptos(
      state,
      state.idsServicos,
    );
    final bool porServico =
        varios && (_separarProfissionais || aptosTodos.isEmpty);

    if (!varios && aptosTodos.isEmpty) {
      return _etapa(
        numero: 2,
        titulo: titulo,
        concluida: false,
        child: _aviso(
          icone: Phosphor.user,
          texto: 'Nenhum profissional disponível para este serviço',
        ),
      );
    }

    return _etapa(
      numero: 2,
      titulo: titulo,
      subtitulo: !varios
          ? null
          : porServico
          ? (aptosTodos.isEmpty
                ? 'Ninguém faz todos; escolha um para cada'
                : 'Escolha um profissional para cada serviço')
          : 'Faz tudo em sequência, num horário só',
      concluida: _profissionaisCompletos(state),
      acao: varios && aptosTodos.isNotEmpty
          ? _linkAcao(
              porServico ? 'Um só' : 'Separar',
              () => setState(
                () => _separarProfissionais = !_separarProfissionais,
              ),
            )
          : null,
      child: porServico
          ? _profissionalPorServico(state)
          : _profissionalUnico(state, aptosTodos),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Dia e horário
  // ---------------------------------------------------------------------------

  Widget _dia(AgendamentoBloco bloco, DateTime dia) {
    final bool hoje = _mesmoDia(dia, _hoje);
    final bool selecionado = _mesmoDia(bloco.data, dia);

    return GestureDetector(
      onTap: () => bloc.add(
        AgendamentoSelectDataEvent(
          idFuncionario: bloco.idFuncionario,
          data: dia,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        decoration: BoxDecoration(
          color: selecionado ? local.AppColors.primary : AppEstilo.campoFundo,
          borderRadius: BorderRadius.circular(AppRadii.externo - 4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            appText(
              hoje ? 'HOJE' : _diasSemana[dia.weekday - 1].toUpperCase(),
              bold: true,
              letterSpacing: 0.5,
              color: selecionado
                  ? local.AppColors.white.withValues(alpha: 0.8)
                  : local.AppColors.textSecondary,
              fontSize: 10,
            ),
            appSizedBox(height: 4),
            appText(
              '${dia.day}',
              bold: true,
              color: selecionado ? local.AppColors.white : local.AppColors.text,
              fontSize: AppFontSizes.medium,
            ),
            appSizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hoje
                    ? (selecionado
                          ? local.AppColors.white
                          : local.AppColors.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faixaDias(AgendamentoBloco bloco) {
    // Começa hoje: os horários que já passaram vêm desativados da API.
    final DateTime hoje = _hoje;
    final List<DateTime> dias = List<DateTime>.generate(
      21,
      (int index) => DateTime(hoje.year, hoje.month, hoje.day + index),
    );

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: _margem),
        itemCount: dias.length,
        separatorBuilder: (_, _) => appSizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) =>
            _dia(bloco, dias[index]),
      ),
    );
  }

  Widget _chipHorario(AgendamentoBloco bloco, AgendamentoHorarioModel horario) {
    final String? hora = horario.horaInicio;
    final bool ativo = horario.disponivel && hora != null;
    final bool selecionado = hora != null && hora == bloco.horaInicio;

    return GestureDetector(
      onTap: ativo
          ? () => bloc.add(
              AgendamentoSelectHorarioEvent(
                idFuncionario: bloco.idFuncionario,
                horaInicio: hora,
              ),
            )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selecionado
              ? local.AppColors.primary
              : ativo
              ? local.AppColors.surface
              : AppEstilo.campoFundo,
          borderRadius: BorderRadius.circular(AppRadii.interno + 2),
          border: Border.all(
            color: selecionado
                ? local.AppColors.primary
                : ativo
                ? local.AppColors.contorno
                : AppEstilo.campoFundo,
          ),
        ),
        child: Center(
          child: Text(
            horario.label,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.bold,
              fontSize: AppFontSizes.verySmall + 1,
              color: selecionado
                  ? local.AppColors.white
                  : ativo
                  ? local.AppColors.text
                  : AppEstilo.campoIcone,
              decoration: ativo ? null : TextDecoration.lineThrough,
              decorationColor: AppEstilo.campoIcone,
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradeHorarios(List<Widget> itens) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.9,
      children: itens,
    );
  }

  Widget _horariosPorPeriodo(AgendamentoBloco bloco) {
    final List<Widget> blocos = <Widget>[];
    int inicio = 0;

    for (final _Periodo periodo in _periodos) {
      final int de = inicio;
      final List<AgendamentoHorarioModel> doPeriodo = bloco.horarios.where((
        AgendamentoHorarioModel item,
      ) {
        final int hora = (minutosDoDia(item.horaInicio) ?? 0) ~/ 60;
        return hora >= de && hora < periodo.ateHora;
      }).toList();
      inicio = periodo.ateHora;

      if (doPeriodo.isEmpty) {
        continue;
      }

      final int livres = doPeriodo
          .where((AgendamentoHorarioModel item) => item.disponivel)
          .length;

      blocos.add(
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.normal + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    periodo.icone,
                    size: 15,
                    color: local.AppColors.textSecondary,
                  ),
                  appSizedBox(width: 5),
                  appText(
                    periodo.titulo,
                    bold: true,
                    color: local.AppColors.text,
                    fontSize: AppFontSizes.verySmall,
                  ),
                  appSizedBox(width: 6),
                  appText(
                    livres == 1 ? '1 livre' : '$livres livres',
                    color: local.AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ],
              ),
              appSizedBox(height: AppSpacing.small + 3),
              _gradeHorarios(
                doPeriodo
                    .map(
                      (AgendamentoHorarioModel horario) =>
                          _chipHorario(bloco, horario),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocos,
    );
  }

  Widget _horariosDoBloco(AgendamentoBloco bloco) {
    if (bloco.loadingHorarios) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: _margem),
        child: _gradeHorarios(
          List<Widget>.generate(
            8,
            (_) => appContainer(
              backgroundColor: AppEstilo.campoFundo,
              radius: BorderRadius.circular(AppRadii.interno + 2),
            ),
          ),
        ),
      );
    }

    final bool algumLivre = bloco.horarios.any(
      (AgendamentoHorarioModel item) => item.disponivel,
    );

    if (!algumLivre) {
      return _aviso(
        icone: Phosphor.calendarBlank,
        texto: bloco.idsServicos.length > 1
            ? 'Não cabem esses serviços seguidos neste dia. Tente outra data.'
            : bloco.motivoHorarios ??
                  'Sem horários livres neste dia. Que tal tentar outra data?',
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _margem),
      child: _horariosPorPeriodo(bloco),
    );
  }

  /// Quem atende, quais serviços seguidos e quanto tempo leva o bloco.
  Widget _cabecalhoBloco(
    AgendamentoReadyState state,
    AgendamentoBloco bloco,
    int indice,
  ) {
    final AgendamentoFuncionarioOpcao? funcionario = _funcionario(
      state,
      bloco.idFuncionario,
    );
    final String servicos = bloco.idsServicos
        .map((int id) => _servico(state, id)?.nome ?? '')
        .where((String nome) => nome.isNotEmpty)
        .join(' + ');
    final int duracao = bloco.duracaoTotal > 0
        ? bloco.duracaoTotal
        : bloco.idsServicos.fold<int>(
            0,
            (int soma, int id) =>
                soma + (_servico(state, id)?.duracaoMinutos ?? 0),
          );
    final ({int inicio, int fim})? intervalo = bloco.intervalo;

    return Padding(
      padding: EdgeInsets.fromLTRB(_margem, 0, _margem, AppSpacing.normal + 2),
      child: appContainer(
        padding: EdgeInsets.all(AppSpacing.normal + 2),
        backgroundColor: local.AppColors.primary.withValues(alpha: 0.06),
        radius: BorderRadius.circular(AppRadii.externo - 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: local.AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: appText(
                inicialProfissional(funcionario?.nome),
                bold: true,
                color: local.AppColors.white,
                fontSize: AppFontSizes.verySmall + 1,
              ),
            ),
            appSizedBox(width: AppSpacing.normal + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  appText(
                    state.blocos.length > 1
                        ? 'Horário ${indice + 1} · com ${_primeiroNome(funcionario?.nome)}'
                        : 'Com ${_primeiroNome(funcionario?.nome)}',
                    bold: true,
                    maxLines: 1,
                    overflow: true,
                    color: local.AppColors.text,
                    fontSize: AppFontSizes.verySmall + 1,
                  ),
                  appText(
                    servicos,
                    maxLines: 1,
                    overflow: true,
                    color: local.AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
            appSizedBox(width: AppSpacing.small),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                appText(
                  intervalo == null
                      ? _duracaoLabel(duracao)
                      : '${horaDeMinutos(intervalo.inicio)}–${horaDeMinutos(intervalo.fim)}',
                  bold: true,
                  color: local.AppColors.primary,
                  fontSize: AppFontSizes.verySmall,
                ),
                if (bloco.idsServicos.length > 1)
                  appText(
                    'seguidos',
                    color: local.AppColors.textSecondary,
                    fontSize: 11,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quando(AgendamentoReadyState state) {
    final bool pronto = _profissionaisCompletos(state);

    if (!pronto || state.blocos.isEmpty) {
      return _etapa(
        numero: 3,
        titulo: 'Quando?',
        concluida: false,
        child: _aviso(
          icone: Phosphor.clock,
          texto: 'Escolha o profissional para ver os dias e horários livres',
        ),
      );
    }

    final bool mostrarCabecalho =
        state.blocos.length > 1 || state.idsServicos.length > 1;
    final DateTime referencia = state.blocos.first.data ?? _hoje;
    final String mes = _meses[referencia.month - 1];

    return _etapa(
      numero: 3,
      titulo: 'Quando?',
      subtitulo: state.blocos.length > 1
          ? 'Profissionais diferentes: um horário para cada'
          : null,
      concluida: state.completo,
      acao: appText(
        '${mes[0].toUpperCase()}${mes.substring(1)}',
        bold: true,
        color: local.AppColors.textSecondary,
        fontSize: AppFontSizes.verySmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < state.blocos.length; i++) ...[
            if (i > 0) appSizedBox(height: AppSpacing.medium),
            if (mostrarCabecalho) _cabecalhoBloco(state, state.blocos[i], i),
            _faixaDias(state.blocos[i]),
            appSizedBox(height: AppSpacing.normal + 4),
            _horariosDoBloco(state.blocos[i]),
          ],
        ],
      ),
    );
  }

  Widget _observacoes() {
    if (!_mostrarObservacao) {
      return Padding(
        padding: EdgeInsets.fromLTRB(_margem, AppSpacing.normal, _margem, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _linkAcao(
            'Adicionar observação (opcional)',
            () => setState(() => _mostrarObservacao = true),
            icone: Phosphor.notePencil,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(_margem, AppSpacing.big - 4, _margem, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appText(
            'Observação',
            bold: true,
            fontSize: AppFontSizes.verySmall + 1,
            color: local.AppColors.text,
          ),
          appSizedBox(height: AppSpacing.small + 3),
          TextField(
            controller: _observacaoController,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: TextStyle(
              fontFamily: AppFonts.family,
              color: local.AppColors.text,
              fontSize: AppFontSizes.small,
            ),
            decoration: InputDecoration(
              hintText: 'Ex.: preferência de corte, alergia...',
              hintStyle: TextStyle(
                fontFamily: AppFonts.family,
                color: AppEstilo.campoIcone,
                fontSize: AppFontSizes.verySmall,
              ),
              filled: true,
              fillColor: AppEstilo.campoFundo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.externo - 4),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.externo - 4),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.externo - 4),
                borderSide: BorderSide(color: local.AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rodapé
  // ---------------------------------------------------------------------------

  String _proximoPasso(AgendamentoState state) {
    if (state.idsServicos.isEmpty) {
      return 'Escolha o serviço';
    }
    if (!_profissionaisCompletos(state)) {
      return 'Escolha o profissional';
    }
    if (!state.completo) {
      return state.blocos.length > 1
          ? 'Escolha os horários'
          : 'Escolha o horário';
    }
    if (state.salvando) {
      return _editando ? 'Salvando...' : 'Confirmando...';
    }
    if (_editando) {
      return 'Salvar alterações';
    }
    return state.idsServicos.length > 1
        ? 'Confirmar ${state.idsServicos.length} serviços'
        : 'Confirmar agendamento';
  }

  Widget _resumo(AgendamentoReadyState state) {
    if (state.idsServicos.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<AgendamentoBloco> marcados = state.blocos
        .where((AgendamentoBloco bloco) => bloco.completo)
        .toList();
    final String quando;

    if (marcados.isEmpty) {
      quando = 'Escolha o dia e o horário';
    } else if (state.blocos.length == 1) {
      final AgendamentoBloco bloco = marcados.first;
      quando = '${_dataCurta(bloco.data!)} às ${bloco.horaInicio}';
    } else {
      quando =
          '${marcados.length} de ${state.blocos.length} horários escolhidos';
    }

    final String oQue = state.idsServicos.length > 1
        ? '${state.idsServicos.length} serviços · ${_duracaoLabel(_duracaoTotal(state))}'
        : _servico(state, state.idsServicos.first)?.nome ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.normal + 2),
      child: Row(
        children: [
          appContainer(
            width: 42,
            height: 42,
            backgroundColor: local.AppColors.primary.withValues(alpha: 0.08),
            radius: BorderRadius.circular(AppRadii.interno + 2),
            child: Center(
              child: Icon(
                Phosphor.calendarCheck,
                size: 20,
                color: local.AppColors.primary,
              ),
            ),
          ),
          appSizedBox(width: AppSpacing.normal + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                appText(
                  quando,
                  bold: true,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.text,
                  fontSize: AppFontSizes.verySmall + 1,
                ),
                appSizedBox(height: 2),
                appText(
                  oQue,
                  maxLines: 1,
                  overflow: true,
                  color: local.AppColors.textSecondary,
                  fontSize: 12,
                ),
              ],
            ),
          ),
          appSizedBox(width: AppSpacing.small),
          appText(
            formataDinheiro(_total(state)),
            bold: true,
            color: local.AppColors.primary,
            fontSize: AppFontSizes.small,
          ),
        ],
      ),
    );
  }

  Widget _rodape(AgendamentoReadyState state) {
    final bool podeSalvar = state.completo && !state.salvando;

    return Container(
      decoration: BoxDecoration(
        color: local.AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.externo + 4),
        ),
        boxShadow: [
          BoxShadow(
            color: local.AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        _margem,
        AppSpacing.medium - 4,
        _margem,
        AppSpacing.normal + 2 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _resumo(state),
          ),
          appElevatedButtonRazor(
            title: _proximoPasso(state),
            padding: 0,
            width: double.infinity,
            color: podeSalvar
                ? local.AppColors.primary
                : local.AppColors.primary.withValues(alpha: 0.35),
            onTap: podeSalvar
                ? () => bloc.add(
                    AgendamentoSalvarEvent(
                      observacao: _observacaoController.text,
                    ),
                  )
                : () {},
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tela
  // ---------------------------------------------------------------------------

  Widget _conteudo(AgendamentoState state) {
    if (state is AgendamentoSuccessState) {
      return Center(child: appLoadingRazor());
    }

    if (state is AgendamentoErrorState) {
      return appErrorRazor(
        state.errorModel,
        function: () => bloc.add(AgendamentoLoadEvent(forceRefresh: true)),
      );
    }

    if (state is! AgendamentoReadyState || state.contexto == null) {
      return appLoadingRazor();
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.big),
      children: [
        _progresso(state),
        if (_reservaPaga)
          Padding(
            padding: EdgeInsets.fromLTRB(
              _margem,
              AppSpacing.normal,
              _margem,
              0,
            ),
            child: _aviso(
              icone: Phosphor.pixLogo,
              texto:
                  'Esta reserva já está paga. Se ficar mais cara, você paga só a diferença; se ficar mais barata, a diferença volta pelo Pix.',
            ),
          ),
        _servicos(state),
        _funcionarios(state),
        _quando(state),
        // Na edição a observação continua a de quando marcou.
        if (!_editando) _observacoes(),
        _regras(),
      ],
    );
  }

  /// Regras de cancelamento e atraso, visíveis antes de confirmar.
  Widget _regras() {
    final PoliticaAgendamentoModel politica = _politica;
    return Padding(
      key: const Key('regras_agendamento'),
      padding: EdgeInsets.fromLTRB(_margem, AppSpacing.big - 4, _margem, 0),
      child: appContainer(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.normal + 4),
        backgroundColor: AppEstilo.campoFundo,
        radius: BorderRadius.circular(AppRadii.externo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Phosphor.info, size: 18, color: AppEstilo.campoIcone),
                appSizedBox(width: 8),
                Expanded(
                  child: appText(
                    'Cancelamento e atraso',
                    bold: true,
                    fontSize: AppFontSizes.verySmall + 1,
                    color: local.AppColors.text,
                  ),
                ),
              ],
            ),
            appSizedBox(height: 6),
            appText(
              'Cancele pelo app até ${politica.prazoLabel} antes do horário. '
              'Depois disso ainda dá para cancelar, sem multa. '
              'Tolerância de atraso: ${politica.toleranciaLabel}.',
              color: local.AppColors.textSecondary,
              fontSize: AppFontSizes.verySmall,
            ),
            if (_mostrarRegras)
              for (final String regra in politica.regrasParaExibir)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: appText(
                    '• $regra',
                    color: local.AppColors.textSecondary,
                    fontSize: AppFontSizes.verySmall,
                  ),
                ),
            appSizedBox(height: 6),
            _linkAcao(
              _mostrarRegras ? 'Ocultar regras' : 'Ver todas as regras',
              () => setState(() => _mostrarRegras = !_mostrarRegras),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AgendamentoBloc, AgendamentoState>(
      bloc: bloc,
      listenWhen: (AgendamentoState anterior, AgendamentoState atual) =>
          atual is AgendamentoSuccessState,
      listener: (BuildContext context, AgendamentoState state) async {
        if (state is! AgendamentoSuccessState) {
          return;
        }

        // Se o horário for daqui a menos de 1h, o lembrete já aparece.
        LembreteAgendamento.instance.atualizar();
        if (state.editado) {
          await _reservaAlterada(context, state);
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
          return;
        }
        // Já está reservado; pagar agora é opcional (dá para pagar depois na agenda).
        await showOrdemCriadaModal(
          context: context,
          agendamentos: state.agendamentos,
        );
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      builder: (BuildContext context, AgendamentoState state) {
        return scaffold(
          title: _editando
              ? 'Editar reserva'
              : widget.nomeBarbearia ?? 'Agendar',
          centerTitle: true,
          background: local.AppColors.surface,
          appBarColor: local.AppColors.primaryBrand,
          safeBottom: false,
          body: _conteudo(state),
          bottomNavigationBar: state is AgendamentoReadyState
              ? _rodape(state)
              : null,
        );
      },
    );
  }

  /// Depois de salvar a edição: avisa o estorno ou já abre o Pix da diferença.
  Future<void> _reservaAlterada(
    BuildContext context,
    AgendamentoSuccessState state,
  ) async {
    final double? aPagar = state.valorAPagar;
    final int? idOrdem = int.tryParse(state.idOrdem ?? '');
    try {
      if (state.valorEstornado != null) {
        // Só fala em devolução confirmada quando o Mercado Pago confirmou.
        showSnackbarSuccess(
          message: state.valorEstornoEmProcessamento != null
              ? 'Reserva atualizada. Reembolso de ${formataDinheiro(state.valorEstornado!)} em processamento pelo Mercado Pago'
              : 'Reserva atualizada. Reembolso de ${formataDinheiro(state.valorEstornado!)} confirmado pelo Mercado Pago',
        );
      } else if (aPagar != null) {
        showSnackbarWarning(
          message:
              'Reserva atualizada. Falta pagar ${formataDinheiro(aPagar)} da diferença',
        );
      } else {
        showSnackbarSuccess(message: 'Reserva atualizada');
      }
    } catch (_) {}

    if (aPagar != null && idOrdem != null && context.mounted) {
      // Dá para fechar e pagar depois pela agenda.
      await showPagamentoOrdemModal(
        context: context,
        idOrdem: idOrdem,
        servicos: state.agendamentos.length,
        valorPrevisto: aPagar,
      );
    }
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    bloc.close();
    super.dispose();
  }
}
