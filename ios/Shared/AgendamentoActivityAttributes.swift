import ActivityKit
import Foundation

/// Lembrete do agendamento na Dynamic Island e na tela de bloqueio.
/// Este arquivo entra no app (Runner) e na extensão (RazorLiveActivity):
/// os dois lados precisam do mesmo tipo para a atividade aparecer.
@available(iOS 16.1, *)
struct AgendamentoActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// Início e fim do serviço. O cronômetro conta até o início.
    var inicio: Date
    var fim: Date
  }

  var idAgendamento: Int
  var servico: String
  var barbearia: String
  var profissional: String?
}
