import ActivityKit
import SwiftUI
import WidgetKit

/// Cores por estado (fundo escuro) e textos secundários.
private enum Razor {
  static let aguardando = Color(red: 0x60 / 255, green: 0xA5 / 255, blue: 0xFA / 255)
  static let confirmado = Color(red: 0x34 / 255, green: 0xD3 / 255, blue: 0x99 / 255)
  static let emAtendimento = Color(red: 0x10 / 255, green: 0xB9 / 255, blue: 0x81 / 255)
  static let finalizado = Color(red: 0xA7 / 255, green: 0x8B / 255, blue: 0xFA / 255)
  static let fundo = Color(red: 0x0B / 255, green: 0x0D / 255, blue: 0x12 / 255)
  static let textoSecundario = Color.white.opacity(0.6)
}

private typealias Estado = AgendamentoActivityAttributes.ContentState.Estado

private extension Estado {
  var cor: Color {
    switch self {
    case .aguardando: return Razor.aguardando
    case .confirmado: return Razor.confirmado
    case .emAtendimento: return Razor.emAtendimento
    case .finalizado: return Razor.finalizado
    }
  }

  var rotulo: String {
    switch self {
    case .aguardando: return "Aguardando"
    case .confirmado: return "Confirmado"
    case .emAtendimento: return "Em atendimento"
    case .finalizado: return "Finalizado"
    }
  }
}

/// O que a atividade mostra num instante. "Chegou a hora" vem do relógio do sistema: a atividade fica
/// obsoleta (`staleDate`) no início do horário e o iOS a desenha de novo, sem timer no app.
private struct Situacao {
  let context: ActivityViewContext<AgendamentoActivityAttributes>

  var estado: Estado { context.state.estado }
  var id: Int { context.attributes.idAgendamento }

  /// Aguardando e o horário já começou: troca a contagem pelo botão do QR Code.
  var horaDoQr: Bool {
    estado == .aguardando && (context.isStale || Date() >= context.state.dataInicio)
  }

  var contagem: ClosedRange<Date> {
    let inicio = context.state.dataInicio
    return min(Date(), inicio)...inicio
  }

  /// Cronômetro crescente desde o início do atendimento (ou do horário, se o servidor não mandou).
  var desdeInicio: ClosedRange<Date> {
    let comeco = context.state.dataInicioAtendimento ?? context.state.dataInicio
    return comeco...Date.distantFuture
  }

  var horario: String {
    let formato = DateFormatter()
    formato.locale = Locale(identifier: "pt_BR")
    formato.dateFormat = "HH:mm"
    return formato.string(from: context.state.dataInicio)
  }

  var linkAgendamento: URL { URL(string: "razor://agendamento/\(id)")! }
  var linkQr: URL { URL(string: "razor://agendamento/\(id)/qrcode")! }
  var linkAvaliar: URL { URL(string: "razor://agendamento/\(id)/avaliar")! }
}

struct AgendamentoLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AgendamentoActivityAttributes.self) { context in
      TelaDeBloqueio(s: Situacao(context: context))
        .activityBackgroundTint(Razor.fundo)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(Situacao(context: context).linkAgendamento)
    } dynamicIsland: { context in
      let s = Situacao(context: context)
      return DynamicIsland {
        // Os lados da câmera são estreitos: o que não couber desce para baixo dela (belowIfTooWide) em vez
        // de ser cortado.
        DynamicIslandExpandedRegion(.leading) {
          Identificacao(s: s, tamanhoFoto: 44)
            .padding(.leading, 4)
            .dynamicIsland(verticalPlacement: .belowIfTooWide)
        }
        DynamicIslandExpandedRegion(.trailing) {
          ItemDoEstado(s: s)
            .padding(.trailing, 4)
            .dynamicIsland(verticalPlacement: .belowIfTooWide)
        }
      } compactLeading: {
        Avatar(attributes: context.attributes, cor: s.estado.cor, tamanho: 20, borda: 1.5)
          .frame(width: 20)
      } compactTrailing: {
        IndicadorCompacto(s: s)
          .frame(width: 42)
      } minimal: {
        Avatar(attributes: context.attributes, cor: s.estado.cor, tamanho: 20, borda: 1.5)
      }
      .widgetURL(s.linkAgendamento)
      .keylineTint(s.estado.cor)
    }
  }
}

// MARK: - Partes

/// Foto, serviço, barbearia e o chip do estado: a parte fixa, à esquerda.
private struct Identificacao: View {
  let s: Situacao
  let tamanhoFoto: CGFloat

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      Avatar(attributes: s.context.attributes, cor: s.estado.cor, tamanho: tamanhoFoto, borda: 2)
      VStack(alignment: .leading, spacing: 3) {
        Text(s.context.attributes.servico)
          .font(.headline)
          .foregroundStyle(.white)
          .lineLimit(1)
        if !s.context.attributes.barbearia.isEmpty {
          Text(s.context.attributes.barbearia)
            .font(.caption)
            .foregroundStyle(Razor.textoSecundario)
            .lineLimit(1)
        }
        ChipEstado(estado: s.estado)
          .padding(.top, 1)
      }
    }
  }
}

private struct ChipEstado: View {
  let estado: Estado

  var body: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(estado.cor)
        .frame(width: 6, height: 6)
      Text(estado.rotulo)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(estado.cor)
        .lineLimit(1)
    }
    .padding(.horizontal, 7)
    .padding(.vertical, 3)
    .background(estado.cor.opacity(0.16), in: Capsule())
  }
}

/// O único item que muda à direita: contagem, horário, cronômetro ou um botão.
private struct ItemDoEstado: View {
  let s: Situacao

  var body: some View {
    switch s.estado {
    case .aguardando:
      if s.horaDoQr {
        Botao(destino: s.linkQr, icone: "qrcode", titulo: "QR Code", subtitulo: "Confirmar chegada",
              cor: Razor.aguardando)
      } else {
        Valor(rotulo: "Começa em", cor: Razor.aguardando) {
          Text(timerInterval: s.contagem, countsDown: true)
        }
      }
    case .confirmado:
      Valor(rotulo: "Horário agendado", cor: Razor.confirmado) {
        Text(s.horario)
      }
    case .emAtendimento:
      Valor(rotulo: "Em atendimento há", cor: Razor.emAtendimento) {
        Text(timerInterval: s.desdeInicio, countsDown: false)
      }
    case .finalizado:
      Botao(destino: s.linkAvaliar, icone: "star.fill", titulo: "Avaliar", subtitulo: "atendimento",
            cor: Razor.finalizado)
    }
  }
}

private struct Valor<Conteudo: View>: View {
  let rotulo: String
  let cor: Color
  @ViewBuilder let conteudo: () -> Conteudo

  var body: some View {
    VStack(alignment: .trailing, spacing: 1) {
      Text(rotulo)
        .font(.caption2.weight(.medium))
        .foregroundStyle(Razor.textoSecundario)
        .lineLimit(1)
      // O cronômetro reserva espaço para "0:00:00": largura fixa para não cortar nem empurrar o resto.
      conteudo()
        .font(.system(size: 26, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(cor)
        .multilineTextAlignment(.trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(width: 96, alignment: .trailing)
    }
  }
}

/// Botão com link (funciona na ilha expandida e na tela bloqueada, mesmo com o app fechado).
private struct Botao: View {
  let destino: URL
  let icone: String
  let titulo: String
  let subtitulo: String
  let cor: Color

  var body: some View {
    Link(destination: destino) {
      HStack(spacing: 6) {
        Image(systemName: icone)
          .font(.system(size: 15, weight: .semibold))
        VStack(alignment: .leading, spacing: 0) {
          Text(titulo)
            .font(.caption.weight(.bold))
          Text(subtitulo)
            .font(.caption2)
            .opacity(0.85)
        }
        .lineLimit(1)
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(cor.opacity(0.9), in: Capsule())
    }
  }
}

/// Ilha fechada, à direita da câmera (42 pt).
private struct IndicadorCompacto: View {
  let s: Situacao

  var body: some View {
    switch s.estado {
    case .aguardando:
      if s.horaDoQr {
        Image(systemName: "qrcode")
          .foregroundStyle(Razor.aguardando)
      } else {
        Text(timerInterval: s.contagem, countsDown: true)
          .monospacedDigit()
          .font(.caption2.weight(.semibold))
          .foregroundStyle(Razor.aguardando)
          .multilineTextAlignment(.trailing)
          .minimumScaleFactor(0.7)
      }
    case .confirmado:
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(Razor.confirmado)
    case .emAtendimento:
      Text(timerInterval: s.desdeInicio, countsDown: false)
        .monospacedDigit()
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Razor.emAtendimento)
        .multilineTextAlignment(.trailing)
        .minimumScaleFactor(0.7)
    case .finalizado:
      Image(systemName: "checkmark.seal.fill")
        .foregroundStyle(Razor.finalizado)
    }
  }
}

/// Foto real do profissional (guardada pelo app no App Group) ou as iniciais dele num círculo discreto.
private struct Avatar: View {
  let attributes: AgendamentoActivityAttributes
  let cor: Color
  let tamanho: CGFloat
  let borda: CGFloat

  private var foto: UIImage? {
    guard let url = attributes.fotoProfissional, let arquivo = FotoProfissional.arquivo(url) else {
      return nil
    }
    return UIImage(contentsOfFile: arquivo.path)
  }

  private var iniciais: String {
    let partes = (attributes.profissional ?? "").split(separator: " ").filter { !$0.isEmpty }
    let letras = [partes.first, partes.count > 1 ? partes.last : nil].compactMap { $0?.first }
    return String(letras).uppercased()
  }

  var body: some View {
    Group {
      if let foto {
        Image(uiImage: foto)
          .resizable()
          .scaledToFill()
      } else {
        ZStack {
          LinearGradient(
            colors: [Color(white: 0.24), Color(white: 0.14)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          if iniciais.isEmpty {
            Image(systemName: "person.fill")
              .font(.system(size: tamanho * 0.45))
              .foregroundStyle(Color.white.opacity(0.7))
          } else {
            Text(iniciais)
              .font(.system(size: tamanho * 0.38, weight: .semibold, design: .rounded))
              .foregroundStyle(Color.white.opacity(0.85))
          }
        }
      }
    }
    .frame(width: tamanho, height: tamanho)
    .clipShape(Circle())
    .overlay(Circle().strokeBorder(cor, lineWidth: borda))
  }
}

/// Tela bloqueada (e aparelhos sem Dynamic Island): mesma informação, numa linha só.
private struct TelaDeBloqueio: View {
  let s: Situacao

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Identificacao(s: s, tamanhoFoto: 50)
      Spacer(minLength: 8)
      ItemDoEstado(s: s)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }
}
