/// Regras de cancelamento, atraso e reembolso que a API aplica.
class PoliticaAgendamentoModel {
  const PoliticaAgendamentoModel({
    this.prazoCancelamentoMinutos = 60,
    this.toleranciaAtrasoMinutos = 15,
    this.multaAutomatica = false,
    this.regras = const <String>[],
  });

  factory PoliticaAgendamentoModel.fromJson(Map<String, dynamic> json) {
    final dynamic regras = json['regras'];
    return PoliticaAgendamentoModel(
      prazoCancelamentoMinutos: _minutos(
        json['prazo_cancelamento_minutos'],
        60,
      ),
      toleranciaAtrasoMinutos: _minutos(json['tolerancia_atraso_minutos'], 15),
      multaAutomatica: json['multa_automatica'] == true,
      regras: regras is List
          ? regras
                .whereType<String>()
                .where((String r) => r.trim().isNotEmpty)
                .toList()
          : const <String>[],
    );
  }

  /// Valores padrão, usados enquanto a API não responde.
  static const PoliticaAgendamentoModel padrao = PoliticaAgendamentoModel();

  final int prazoCancelamentoMinutos;
  final int toleranciaAtrasoMinutos;
  final bool multaAutomatica;
  final List<String> regras;

  String get prazoLabel => duracaoLabel(prazoCancelamentoMinutos);

  String get toleranciaLabel => duracaoLabel(toleranciaAtrasoMinutos);

  /// Regras da API; sem elas, o resumo com os valores conhecidos.
  List<String> get regrasParaExibir {
    if (regras.isNotEmpty) {
      return regras;
    }

    return <String>[
      'Cancele pelo app até $prazoLabel antes do horário para liberar a agenda da barbearia.',
      'Depois desse prazo você ainda pode cancelar: o pedido fica registrado como cancelamento fora do prazo, sem multa.',
      'Tolerância de atraso: $toleranciaLabel. Sem chegada confirmada até lá, o horário é liberado e registrado como não comparecimento, sem multa.',
      'Se você pagou pelo app e cancelar, o valor pago é devolvido pelo Mercado Pago.',
      'Essas regras não afastam os direitos garantidos pelo Código de Defesa do Consumidor.',
    ];
  }

  /// O prazo já passou: cancelar ainda é possível, mas fica registrado como fora do prazo.
  /// Exatamente no limite ainda está no prazo, como na API.
  bool foraDoPrazo(DateTime? inicio, DateTime agora) {
    if (inicio == null) {
      return false;
    }

    return agora.isAfter(
      inicio.subtract(Duration(minutes: prazoCancelamentoMinutos)),
    );
  }

  static String duracaoLabel(int minutos) {
    if (minutos % 60 == 0) {
      final int horas = minutos ~/ 60;
      return horas == 1 ? '1 hora' : '$horas horas';
    }

    return '$minutos minutos';
  }

  static int _minutos(dynamic valor, int padrao) {
    if (valor is num && valor > 0) {
      return valor.toInt();
    }

    return padrao;
  }
}
