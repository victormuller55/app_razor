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
      Linha(s: Situacao(context: context), tamanhoFoto: 60)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(Razor.fundo)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(Situacao(context: context).linkAgendamento)
    } dynamicIsland: { context in
      let s = Situacao(context: context)
      return DynamicIsland {
        // Uma linha só, abaixo da câmera e com a largura toda: separar em leading/trailing dividia a largura
        // ao meio (cortando o serviço) e cada lado descia ou não conforme coubesse, desalinhando a altura.
        DynamicIslandExpandedRegion(.bottom) {
          Linha(s: s, tamanhoFoto: 66)
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
        }
      } compactLeading: {
        // Sem largura fixa: a ilha fechada ocupa só o tamanho dos itens.
        Avatar(attributes: context.attributes, cor: s.estado.cor, tamanho: 20, borda: 1.5)
      } compactTrailing: {
        IndicadorCompacto(s: s)
      } minimal: {
        Avatar(attributes: context.attributes, cor: s.estado.cor, tamanho: 20, borda: 1.5)
      }
      .widgetURL(s.linkAgendamento)
      .keylineTint(s.estado.cor)
    }
  }
}

// MARK: - Partes

/// Foto, serviço e o chip do estado: a parte fixa, à esquerda.
private struct Identificacao: View {
  let s: Situacao
  let tamanhoFoto: CGFloat

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Avatar(attributes: s.context.attributes, cor: s.estado.cor, tamanho: tamanhoFoto, borda: 2.5)
      VStack(alignment: .leading, spacing: 6) {
        VStack(alignment: .leading, spacing: 1) {
          Text(s.context.attributes.servico)
            .font(.headline)
            .foregroundStyle(.white)
            .lineLimit(1)
          if let profissional = s.context.attributes.profissional, !profissional.isEmpty {
            Text("com \(profissional)")
              .font(.caption)
              .foregroundStyle(Razor.textoSecundario)
              .lineLimit(1)
          }
        }
        ChipEstado(estado: s.estado)
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
    .fixedSize()
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

/// Ilha fechada, à direita da câmera: só o tamanho do conteúdo, para a ilha não crescer à toa.
private struct IndicadorCompacto: View {
  let s: Situacao

  var body: some View {
    switch s.estado {
    case .aguardando:
      if s.horaDoQr {
        Image(systemName: "qrcode")
          .foregroundStyle(Razor.aguardando)
      } else {
        Relogio(intervalo: s.contagem, regressivo: true, cor: Razor.aguardando)
      }
    case .confirmado:
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(Razor.confirmado)
    case .emAtendimento:
      Relogio(intervalo: s.desdeInicio, regressivo: false, cor: Razor.emAtendimento)
    case .finalizado:
      Image(systemName: "checkmark.seal.fill")
        .foregroundStyle(Razor.finalizado)
    }
  }
}

/// Contagem ou cronômetro da ilha fechada. O `Text(timerInterval:)` ocupa toda a largura que receber, então
/// a largura é a de "00:00" (o que passar de 1 hora encolhe a fonte).
private struct Relogio: View {
  let intervalo: ClosedRange<Date>
  let regressivo: Bool
  let cor: Color

  var body: some View {
    Text(timerInterval: intervalo, countsDown: regressivo)
      .monospacedDigit()
      .font(.caption2.weight(.semibold))
      .foregroundStyle(cor)
      .multilineTextAlignment(.trailing)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .frame(width: 30)
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

/// Ilha expandida e tela bloqueada: identificação à esquerda e o item do estado à direita, centralizados na
/// altura. Quem encolhe é o nome do serviço, nunca o item da direita.
private struct Linha: View {
  let s: Situacao
  let tamanhoFoto: CGFloat

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Identificacao(s: s, tamanhoFoto: tamanhoFoto)
      Spacer(minLength: 8)
      ItemDoEstado(s: s)
        .layoutPriority(1)
    }
  }
}
