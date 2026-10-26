import ActivityKit
import SwiftUI
import WidgetKit

/// Cores do Razor. Na ilha o fundo é preto, então o azul da marca vira um
/// tom claro para ter contraste.
private enum Razor {
  static let marca = Color(red: 0x1C / 255, green: 0x3A / 255, blue: 0x5A / 255)
  static let marcaEscura = Color(red: 0x10 / 255, green: 0x24 / 255, blue: 0x3A / 255)
  static let destaque = Color(red: 0x9C / 255, green: 0xC4 / 255, blue: 0xF0 / 255)
  static let textoSecundario = Color.white.opacity(0.65)
}

private extension AgendamentoActivityAttributes.ContentState {
  /// A barra enche ao longo da última hora antes do serviço.
  var janela: ClosedRange<Date> {
    let comeco = inicio.addingTimeInterval(-60 * 60)
    return min(comeco, inicio)...inicio
  }

  /// Faixa do cronômetro: de agora até o início, sem inverter quando já passou.
  var contagem: ClosedRange<Date> {
    min(Date(), inicio)...inicio
  }

  var horario: String {
    let formato = DateFormatter()
    formato.locale = Locale(identifier: "pt_BR")
    formato.dateFormat = "HH:mm"
    return "\(formato.string(from: inicio)) – \(formato.string(from: fim))"
  }
}

struct AgendamentoLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AgendamentoActivityAttributes.self) { context in
      TelaDeBloqueio(context: context)
        .activityBackgroundTint(Razor.marcaEscura)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          IconeTesoura(tamanho: 44)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            Text(context.isStale ? "Agora" : "Faltam")
              .font(.caption2.weight(.medium))
              .foregroundStyle(Razor.textoSecundario)
            Cronometro(estado: context.state, encerrado: context.isStale)
              .font(.system(size: 26, weight: .semibold, design: .rounded))
              .foregroundStyle(Razor.destaque)
          }
          .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.servico)
              .font(.headline)
              .foregroundStyle(.white)
              .lineLimit(1)
            Text(context.attributes.barbearia)
              .font(.caption)
              .foregroundStyle(Razor.textoSecundario)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 8) {
            BarraProgresso(estado: context.state)
            HStack {
              Label(context.state.horario, systemImage: "clock")
              Spacer()
              if let profissional = context.attributes.profissional {
                Label(profissional, systemImage: "person.fill")
                  .lineLimit(1)
              }
            }
            .font(.caption)
            .foregroundStyle(Razor.textoSecundario)
          }
          .padding(.horizontal, 4)
          .padding(.top, 4)
        }
      } compactLeading: {
        Image(systemName: "scissors")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(Razor.destaque)
      } compactTrailing: {
        Cronometro(estado: context.state, encerrado: context.isStale)
          .font(.system(size: 14, weight: .semibold, design: .rounded))
          .foregroundStyle(Razor.destaque)
          .frame(maxWidth: 56)
      } minimal: {
        Image(systemName: "scissors")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(Razor.destaque)
      }
      .keylineTint(Razor.destaque)
    }
  }
}

/// Contagem regressiva até o início. O sistema atualiza sozinho, sem o app.
private struct Cronometro: View {
  let estado: AgendamentoActivityAttributes.ContentState
  let encerrado: Bool

  var body: some View {
    if encerrado || estado.inicio <= Date() {
      Text("É agora")
    } else {
      Text(timerInterval: estado.contagem, countsDown: true)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
  }
}

private struct BarraProgresso: View {
  let estado: AgendamentoActivityAttributes.ContentState

  var body: some View {
    ProgressView(timerInterval: estado.janela, countsDown: false) {
      EmptyView()
    } currentValueLabel: {
      EmptyView()
    }
    .progressViewStyle(.linear)
    .tint(Razor.destaque)
  }
}

private struct IconeTesoura: View {
  let tamanho: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .fill(
          LinearGradient(
            colors: [Razor.marca, Razor.destaque.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      Image(systemName: "scissors")
        .font(.system(size: tamanho * 0.42, weight: .bold))
        .foregroundStyle(.white)
    }
    .frame(width: tamanho, height: tamanho)
  }
}

private struct TelaDeBloqueio: View {
  let context: ActivityViewContext<AgendamentoActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 12) {
        IconeTesoura(tamanho: 46)
        VStack(alignment: .leading, spacing: 2) {
          Text(context.isStale ? "Seu horário começou" : "Seu horário está chegando")
            .font(.caption.weight(.medium))
            .foregroundStyle(Razor.textoSecundario)
          Text(context.attributes.servico)
            .font(.headline)
            .foregroundStyle(.white)
            .lineLimit(1)
          Text(context.attributes.barbearia)
            .font(.caption)
            .foregroundStyle(Razor.textoSecundario)
            .lineLimit(1)
        }
        Spacer(minLength: 8)
        Cronometro(estado: context.state, encerrado: context.isStale)
          .font(.system(size: 30, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .frame(maxWidth: 110, alignment: .trailing)
      }

      BarraProgresso(estado: context.state)

      HStack {
        Label(context.state.horario, systemImage: "clock")
        Spacer()
        if let profissional = context.attributes.profissional {
          Label(profissional, systemImage: "person.fill")
            .lineLimit(1)
        }
      }
      .font(.caption)
      .foregroundStyle(Razor.textoSecundario)
    }
    .padding(16)
  }
}
