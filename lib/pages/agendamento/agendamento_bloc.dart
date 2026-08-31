import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_event.dart';
import 'package:app_razor/pages/agendamento/agendamento_service.dart';
import 'package:app_razor/pages/agendamento/agendamento_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetContexto = Future<AppResponse> Function({
  required int idBarbearia,
  bool forceRefresh,
});

typedef GetHorarios = Future<AppResponse> Function({
  required int idBarbearia,
  required int idFuncionarioBarbearia,
  required int idBarbeariaServico,
  required String data,
  bool forceRefresh,
});

typedef PostAgendamento = Future<AppResponse> Function({
  required int idBarbearia,
  required int idFuncionarioBarbearia,
  required int idBarbeariaServico,
  required String dataAgendamento,
  required String horaInicio,
  String? observacao,
});

class AgendamentoBloc extends Bloc<AgendamentoEvent, AgendamentoState> {
  AgendamentoBloc({
    required this.barbeariaId,
    int? servicoId,
    int? funcionarioId,
    GetContexto? getContexto,
    GetHorarios? getHorarios,
    PostAgendamento? postAgendamento,
  })  : _getContexto = getContexto ?? getAgendamentoContexto,
        _getHorarios = getHorarios ?? getHorariosDisponiveis,
        _postAgendamento = postAgendamento ?? criarAgendamento,
        super(
          AgendamentoInitialState(
            idServico: servicoId,
            idFuncionario: funcionarioId,
          ),
        ) {
    on<AgendamentoLoadEvent>(_load);
    on<AgendamentoSelectServicoEvent>(_selectServico);
    on<AgendamentoSelectFuncionarioEvent>(_selectFuncionario);
    on<AgendamentoSelectDataEvent>(_selectData);
    on<AgendamentoSelectHorarioEvent>(_selectHorario);
    on<AgendamentoSalvarEvent>(_salvar);
  }

  final int barbeariaId;
  final GetContexto _getContexto;
  final GetHorarios _getHorarios;
  final PostAgendamento _postAgendamento;

  Future<void> _load(
    AgendamentoLoadEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    emit(
      AgendamentoLoadingState(
        idServico: state.idServico,
        idFuncionario: state.idFuncionario,
      ),
    );

    try {
      final AppResponse response = await _getContexto(
        idBarbearia: barbeariaId,
        forceRefresh: event.forceRefresh,
      );
      final AgendamentoContextoModel contexto = AgendamentoContextoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      final int? idServico = _servicoValido(contexto, state.idServico);
      final int? idFuncionario = _funcionarioValido(
        contexto,
        idServico,
        state.idFuncionario,
      );

      emit(
        AgendamentoReadyState(
          contexto: contexto,
          idServico: idServico,
          idFuncionario: idFuncionario,
        ),
      );
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(
        AgendamentoErrorState(
          errorModel: errorModel,
          idServico: state.idServico,
          idFuncionario: state.idFuncionario,
        ),
      );
      _notifyErro(errorModel);
    }
  }

  Future<void> _selectServico(
    AgendamentoSelectServicoEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoState current = state;
    final AgendamentoContextoModel? contexto = current.contexto;

    if (contexto == null) {
      return;
    }

    final int? idFuncionario = _funcionarioValido(
      contexto,
      event.idServico,
      current.idFuncionario,
    );

    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idServico: event.idServico,
        idFuncionario: idFuncionario,
        data: current.data,
      ),
    );

    await _carregarHorarios(emit);
  }

  Future<void> _selectFuncionario(
    AgendamentoSelectFuncionarioEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoState current = state;
    final AgendamentoContextoModel? contexto = current.contexto;

    if (contexto == null) {
      return;
    }

    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idServico: current.idServico,
        idFuncionario: event.idFuncionario,
        data: current.data,
      ),
    );

    await _carregarHorarios(emit);
  }

  Future<void> _selectData(
    AgendamentoSelectDataEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoState current = state;
    final AgendamentoContextoModel? contexto = current.contexto;

    if (contexto == null) {
      return;
    }

    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idServico: current.idServico,
        idFuncionario: current.idFuncionario,
        data: event.data,
      ),
    );

    await _carregarHorarios(emit);
  }

  void _selectHorario(
    AgendamentoSelectHorarioEvent event,
    Emitter<AgendamentoState> emit,
  ) {
    final AgendamentoState current = state;
    final AgendamentoContextoModel? contexto = current.contexto;

    if (contexto == null) {
      return;
    }

    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idServico: current.idServico,
        idFuncionario: current.idFuncionario,
        data: current.data,
        horaInicio: event.horaInicio,
        horarios: current.horarios,
      ),
    );
  }

  Future<void> _salvar(
    AgendamentoSalvarEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoState current = state;
    final AgendamentoContextoModel? contexto = current.contexto;
    final int? idServico = current.idServico;
    final int? idFuncionario = current.idFuncionario;
    final DateTime? data = current.data;
    final String? horaInicio = current.horaInicio;
    final String? observacao = event.observacao?.trim();

    if (contexto == null ||
        idServico == null ||
        idFuncionario == null ||
        data == null ||
        horaInicio == null) {
      showSnackbarWarning(message: 'Escolha serviço, profissional, data e horário');
      return;
    }

    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idServico: idServico,
        idFuncionario: idFuncionario,
        data: data,
        horaInicio: horaInicio,
        horarios: current.horarios,
        salvando: true,
      ),
    );

    try {
      final AppResponse response = await _postAgendamento(
        idBarbearia: barbeariaId,
        idFuncionarioBarbearia: idFuncionario,
        idBarbeariaServico: idServico,
        dataAgendamento: _dataIso(data),
        horaInicio: horaInicio,
        observacao: observacao != null && observacao.isNotEmpty
            ? observacao
            : null,
      );
      final AgendamentoModel agendamento = AgendamentoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      emit(AgendamentoSuccessState(agendamento: agendamento));
      showSnackbarSuccess(message: 'Agendamento confirmado');
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(
        AgendamentoReadyState(
          contexto: contexto,
          idServico: idServico,
          idFuncionario: idFuncionario,
          data: data,
          horaInicio: horaInicio,
          horarios: current.horarios,
        ),
      );
      _notifyErro(errorModel);
    }
  }

  Future<void> _carregarHorarios(Emitter<AgendamentoState> emit) async {
    final AgendamentoState current = state;
    final AgendamentoContextoModel? contexto = current.contexto;
    final int? idServico = current.idServico;
    final int? idFuncionario = current.idFuncionario;
    final DateTime? data = current.data;

    if (contexto == null ||
        idServico == null ||
        idFuncionario == null ||
        data == null) {
      return;
    }

    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idServico: idServico,
        idFuncionario: idFuncionario,
        data: data,
        loadingHorarios: true,
      ),
    );

    try {
      final AppResponse response = await _getHorarios(
        idBarbearia: barbeariaId,
        idFuncionarioBarbearia: idFuncionario,
        idBarbeariaServico: idServico,
        data: _dataIso(data),
        forceRefresh: true,
      );
      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final dynamic horariosJson = json['horarios'];
      final List<AgendamentoHorarioModel> horarios = horariosJson is List
          ? horariosJson
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) => AgendamentoHorarioModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <AgendamentoHorarioModel>[];

      emit(
        AgendamentoReadyState(
          contexto: contexto,
          idServico: idServico,
          idFuncionario: idFuncionario,
          data: data,
          horarios: horarios,
        ),
      );
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(
        AgendamentoReadyState(
          contexto: contexto,
          idServico: idServico,
          idFuncionario: idFuncionario,
          data: data,
        ),
      );
      _notifyErro(errorModel);
    }
  }

  int? _servicoValido(AgendamentoContextoModel contexto, int? idServico) {
    if (idServico == null) {
      return null;
    }

    final bool existe = contexto.servicos.any(
      (AgendamentoServicoOpcao item) => item.id == idServico,
    );
    return existe ? idServico : null;
  }

  int? _funcionarioValido(
    AgendamentoContextoModel contexto,
    int? idServico,
    int? idFuncionario,
  ) {
    if (idFuncionario == null) {
      return null;
    }

    final Iterable<AgendamentoFuncionarioOpcao> candidatos = contexto.funcionarios
        .where(
          (AgendamentoFuncionarioOpcao item) =>
              item.id == idFuncionario && item.realizaServico(idServico),
        );

    return candidatos.isEmpty ? null : idFuncionario;
  }

  String _dataIso(DateTime data) {
    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');
    return '${data.year}-$mes-$dia';
  }

  void _notifyErro(ErrorModel errorModel) {
    try {
      if (AppContext.navigatorKey.currentContext == null) {
        return;
      }

      showSnackbarError(message: errorModel.mensagem);
    } catch (_) {}
  }
}
