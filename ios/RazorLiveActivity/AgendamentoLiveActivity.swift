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
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        // Os lados da câmera são estreitos: o que não couber desce para
        // baixo dela (belowIfTooWide) em vez de ser cortado.
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 10) {
            IconeTesoura(tamanho: 40)
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
          }
          .padding(.leading, 4)
          .dynamicIsland(verticalPlacement: .belowIfTooWide)
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 0) {
            Text(context.isStale ? "Começou:" : "Começa em:")
              .font(.caption2.weight(.medium))
              .foregroundStyle(Razor.textoSecundario)
            // O cronômetro reserva espaço para "0:00:00": largura fixa
            // para não cortar nem empurrar o resto.
            Cronometro(estado: context.state, encerrado: context.isStale)
              .font(.system(size: 24, weight: .semibold, design: .rounded))
              .foregroundStyle(Razor.destaque)
              .lineLimit(1)
              .frame(width: 92, alignment: .trailing)
          }
          .padding(.trailing, 4)
          .dynamicIsland(verticalPlacement: .belowIfTooWide)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 8) {
            BarraProgresso(estado: context.state)
            HStack {
              Label {
                Text(context.state.horario)
              } icon: {
                Image(systemName: "clock").foregroundStyle(Razor.destaque)
              }
              Spacer()
              if let profissional = context.attributes.profissional {
                Label {
                  Text(profissional).lineLimit(1)
                } icon: {
                  Image(systemName: "person.fill").foregroundStyle(Razor.destaque)
                }
              }
            }
            .font(.caption)
            .foregroundStyle(Razor.textoSecundario)
          }
          .padding(.horizontal, 4)
          .padding(.top, 6)
        }
      } compactLeading: {
        // Larguras fixas e justas: sem elas o cronômetro reserva espaço para
        // "0:00:00" e a ilha fechada fica bem mais larga que o necessário.
        Image(systemName: "scissors")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(Razor.destaque)
          .frame(width: 20)
      } compactTrailing: {
        Group {
          if context.isStale || context.state.inicio <= Date() {
            Text("Agora")
          } else {
            Text(timerInterval: context.state.contagem, countsDown: true)
              .monospacedDigit()
              .multilineTextAlignment(.trailing)
          }
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(Razor.destaque)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(width: 42, alignment: .trailing)
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
        VStack(alignment: .trailing, spacing: 0) {
          Text(context.isStale ? "Começou:" : "Começa em:")
            .font(.caption.weight(.medium))
            .foregroundStyle(Razor.textoSecundario)
          Cronometro(estado: context.state, encerrado: context.isStale)
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundStyle(Razor.destaque)
        }
        .frame(maxWidth: 120, alignment: .trailing)
      }

      BarraProgresso(estado: context.state)

      HStack {
        Label {
          Text(context.state.horario)
        } icon: {
          Image(systemName: "clock").foregroundStyle(Razor.destaque)
        }
        Spacer()
        if let profissional = context.attributes.profissional {
          Label {
            Text(profissional).lineLimit(1)
          } icon: {
            Image(systemName: "person.fill").foregroundStyle(Razor.destaque)
          }
        }
      }
      .font(.caption)
      .foregroundStyle(Razor.textoSecundario)
    }
    .padding(16)
  }
}
