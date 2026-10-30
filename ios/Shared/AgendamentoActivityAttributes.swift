import ActivityKit
import Foundation

/// Lembrete do agendamento na Dynamic Island e na tela bloqueada. Compartilhado entre o app e a extensão.
///
/// O mesmo JSON chega por push (ActivityKit pelo FCM): os nomes dos campos e os valores de `Estado` são o
/// contrato com a API (`AtividadeAoVivoService`). Datas vão como segundos desde 1970 (Double), não como `Date`,
/// porque o `Codable` padrão de `Date` usa outra referência (2001) e o servidor não precisa saber disso.
@available(iOS 16.1, *)
struct AgendamentoActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    enum Estado: String, Codable, Hashable {
      /// Agendado, chegada ainda não confirmada pelo QR Code.
      case aguardando
      /// QR Code lido pela barbearia.
      case confirmado
      /// Barbeiro iniciou o atendimento.
      case emAtendimento
      /// Atendimento concluído: convida para avaliar.
      case finalizado
    }

    var estado: Estado
    var inicio: Double
    var fim: Double
    /// Quando o barbeiro iniciou (só em atendimento).
    var inicioAtendimento: Double?

    var dataInicio: Date { Date(timeIntervalSince1970: inicio) }
    var dataFim: Date { Date(timeIntervalSince1970: fim) }
    var dataInicioAtendimento: Date? { inicioAtendimento.map(Date.init(timeIntervalSince1970:)) }
  }

  var idAgendamento: Int
  var servico: String
  var barbearia: String
  var profissional: String?
  /// URL da foto do profissional. A extensão não baixa nada: o app guarda a foto no App Group
  /// (`FotoProfissional`) e a extensão só lê o arquivo; sem ele, mostra as iniciais.
  var fotoProfissional: String?
  /// Chave assinada pela API que autoriza ligar o token desta atividade ao agendamento, sem o login.
  var chave: String?
}

/// Fotos dos profissionais no contêiner do App Group, lidas pela extensão.
enum FotoProfissional {
  static let grupo = "group.com.net.convertix.scissor"

  /// Arquivo da foto de uma URL (nome estável, sem caracteres de URL).
  static func arquivo(_ url: String) -> URL? {
    guard
      let pasta = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: grupo)?
        .appendingPathComponent("fotos", isDirectory: true)
    else {
      return nil
    }
    var hash: UInt64 = 5381
    for byte in url.utf8 {
      hash = (hash &* 33) &+ UInt64(byte)
    }
    return pasta.appendingPathComponent("\(String(hash, radix: 16)).jpg")
  }
}
