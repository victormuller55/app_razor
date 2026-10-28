import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_blocos.dart';
import 'package:muller_package/muller_package.dart';

abstract class AgendamentoState {
  ErrorModel errorModel;
  AgendamentoContextoModel? contexto;

  /// Serviços escolhidos, na ordem em que serão feitos.
  List<int> idsServicos;

  /// Profissional escolhido para cada serviço.
  Map<int, int> funcionarioPorServico;

  /// Um horário por profissional, com os serviços dele seguidos.
  List<AgendamentoBloco> blocos;
  bool salvando;

  AgendamentoState({
    required this.errorModel,
    this.contexto,
    this.idsServicos = const <int>[],
    this.funcionarioPorServico = const <int, int>{},
    this.blocos = const <AgendamentoBloco>[],
    this.salvando = false,
  });

  /// Todo serviço tem profissional e todo bloco tem dia e horário.
  bool get completo =>
      idsServicos.isNotEmpty &&
      idsServicos.every(funcionarioPorServico.containsKey) &&
      blocos.isNotEmpty &&
      blocos.every((AgendamentoBloco bloco) => bloco.completo);
}

class AgendamentoInitialState extends AgendamentoState {
  AgendamentoInitialState({super.idsServicos})
    : super(errorModel: ErrorModel.empty());
}

class AgendamentoLoadingState extends AgendamentoState {
  AgendamentoLoadingState({super.idsServicos})
    : super(errorModel: ErrorModel.empty());
}

class AgendamentoReadyState extends AgendamentoState {
  AgendamentoReadyState({
    required AgendamentoContextoModel contexto,
    super.idsServicos,
    super.funcionarioPorServico,
    super.blocos,
    super.salvando,
  }) : super(errorModel: ErrorModel.empty(), contexto: contexto);
}

class AgendamentoSuccessState extends AgendamentoState {
  AgendamentoSuccessState({
    required this.agendamentos,
    this.idOrdem,
    this.editado = false,
    this.valorAPagar,
    this.valorEstornado,
  }) : super(errorModel: ErrorModel.empty());

  /// Um por serviço, na ordem em que serão feitos.
  final List<AgendamentoModel> agendamentos;

  /// Ordem de serviço criada quando foi mais de um serviço.
  final String? idOrdem;

  /// Foi a edição de uma reserva (não uma reserva nova).
  final bool editado;

  /// Reserva paga que ficou mais cara: a diferença a pagar.
  final double? valorAPagar;

  /// Reserva paga que ficou mais barata: o que volta para o cliente.
  final double? valorEstornado;

  AgendamentoModel get agendamento => agendamentos.first;
}

class AgendamentoErrorState extends AgendamentoState {
  AgendamentoErrorState({required super.errorModel, super.idsServicos});
}
