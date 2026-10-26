import 'package:app_razor/models/agendamento_model.dart';
import 'package:muller_package/muller_package.dart';

abstract class AgendamentoState {
  ErrorModel errorModel;
  AgendamentoContextoModel? contexto;
  int? idServico;
  int? idFuncionario;
  DateTime? data;
  String? horaInicio;
  List<AgendamentoHorarioModel> horarios;

  /// Por que não há horário livre na data (barbearia fechada, folga...).
  String? motivoHorarios;
  bool loadingHorarios;
  bool salvando;

  AgendamentoState({
    required this.errorModel,
    this.contexto,
    this.idServico,
    this.idFuncionario,
    this.data,
    this.horaInicio,
    this.horarios = const <AgendamentoHorarioModel>[],
    this.motivoHorarios,
    this.loadingHorarios = false,
    this.salvando = false,
  });
}

class AgendamentoInitialState extends AgendamentoState {
  AgendamentoInitialState({
    super.idServico,
    super.idFuncionario,
  }) : super(errorModel: ErrorModel.empty());
}

class AgendamentoLoadingState extends AgendamentoState {
  AgendamentoLoadingState({
    super.idServico,
    super.idFuncionario,
  }) : super(errorModel: ErrorModel.empty());
}

class AgendamentoReadyState extends AgendamentoState {
  AgendamentoReadyState({
    required AgendamentoContextoModel contexto,
    super.idServico,
    super.idFuncionario,
    super.data,
    super.horaInicio,
    super.horarios,
    super.motivoHorarios,
    super.loadingHorarios,
    super.salvando,
  }) : super(errorModel: ErrorModel.empty(), contexto: contexto);
}

class AgendamentoSuccessState extends AgendamentoState {
  AgendamentoSuccessState({required this.agendamento})
      : super(errorModel: ErrorModel.empty());

  final AgendamentoModel agendamento;
}

class AgendamentoErrorState extends AgendamentoState {
  AgendamentoErrorState({
    required super.errorModel,
    super.idServico,
    super.idFuncionario,
  });
}
