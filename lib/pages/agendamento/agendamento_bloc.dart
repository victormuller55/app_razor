import 'dart:convert';

import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/models/agendamento_model.dart';
import 'package:app_razor/pages/agendamento/agendamento_blocos.dart';
import 'package:app_razor/pages/agendamento/agendamento_event.dart';
import 'package:app_razor/pages/agendamento/agendamento_service.dart';
import 'package:app_razor/pages/agendamento/agendamento_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muller_package/muller_package.dart';

typedef GetContexto =
    Future<AppResponse> Function({required int idBarbearia, bool forceRefresh});

typedef GetHorarios =
    Future<AppResponse> Function({
      required int idBarbearia,
      required int idFuncionarioBarbearia,
      required List<int> idsBarbeariaServico,
      required String data,
      List<int> ignorar,
      bool forceRefresh,
    });

typedef PostAgendamento =
    Future<AppResponse> Function({
      required int idBarbearia,
      required int idFuncionarioBarbearia,
      required int idBarbeariaServico,
      required String dataAgendamento,
      required String horaInicio,
      String? observacao,
    });

typedef PostOrdem =
    Future<AppResponse> Function({
      required int idBarbearia,
      required List<Map<String, dynamic>> itens,
      String? observacao,
    });

typedef PutEdicao =
    Future<AppResponse> Function({
      int? idOrdem,
      required int idAgendamento,
      required List<Map<String, dynamic>> itens,
    });

/// Reserva que está sendo editada: os serviços dela que ainda podem mudar.
class AgendamentoEdicao {
  AgendamentoEdicao({required this.itens, this.idOrdem});

  /// Agendados e por vir, na ordem em que acontecem.
  final List<AgendamentoModel> itens;

  /// Ordem de serviço da reserva; null quando é um agendamento avulso.
  final int? idOrdem;

  int get idAgendamento => itens.first.id!;

  List<int> get ids =>
      itens.map((AgendamentoModel item) => item.id).whereType<int>().toList();

  List<int> get idsServicos => itens
      .map((AgendamentoModel item) => item.idBarbeariaServico)
      .whereType<int>()
      .toList();
}

/// Duração usada quando nem a API nem o serviço informam.
const int _duracaoPadrao = 30;

class AgendamentoBloc extends Bloc<AgendamentoEvent, AgendamentoState> {
  AgendamentoBloc({
    required this.barbeariaId,
    int? servicoId,
    int? funcionarioId,
    GetContexto? getContexto,
    GetHorarios? getHorarios,
    PostAgendamento? postAgendamento,
    PostOrdem? postOrdem,
    PutEdicao? putEdicao,
    this.edicao,
    DateTime Function()? agora,
  }) : _getContexto = getContexto ?? getAgendamentoContexto,
       _getHorarios = getHorarios ?? getHorariosDisponiveis,
       _postAgendamento = postAgendamento ?? criarAgendamento,
       _postOrdem = postOrdem ?? criarOrdemServico,
       _putEdicao = putEdicao ?? editarReserva,
       _agora = agora ?? DateTime.now,
       _funcionarioPreferido = funcionarioId,
       super(
         AgendamentoInitialState(
           idsServicos: edicao != null
               ? edicao.idsServicos
               : servicoId == null
               ? const <int>[]
               : <int>[servicoId],
         ),
       ) {
    on<AgendamentoLoadEvent>(_load);
    on<AgendamentoToggleServicoEvent>(_toggleServico);
    on<AgendamentoSelectFuncionarioEvent>(_selectFuncionario);
    on<AgendamentoSelectDataEvent>(_selectData);
    on<AgendamentoSelectHorarioEvent>(_selectHorario);
    on<AgendamentoSalvarEvent>(_salvar);
  }

  final int barbeariaId;
  final GetContexto _getContexto;
  final GetHorarios _getHorarios;
  final PostAgendamento _postAgendamento;
  final PostOrdem _postOrdem;
  final PutEdicao _putEdicao;

  /// Reserva sendo editada; null quando é uma reserva nova.
  final AgendamentoEdicao? edicao;

  /// Dia e horário que cada profissional já tinha na reserva editada.
  final Map<int, ({DateTime data, String hora})> _horasDaEdicao =
      <int, ({DateTime data, String hora})>{};
  final DateTime Function() _agora;

  /// Profissional vindo do perfil da barbearia, sugerido quando faz o serviço.
  final int? _funcionarioPreferido;

  DateTime get _hoje {
    final DateTime agora = _agora();
    return DateTime(agora.year, agora.month, agora.day);
  }

  // ---------------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------------

  Future<void> _load(
    AgendamentoLoadEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final List<int> pedidos = state.idsServicos;
    emit(AgendamentoLoadingState(idsServicos: pedidos));

    try {
      final AppResponse response = await _getContexto(
        idBarbearia: barbeariaId,
        forceRefresh: event.forceRefresh,
      );
      final AgendamentoContextoModel contexto =
          AgendamentoContextoModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );

      final List<int> idsValidos = pedidos
          .where(
            (int id) => contexto.servicos.any(
              (AgendamentoServicoOpcao item) => item.id == id,
            ),
          )
          .toList();
      // Barbearia com um serviço só já começa com ele marcado.
      final List<int> ids =
          idsValidos.isEmpty &&
              contexto.servicos.length == 1 &&
              contexto.servicos.first.id != null
          ? <int>[contexto.servicos.first.id!]
          : idsValidos;

      final Map<int, int> mapa = <int, int>{};
      final List<AgendamentoBloco> iniciais = <AgendamentoBloco>[];
      final AgendamentoEdicao? reserva = edicao;
      if (reserva != null) {
        for (final AgendamentoModel item in reserva.itens) {
          final int? idServico = item.idBarbeariaServico;
          final int? idFuncionario = item.idFuncionarioBarbearia;
          final DateTime? inicio = item.dataHora;
          if (idServico == null || idFuncionario == null || inicio == null) {
            continue;
          }
          mapa[idServico] = idFuncionario;
          if (!_horasDaEdicao.containsKey(idFuncionario)) {
            final DateTime dia = DateTime(
              inicio.year,
              inicio.month,
              inicio.day,
            );
            _horasDaEdicao[idFuncionario] = (
              data: dia,
              hora: horaDeMinutos(inicio.hour * 60 + inicio.minute),
            );
            // Sem serviços: só leva o dia para o bloco novo, que busca a grade.
            iniciais.add(
              AgendamentoBloco(
                idFuncionario: idFuncionario,
                idsServicos: const <int>[],
                data: dia,
              ),
            );
          }
        }
      } else {
        for (final int id in ids) {
          final int? sugerido = _sugerirFuncionario(contexto, id, mapa);
          if (sugerido != null) {
            mapa[id] = sugerido;
          }
        }
      }

      await _aplicar(
        emit,
        contexto: contexto,
        idsServicos: ids,
        funcionarioPorServico: mapa,
        blocosAtuais: iniciais,
      );
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      emit(AgendamentoErrorState(errorModel: errorModel, idsServicos: pedidos));
      _notifyErro(errorModel);
    }
  }

  Future<void> _toggleServico(
    AgendamentoToggleServicoEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoContextoModel? contexto = state.contexto;
    if (contexto == null || state.salvando) {
      return;
    }

    final List<int> ids = List<int>.from(state.idsServicos);
    final Map<int, int> mapa = Map<int, int>.from(state.funcionarioPorServico);

    if (ids.remove(event.idServico)) {
      mapa.remove(event.idServico);
    } else {
      ids.add(event.idServico);
      final int? sugerido = _sugerirFuncionario(
        contexto,
        event.idServico,
        mapa,
      );
      if (sugerido != null) {
        mapa[event.idServico] = sugerido;
      }
    }

    await _aplicar(
      emit,
      contexto: contexto,
      idsServicos: ids,
      funcionarioPorServico: mapa,
      blocosAtuais: state.blocos,
    );
  }

  Future<void> _selectFuncionario(
    AgendamentoSelectFuncionarioEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoContextoModel? contexto = state.contexto;
    if (contexto == null || state.salvando) {
      return;
    }

    final AgendamentoFuncionarioOpcao? funcionario = _funcionario(
      contexto,
      event.idFuncionario,
    );
    if (funcionario == null) {
      return;
    }

    final Map<int, int> mapa = Map<int, int>.from(state.funcionarioPorServico);
    final Iterable<int> alvos = event.idServico != null
        ? <int>[event.idServico!]
        : state.idsServicos;

    for (final int idServico in alvos) {
      if (funcionario.realizaServico(idServico)) {
        mapa[idServico] = event.idFuncionario;
      }
    }

    await _aplicar(
      emit,
      contexto: contexto,
      idsServicos: state.idsServicos,
      funcionarioPorServico: mapa,
      blocosAtuais: state.blocos,
    );
  }

  Future<void> _selectData(
    AgendamentoSelectDataEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoContextoModel? contexto = state.contexto;
    if (contexto == null || state.salvando) {
      return;
    }

    final List<AgendamentoBloco> blocos = state.blocos
        .map(
          (AgendamentoBloco bloco) => bloco.idFuncionario == event.idFuncionario
              ? bloco.copyWith(
                  data: event.data,
                  limparHora: true,
                  horarios: const <AgendamentoHorarioModel>[],
                  grades: const <List<AgendamentoHorarioModel>>[],
                  limparMotivo: true,
                )
              : bloco,
        )
        .toList();

    _emitirPronto(emit, contexto: contexto, blocos: _recalcular(blocos));
    await _carregarHorarios(emit, event.idFuncionario);
  }

  void _selectHorario(
    AgendamentoSelectHorarioEvent event,
    Emitter<AgendamentoState> emit,
  ) {
    final AgendamentoContextoModel? contexto = state.contexto;
    if (contexto == null || state.salvando) {
      return;
    }

    final List<AgendamentoBloco> blocos = state.blocos
        .map(
          (AgendamentoBloco bloco) => bloco.idFuncionario == event.idFuncionario
              ? bloco.copyWith(horaInicio: event.horaInicio)
              : bloco,
        )
        .toList();

    _emitirPronto(emit, contexto: contexto, blocos: _recalcular(blocos));
  }

  Future<void> _salvar(
    AgendamentoSalvarEvent event,
    Emitter<AgendamentoState> emit,
  ) async {
    final AgendamentoState current = state;
    final AgendamentoContextoModel? contexto = current.contexto;

    if (contexto == null || current.salvando) {
      return;
    }

    if (!current.completo) {
      showSnackbarWarning(
        message: 'Escolha serviço, profissional, data e horário',
      );
      return;
    }

    final String? observacao = event.observacao?.trim();
    _emitirPronto(
      emit,
      contexto: contexto,
      blocos: current.blocos,
      salvando: true,
    );

    // Do mais cedo para o mais tarde, cada serviço começa onde o anterior termina.
    final List<AgendamentoBloco> blocos =
        List<AgendamentoBloco>.from(current.blocos)..sort((a, b) {
          final int porData = a.data!.compareTo(b.data!);
          return porData != 0
              ? porData
              : a.intervalo!.inicio.compareTo(b.intervalo!.inicio);
        });
    final List<Map<String, dynamic>> itens = <Map<String, dynamic>>[];
    for (final AgendamentoBloco bloco in blocos) {
      int inicio = bloco.intervalo!.inicio;
      for (final int idServico in bloco.idsServicos) {
        itens.add(<String, dynamic>{
          'id_funcionario_barbearia': bloco.idFuncionario,
          'id_barbearia_servico': idServico,
          'data_agendamento': _dataIso(bloco.data!),
          'hora_inicio': horaDeMinutos(inicio),
        });
        inicio += bloco.duracoes[idServico] ?? _duracaoPadrao;
      }
    }
    final String? texto = observacao != null && observacao.isNotEmpty
        ? observacao
        : null;

    final List<AgendamentoModel> criados;
    String? idOrdem;
    final AgendamentoEdicao? reserva = edicao;

    if (reserva != null) {
      // Serviço que já estava na reserva continua sendo o mesmo agendamento.
      final Map<int, int> idPorServico = <int, int>{
        for (final AgendamentoModel item in reserva.itens)
          if (item.idBarbeariaServico != null && item.id != null)
            item.idBarbeariaServico!: item.id!,
      };
      for (final Map<String, dynamic> item in itens) {
        final int? id = idPorServico.remove(item['id_barbearia_servico']);
        if (id != null) {
          item['id'] = id;
        }
      }

      try {
        final AppResponse response = await _putEdicao(
          idOrdem: reserva.idOrdem,
          idAgendamento: reserva.idAgendamento,
          itens: itens,
        );
        final Map<String, dynamic> ordem =
            jsonDecode(response.body) as Map<String, dynamic>;
        emit(
          AgendamentoSuccessState(
            agendamentos: _agendamentosDaOrdem(
              ordem,
            ).where((AgendamentoModel item) => !item.cancelado).toList(),
            idOrdem: ordem['id'] == null ? null : '${ordem['id']}',
            editado: true,
            valorAPagar: _valor(ordem['valor_a_pagar']),
            valorEstornado: _valor(ordem['valor_estornado']),
            valorEstornoEmProcessamento: _valor(
              ordem['valor_estorno_em_processamento'],
            ),
          ),
        );
      } catch (e) {
        final ErrorModel errorModel = errorModelFromApi(e);
        _emitirPronto(emit, contexto: contexto, blocos: current.blocos);
        await _falhaAoSalvar(emit, errorModel);
      }
      return;
    }

    try {
      if (itens.length == 1) {
        final Map<String, dynamic> item = itens.single;
        final AppResponse response = await _postAgendamento(
          idBarbearia: barbeariaId,
          idFuncionarioBarbearia: item['id_funcionario_barbearia'] as int,
          idBarbeariaServico: item['id_barbearia_servico'] as int,
          dataAgendamento: item['data_agendamento'] as String,
          horaInicio: item['hora_inicio'] as String,
          observacao: texto,
        );
        criados = <AgendamentoModel>[
          AgendamentoModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          ),
        ];
      } else {
        // A API marca tudo ou nada: se um serviço não couber, nenhum entra.
        final AppResponse response = await _postOrdem(
          idBarbearia: barbeariaId,
          itens: itens,
          observacao: texto,
        );
        final Map<String, dynamic> ordem =
            jsonDecode(response.body) as Map<String, dynamic>;
        idOrdem = ordem['id'] == null ? null : '${ordem['id']}';
        criados = _agendamentosDaOrdem(ordem);
      }
    } catch (e) {
      final ErrorModel errorModel = errorModelFromApi(e);
      _emitirPronto(emit, contexto: contexto, blocos: current.blocos);
      await _falhaAoSalvar(emit, errorModel);
      return;
    }

    emit(AgendamentoSuccessState(agendamentos: criados, idOrdem: idOrdem));
    try {
      showSnackbarSuccess(
        message: criados.length > 1
            ? 'Ordem de serviço criada'
            : 'Agendamento confirmado',
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Montagem dos blocos
  // ---------------------------------------------------------------------------

  /// Remonta os blocos a partir dos serviços e profissionais e busca os
  /// horários dos blocos que mudaram.
  Future<void> _aplicar(
    Emitter<AgendamentoState> emit, {
    required AgendamentoContextoModel contexto,
    required List<int> idsServicos,
    required Map<int, int> funcionarioPorServico,
    required List<AgendamentoBloco> blocosAtuais,
  }) async {
    final List<AgendamentoBloco> blocos = <AgendamentoBloco>[];
    final List<int> recarregar = <int>[];

    for (final ({int idFuncionario, List<int> idsServicos}) grupo
        in agrupaPorFuncionario(idsServicos, funcionarioPorServico)) {
      final Iterable<AgendamentoBloco> anteriores = blocosAtuais.where(
        (AgendamentoBloco bloco) => bloco.idFuncionario == grupo.idFuncionario,
      );
      final AgendamentoBloco? anterior = anteriores.isEmpty
          ? null
          : anteriores.first;

      if (anterior != null &&
          _mesmaLista(anterior.idsServicos, grupo.idsServicos)) {
        blocos.add(anterior);
        continue;
      }

      blocos.add(
        AgendamentoBloco(
          idFuncionario: grupo.idFuncionario,
          idsServicos: grupo.idsServicos,
          data: anterior?.data ?? _hoje,
        ),
      );
      recarregar.add(grupo.idFuncionario);
    }

    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idsServicos: idsServicos,
        funcionarioPorServico: funcionarioPorServico,
        blocos: _recalcular(blocos),
      ),
    );

    await Future.wait(recarregar.map((int id) => _carregarHorarios(emit, id)));
  }

  Future<void> _carregarHorarios(
    Emitter<AgendamentoState> emit,
    int idFuncionario,
  ) async {
    final AgendamentoContextoModel? contexto = state.contexto;
    final AgendamentoBloco? bloco = _bloco(idFuncionario);

    if (contexto == null || bloco == null || bloco.data == null) {
      return;
    }

    _atualizarBloco(
      emit,
      idFuncionario,
      (AgendamentoBloco atual) => atual.copyWith(
        loadingHorarios: true,
        limparHora: true,
        limparMotivo: true,
      ),
    );

    try {
      // Com vários serviços, a API já devolve as faixas com a soma das
      // durações (o profissional faz um em seguida do outro).
      final AppResponse resposta = await _getHorarios(
        idBarbearia: barbeariaId,
        idFuncionarioBarbearia: idFuncionario,
        idsBarbeariaServico: bloco.idsServicos,
        data: _dataIso(bloco.data!),
        ignorar: edicao?.ids ?? const <int>[],
        forceRefresh: true,
      );
      final Map<String, dynamic> json =
          jsonDecode(resposta.body) as Map<String, dynamic>;
      final List<AgendamentoHorarioModel> grade = _grade(json['horarios']);
      final dynamic duracaoApi = json['duracao_minutos'];
      final dynamic motivoApi = json['motivo'];
      final String? motivo = motivoApi is String && motivoApi.isNotEmpty
          ? motivoApi
          : null;

      // A duração de cada serviço encadeia os horários de início na reserva.
      final Map<int, int> duracoes = <int, int>{
        for (final int idServico in bloco.idsServicos)
          idServico:
              _servico(contexto, idServico)?.duracaoMinutos ?? _duracaoPadrao,
      };
      final int total =
          (duracaoApi is num ? duracaoApi.toInt() : null) ??
          duracaoDaGrade(grade) ??
          duracoes.values.fold<int>(0, (int soma, int d) => soma + d);
      if (bloco.idsServicos.length == 1) {
        duracoes[bloco.idsServicos.single] = total;
      }
      final List<List<AgendamentoHorarioModel>> grades =
          <List<AgendamentoHorarioModel>>[grade];

      // Enquanto buscava, o cliente pode ter trocado o dia ou os serviços.
      if (!_aindaValido(idFuncionario, bloco)) {
        return;
      }

      _atualizarBloco(
        emit,
        idFuncionario,
        (AgendamentoBloco atual) => atual.copyWith(
          grades: grades,
          duracoes: duracoes,
          motivoHorarios: motivo,
          loadingHorarios: false,
          // Na edição, o dia original volta com o horário que já estava marcado.
          horaInicio: atual.horaInicio ?? _horaDaEdicao(atual),
        ),
      );
    } catch (e) {
      if (!_aindaValido(idFuncionario, bloco)) {
        return;
      }

      _atualizarBloco(
        emit,
        idFuncionario,
        (AgendamentoBloco atual) => atual.copyWith(loadingHorarios: false),
      );
      _notifyErro(errorModelFromApi(e));
    }
  }

  /// Recalcula os horários de cada bloco: os serviços dele seguidos e sem
  /// bater com o horário já escolhido em outro bloco do mesmo dia.
  List<AgendamentoBloco> _recalcular(List<AgendamentoBloco> blocos) {
    return blocos.map((AgendamentoBloco bloco) {
      if (bloco.grades.isEmpty) {
        return bloco;
      }

      final List<({int inicio, int fim})> ocupados = <({int inicio, int fim})>[
        for (final AgendamentoBloco outro in blocos)
          if (outro.idFuncionario != bloco.idFuncionario &&
              outro.data == bloco.data &&
              outro.intervalo != null)
            outro.intervalo!,
      ];
      final List<AgendamentoHorarioModel> horarios = combinaHorarios(
        grades: bloco.grades,
        duracaoTotal: bloco.duracaoTotal,
        ocupados: ocupados,
      );
      final bool horaContinuaLivre = horarios.any(
        (AgendamentoHorarioModel item) =>
            item.disponivel && item.horaInicio == bloco.horaInicio,
      );

      return bloco.copyWith(horarios: horarios, limparHora: !horaContinuaLivre);
    }).toList();
  }

  void _atualizarBloco(
    Emitter<AgendamentoState> emit,
    int idFuncionario,
    AgendamentoBloco Function(AgendamentoBloco atual) alterar,
  ) {
    final AgendamentoContextoModel? contexto = state.contexto;
    if (contexto == null) {
      return;
    }

    _emitirPronto(
      emit,
      contexto: contexto,
      blocos: _recalcular(
        state.blocos
            .map(
              (AgendamentoBloco bloco) =>
                  bloco.idFuncionario == idFuncionario ? alterar(bloco) : bloco,
            )
            .toList(),
      ),
    );
  }

  void _emitirPronto(
    Emitter<AgendamentoState> emit, {
    required AgendamentoContextoModel contexto,
    required List<AgendamentoBloco> blocos,
    bool salvando = false,
  }) {
    emit(
      AgendamentoReadyState(
        contexto: contexto,
        idsServicos: state.idsServicos,
        funcionarioPorServico: state.funcionarioPorServico,
        blocos: blocos,
        salvando: salvando,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Apoio
  // ---------------------------------------------------------------------------

  /// Mantém junto com quem já foi escolhido (serviços seguidos); senão, o
  /// profissional do perfil ou o único que faz o serviço.
  int? _sugerirFuncionario(
    AgendamentoContextoModel contexto,
    int idServico,
    Map<int, int> mapa,
  ) {
    final List<AgendamentoFuncionarioOpcao> aptos = contexto.funcionarios
        .where(
          (AgendamentoFuncionarioOpcao item) =>
              item.id != null && item.realizaServico(idServico),
        )
        .toList();

    for (final int jaEscolhido in mapa.values) {
      if (aptos.any(
        (AgendamentoFuncionarioOpcao item) => item.id == jaEscolhido,
      )) {
        return jaEscolhido;
      }
    }

    if (_funcionarioPreferido != null &&
        aptos.any(
          (AgendamentoFuncionarioOpcao item) =>
              item.id == _funcionarioPreferido,
        )) {
      return _funcionarioPreferido;
    }

    return aptos.length == 1 ? aptos.first.id : null;
  }

  String? _horaDaEdicao(AgendamentoBloco bloco) {
    final ({DateTime data, String hora})? original =
        _horasDaEdicao[bloco.idFuncionario];
    return original != null && original.data == bloco.data
        ? original.hora
        : null;
  }

  bool _aindaValido(int idFuncionario, AgendamentoBloco pedido) {
    final AgendamentoBloco? atual = _bloco(idFuncionario);
    return atual != null &&
        atual.data == pedido.data &&
        _mesmaLista(atual.idsServicos, pedido.idsServicos);
  }

  AgendamentoBloco? _bloco(int idFuncionario) {
    final Iterable<AgendamentoBloco> itens = state.blocos.where(
      (AgendamentoBloco bloco) => bloco.idFuncionario == idFuncionario,
    );
    return itens.isEmpty ? null : itens.first;
  }

  AgendamentoFuncionarioOpcao? _funcionario(
    AgendamentoContextoModel contexto,
    int id,
  ) {
    final Iterable<AgendamentoFuncionarioOpcao> itens = contexto.funcionarios
        .where((AgendamentoFuncionarioOpcao item) => item.id == id);
    return itens.isEmpty ? null : itens.first;
  }

  AgendamentoServicoOpcao? _servico(AgendamentoContextoModel contexto, int id) {
    final Iterable<AgendamentoServicoOpcao> itens = contexto.servicos.where(
      (AgendamentoServicoOpcao item) => item.id == id,
    );
    return itens.isEmpty ? null : itens.first;
  }

  List<AgendamentoModel> _agendamentosDaOrdem(Map<String, dynamic> ordem) {
    final dynamic itens = ordem['agendamentos'];
    return (itens is List ? itens : const <dynamic>[])
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              AgendamentoModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  double? _valor(dynamic valor) {
    final double? numero = valor is num
        ? valor.toDouble()
        : double.tryParse('${valor ?? ''}');
    return numero != null && numero > 0 ? numero : null;
  }

  List<AgendamentoHorarioModel> _grade(dynamic horariosJson) {
    if (horariosJson is! List) {
      return const <AgendamentoHorarioModel>[];
    }

    return horariosJson
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              AgendamentoHorarioModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  bool _mesmaLista(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  String _dataIso(DateTime data) {
    final String dia = data.day.toString().padLeft(2, '0');
    final String mes = data.month.toString().padLeft(2, '0');
    return '${data.year}-$mes-$dia';
  }

  /// Resposta 409 da API ao marcar ou editar.
  static const String conflito = '409';

  /// Com 409 o horário foi ocupado por outra pessoa entre a consulta e a
  /// confirmação: avisa e recarrega os horários de todos os blocos, sem o
  /// horário escolhido, para o cliente escolher outro. Os serviços e
  /// profissionais escolhidos continuam.
  Future<void> _falhaAoSalvar(
    Emitter<AgendamentoState> emit,
    ErrorModel errorModel,
  ) async {
    if (errorModel.tipo != conflito) {
      _notifyErro(errorModel);
      return;
    }
    try {
      if (AppContext.navigatorKey.currentContext != null) {
        showSnackbarWarning(
          message:
              errorModel.mensagem ??
              'Esse horário acabou de ficar indisponível. Escolha outro horário para continuar',
        );
      }
    } catch (_) {}
    await Future.wait(
      state.blocos.map(
        (AgendamentoBloco bloco) =>
            _carregarHorarios(emit, bloco.idFuncionario),
      ),
    );
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
