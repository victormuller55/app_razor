import ActivityKit
import Flutter
import Foundation

/// Liga o Dart ao ActivityKit: mostra o lembrete do agendamento na Dynamic
/// Island e encerra os que não valem mais (cancelado, já terminou).
///
/// Canal `razor/lembrete_agendamento`, método `sincronizar` com
/// `{ "agendamento": {...} | null }`. Só há um lembrete por vez.
final class LembreteAgendamentoPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "razor/lembrete_agendamento",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(LembreteAgendamentoPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "sincronizar" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard #available(iOS 16.2, *) else {
      result(false)
      return
    }

    let argumentos = call.arguments as? [String: Any]
    let agendamento = argumentos?["agendamento"] as? [String: Any]

    Task {
      let mostrando = await Self.sincronizar(agendamento)
      // O Flutter espera a resposta na thread principal.
      await MainActor.run { result(mostrando) }
    }
  }

  @available(iOS 16.2, *)
  private static func sincronizar(_ dados: [String: Any]?) async -> Bool {
    let atuais = Activity<AgendamentoActivityAttributes>.activities
    let desejado = dados.flatMap(Lembrete.init)

    // Encerra o que não é o lembrete desejado.
    for atividade in atuais where atividade.attributes.idAgendamento != desejado?.id {
      await atividade.end(nil, dismissalPolicy: .immediate)
    }

    guard let lembrete = desejado else {
      return false
    }

    let estado = AgendamentoActivityAttributes.ContentState(
      inicio: lembrete.inicio,
      fim: lembrete.fim
    )
    // Depois do início o cronômetro troca para "É agora".
    let conteudo = ActivityContent(state: estado, staleDate: lembrete.inicio)

    if let existente = atuais.first(where: { $0.attributes.idAgendamento == lembrete.id }) {
      await existente.update(conteudo)
      return true
    }

    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      return false
    }

    do {
      _ = try Activity.request(
        attributes: AgendamentoActivityAttributes(
          idAgendamento: lembrete.id,
          servico: lembrete.servico,
          barbearia: lembrete.barbearia,
          profissional: lembrete.profissional
        ),
        content: conteudo,
        pushType: nil
      )
      return true
    } catch {
      return false
    }
  }
}

/// Dados que o Dart manda. Datas em milissegundos desde 1970.
private struct Lembrete {
  let id: Int
  let servico: String
  let barbearia: String
  let profissional: String?
  let inicio: Date
  let fim: Date

  init?(_ dados: [String: Any]) {
    guard
      let id = (dados["id"] as? NSNumber)?.intValue,
      let inicio = (dados["inicio"] as? NSNumber)?.doubleValue,
      let fim = (dados["fim"] as? NSNumber)?.doubleValue
    else {
      return nil
    }

    self.id = id
    servico = dados["servico"] as? String ?? "Seu serviço"
    barbearia = dados["barbearia"] as? String ?? ""
    profissional = dados["profissional"] as? String
    self.inicio = Date(timeIntervalSince1970: inicio / 1000)
    self.fim = Date(timeIntervalSince1970: fim / 1000)
  }
}
