import 'package:app_razor/app_config/const/app_colors.dart' as local;
import 'package:app_razor/app_config/const/app_fonts.dart';
import 'package:app_razor/app_config/const/phosphor_icons.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_bloc.dart';
import 'package:app_razor/pages/agendamento/agendamento_event.dart';
import 'package:app_razor/pages/agendamento/agendamento_state.dart';
import 'package:app_razor/pages/agendamento/widgets/profissional_select_card.dart';
import 'package:app_razor/pages/agendamento/widgets/servico_agendamento_card.dart';
import 'package:app_razor/widgets/app_elevated_button.dart';
import 'package:app_razor/widgets/app_loading.dart';
import 'package:flutter/cupertino.dart';
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

class AgendamentoPage extends StatefulWidget {
  const AgendamentoPage({
    super.key,
    required this.barbeariaId,
    this.nomeBarbearia,
    this.servicoId,
    this.funcionarioId,
  });

  final int barbeariaId;
  final String? nomeBarbearia;
  final int? servicoId;
  final int? funcionarioId;

  @override
  State<AgendamentoPage> createState() => _AgendamentoPageState();
}

class _AgendamentoPageState extends State<AgendamentoPage> {
  late final AgendamentoBloc bloc;
  final TextEditingController _observacaoController = TextEditingController();

  static const List<String> _diasSemana = <String>[
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

  @override
  void initState() {
    super.initState();
    bloc = AgendamentoBloc(
      barbeariaId: widget.barbeariaId,
      servicoId: widget.servicoId,
      funcionarioId: widget.funcionarioId,
    );
    bloc.add(AgendamentoLoadEvent());
  }

  Widget _cardSecao({
    required String titulo,
    required IconData icone,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.normal),
      child: appContainer(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.normal),
        backgroundColor: local.AppColors.white,
        radius: BorderRadius.circular(AppRadius.normal),
        shadow: local.AppColors.cardShadow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 16, color: local.AppColors.primary),
                appSizedBox(width: 6),
                appText(
                  titulo,
                  bold: true,
                  fontSize: AppFontSizes.small,
                  color: local.AppColors.text,
                ),
              ],
            ),
            appSizedBox(height: AppSpacing.normal),
            child,
          ],
        ),
      ),
    );
  }

  Widget _textoApoio(String texto) {
    return appText(
      texto,
      color: local.AppColors.textSecondary,
      fontSize: AppFontSizes.verySmall,
    );
  }

  Widget _chip({
    required String texto,
    required bool selecionado,
    required VoidCallback onTap,
    String? detalhe,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: appContainer(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: selecionado
            ? local.AppColors.primary.withValues(alpha: 0.12)
            : local.AppColors.inputBackground,
        radius: BorderRadius.circular(AppRadius.medium),
        border: selecionado
            ? Border.all(color: local.AppColors.primary)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            appText(
              texto,
              bold: true,
              color: selecionado ? local.AppColors.primary : local.AppColors.text,
              fontSize: AppFontSizes.verySmall,
            ),
            if (detalhe != null)
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: appText(
                  detalhe,
                  color: local.AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _servicos(AgendamentoReadyState state) {
    if (widget.servicoId != null) {
      final Iterable<AgendamentoServicoOpcao> escolhidos = state.contexto!.servicos
          .where((AgendamentoServicoOpcao item) => item.id == widget.servicoId);
      final AgendamentoServicoOpcao? servico =
          escolhidos.isEmpty ? null : escolhidos.first;

      if (servico == null) {
        return const SizedBox.shrink();
      }

      return _cardSecao(
        titulo: 'Serviço',
        icone: Phosphor.scissors,
        child: servicoAgendamentoCard(servico: servico),
      );
    }

    return _cardSecao(
      titulo: 'Serviço',
      icone: Phosphor.scissors,
      child: Column(
        children: [
          for (final AgendamentoServicoOpcao servico
              in state.contexto!.servicos) ...[
            if (servico != state.contexto!.servicos.first)
              appSizedBox(height: AppSpacing.small),
            servicoAgendamentoCard(
              servico: servico,
              selecionado: servico.id != null && servico.id == state.idServico,
              onTap: servico.id == null
                  ? () {}
                  : () => bloc.add(AgendamentoSelectServicoEvent(servico.id!)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _funcionarios(AgendamentoReadyState state) {
    final List<AgendamentoFuncionarioOpcao> opcoes = state.contexto!.funcionarios
        .where(
          (AgendamentoFuncionarioOpcao item) =>
              item.realizaServico(state.idServico),
        )
        .toList();

    if (state.idServico == null) {
      return _cardSecao(
        titulo: 'Profissional',
        icone: Phosphor.user,
        child: _textoApoio('Escolha um serviço para ver os profissionais'),
      );
    }

    if (opcoes.isEmpty) {
      return _cardSecao(
        titulo: 'Profissional',
        icone: Phosphor.user,
        child: _textoApoio('Nenhum profissional disponível para este serviço'),
      );
    }

    return _cardSecao(
      titulo: 'Profissional',
      icone: Phosphor.user,
      child: SizedBox(
        height: 148,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: opcoes.length,
          separatorBuilder: (_, _) => appSizedBox(width: 8),
          itemBuilder: (BuildContext context, int index) {
            final AgendamentoFuncionarioOpcao funcionario = opcoes[index];
            final int? id = funcionario.id;
            return profissionalSelectCard(
              funcionario: funcionario,
              selecionado: id != null && id == state.idFuncionario,
              onTap: id == null
                  ? () {}
                  : () => bloc.add(AgendamentoSelectFuncionarioEvent(id)),
            );
          },
        ),
      ),
    );
  }

  Widget _datas(AgendamentoReadyState state) {
    final DateTime hoje = DateTime.now();
    final List<DateTime> dias = List<DateTime>.generate(
      14,
      (int index) => DateTime(hoje.year, hoje.month, hoje.day).add(
        Duration(days: index + 1),
      ),
    );

    return _cardSecao(
      titulo: 'Data',
      icone: Phosphor.calendarBlank,
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dias.length,
          separatorBuilder: (_, _) => appSizedBox(width: 8),
          itemBuilder: (BuildContext context, int index) {
            final DateTime dia = dias[index];
            final bool selecionado = state.data != null &&
                state.data!.year == dia.year &&
                state.data!.month == dia.month &&
                state.data!.day == dia.day;

            return _chip(
              texto: _diasSemana[dia.weekday - 1],
              detalhe: '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}',
              selecionado: selecionado,
              onTap: () => bloc.add(AgendamentoSelectDataEvent(dia)),
            );
          },
        ),
      ),
    );
  }

  String? _labelHora(String? horaInicio) {
    if (horaInicio == null || horaInicio.length < 5) {
      return null;
    }

    return horaInicio.substring(0, 5);
  }

  TimeOfDay _horaInicial(String? horaInicio) {
    final String? label = _labelHora(horaInicio);

    if (label == null) {
      return TimeOfDay.now();
    }

    final List<String> partes = label.split(':');
    final int? hora = int.tryParse(partes.first);
    final int? minuto = partes.length > 1 ? int.tryParse(partes[1]) : null;

    if (hora == null || minuto == null) {
      return TimeOfDay.now();
    }

    return TimeOfDay(hour: hora, minute: minuto);
  }

  String _horaApi(TimeOfDay hora) {
    final String horas = hora.hour.toString().padLeft(2, '0');
    final String minutos = hora.minute.toString().padLeft(2, '0');
    return '$horas:$minutos:00';
  }

  Future<TimeOfDay?> _abrirSeletorIos(TimeOfDay inicial) {
    TimeOfDay selecionado = inicial;

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(selecionado),
                      child: const Text('OK'),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: DateTime(
                      2020,
                      1,
                      1,
                      inicial.hour,
                      inicial.minute,
                    ),
                    onDateTimeChanged: (DateTime data) {
                      selecionado = TimeOfDay(
                        hour: data.hour,
                        minute: data.minute,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> _abrirSeletorAndroid(TimeOfDay inicial) {
    return showTimePicker(
      context: context,
      initialTime: inicial,
      helpText: 'Selecione o horário',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minuto',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: local.AppColors.primary,
                onPrimary: local.AppColors.white,
                surface: local.AppColors.white,
                onSurface: local.AppColors.text,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
  }

  Future<void> _abrirSeletorHorario(AgendamentoReadyState state) async {
    final TimeOfDay inicial = _horaInicial(state.horaInicio);
    final bool ios = Theme.of(context).platform == TargetPlatform.iOS;
    final TimeOfDay? escolhido = ios
        ? await _abrirSeletorIos(inicial)
        : await _abrirSeletorAndroid(inicial);

    if (escolhido == null) {
      return;
    }

    bloc.add(AgendamentoSelectHorarioEvent(_horaApi(escolhido)));
  }

  Widget _campoHorario({
    required String? horaInicio,
    required VoidCallback onTap,
  }) {
    final String? label = _labelHora(horaInicio);
    final bool selecionado = label != null;

    return GestureDetector(
      onTap: onTap,
      child: appContainer(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: selecionado
            ? local.AppColors.primary.withValues(alpha: 0.12)
            : local.AppColors.inputBackground,
        radius: BorderRadius.circular(AppRadius.medium),
        border: selecionado ? Border.all(color: local.AppColors.primary) : null,
        child: Row(
          children: [
            Expanded(
              child: appText(
                label ?? 'Escolher horário',
                bold: true,
                color: selecionado
                    ? local.AppColors.primary
                    : local.AppColors.textSecondary,
                fontSize: AppFontSizes.small,
              ),
            ),
            Icon(
              Phosphor.clock,
              size: 18,
              color: selecionado
                  ? local.AppColors.primary
                  : local.AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _horarios(AgendamentoReadyState state) {
    if (state.idServico == null ||
        state.idFuncionario == null ||
        state.data == null) {
      return _cardSecao(
        titulo: 'Horário',
        icone: Phosphor.clock,
        child: _textoApoio('Escolha profissional e data para ver os horários'),
      );
    }

    return _cardSecao(
      titulo: 'Horário',
      icone: Phosphor.clock,
      child: _campoHorario(
        horaInicio: state.horaInicio,
        onTap: () => _abrirSeletorHorario(state),
      ),
    );
  }

  Widget _observacoes() {
    return _cardSecao(
      titulo: 'Observações',
      icone: Phosphor.notePencil,
      child: TextField(
        controller: _observacaoController,
        minLines: 3,
        maxLines: 5,
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
            color: local.AppColors.textSecondary,
            fontSize: AppFontSizes.verySmall,
          ),
          filled: true,
          fillColor: local.AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide(color: local.AppColors.primary),
          ),
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _conteudo(AgendamentoState state) {
    if (state is AgendamentoSuccessState) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.medium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Phosphor.checkCircle, size: 48, color: local.AppColors.primary),
              appSizedBox(height: AppSpacing.normal),
              appText(
                'Horário reservado',
                bold: true,
                fontSize: AppFontSizes.medium,
                color: local.AppColors.text,
              ),
              appSizedBox(height: AppSpacing.small),
              appText(
                state.agendamento.periodoLabel,
                color: local.AppColors.textSecondary,
                fontSize: AppFontSizes.verySmall,
              ),
            ],
          ),
        ),
      );
    }

    if (state is AgendamentoErrorState) {
      return appError(
        state.errorModel,
        function: () => bloc.add(AgendamentoLoadEvent(forceRefresh: true)),
      );
    }

    if (state is! AgendamentoReadyState || state.contexto == null) {
      return appLoadingRazor();
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.normal,
        AppSpacing.medium,
        AppSpacing.giant,
      ),
      children: [
        _servicos(state),
        _funcionarios(state),
        _datas(state),
        _horarios(state),
        _observacoes(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AgendamentoBloc, AgendamentoState>(
      bloc: bloc,
      listener: (BuildContext context, AgendamentoState state) {
        if (state is AgendamentoSuccessState) {
          Navigator.of(context).pop();
        }
      },
      builder: (BuildContext context, AgendamentoState state) {
        final bool podeSalvar = state is AgendamentoReadyState &&
            state.idServico != null &&
            state.idFuncionario != null &&
            state.data != null &&
            state.horaInicio != null &&
            !state.salvando;

        return scaffold(
          title: widget.nomeBarbearia ?? 'Agendar',
          background: local.AppColors.background,
          appBarColor: local.AppColors.primary,
          body: _conteudo(state),
          bottomNavigationBar: state is AgendamentoReadyState
              ? SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      0,
                      AppSpacing.medium,
                      AppSpacing.normal,
                    ),
                    child: appElevatedButtonRazor(
                      title: state.salvando ? 'Salvando...' : 'Confirmar',
                      onTap: podeSalvar
                          ? () => bloc.add(
                                AgendamentoSalvarEvent(
                                  observacao: _observacaoController.text,
                                ),
                              )
                          : () {},
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    bloc.close();
    super.dispose();
  }
}
