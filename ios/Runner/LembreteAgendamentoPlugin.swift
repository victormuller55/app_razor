import ActivityKit
import Flutter
import Foundation
import UIKit

/// Liga o Dart ao ActivityKit: mostra o agendamento na Dynamic Island e na tela bloqueada, encerra o que não
/// vale mais e repassa os links tocados na atividade (`razor://agendamento/{id}/...`).
///
/// Canal `razor/lembrete_agendamento`:
/// - `configurar` `{ "api": url }`: endereço da API, guardado para enviar tokens com o app fechado;
/// - `sincronizar` `{ "agendamento": {...} | null }`: só há uma atividade por vez;
/// - `tokenInicio`: token de push-to-start (iOS 17.2+) para o servidor iniciar a atividade, ou null;
/// - `linkPendente`: link que abriu o app fechado, entregue uma vez;
/// - do iOS para o Dart, `abrirLink` `{ "url": ... }` com o app aberto.
final class LembreteAgendamentoPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "razor/lembrete_agendamento",
      binaryMessenger: registrar.messenger()
    )
    let plugin = LembreteAgendamentoPlugin()
    registrar.addMethodCallDelegate(plugin, channel: channel)
    // Links `razor://` tocados na atividade chegam pelos eventos da cena (o app usa UIScene).
    registrar.addSceneDelegate(plugin)
    LinksAtividade.shared.aoReceber = { url in
      channel.invokeMethod("abrirLink", arguments: ["url": url.absoluteString])
    }
  }

  /// App aberto por um link estando fechado.
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    if let url = connectionOptions?.urlContexts.first?.url {
      LinksAtividade.shared.receber(url)
    }
    // Não consome a conexão: os outros plugins seguem recebendo.
    return false
  }

  /// Link tocado com o app em segundo plano.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    let links = URLContexts.map(\.url).filter { $0.scheme == "razor" }
    links.forEach(LinksAtividade.shared.receber)
    return !links.isEmpty
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let argumentos = call.arguments as? [String: Any]

    switch call.method {
    case "configurar":
      TokensAtividade.api = argumentos?["api"] as? String
      result(nil)
    case "linkPendente":
      result(LinksAtividade.shared.retirarPendente()?.absoluteString)
    case "tokenInicio":
      guard #available(iOS 17.2, *) else {
        result(nil)
        return
      }
      Task {
        let token = await TokensAtividade.shared.tokenInicio()
        await MainActor.run { result(token) }
      }
    case "sincronizar":
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      let agendamento = argumentos?["agendamento"] as? [String: Any]
      Task {
        let mostrando = await Self.sincronizar(agendamento)
        // O Flutter espera a resposta na thread principal.
        await MainActor.run { result(mostrando) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Ajusta a atividade ao agendamento escolhido pelo Dart. A que já existe é atualizada (nunca recriada);
  /// as de outros agendamentos são encerradas.
  @available(iOS 16.2, *)
  private static func sincronizar(_ dados: [String: Any]?) async -> Bool {
    let atuais = Activity<AgendamentoActivityAttributes>.activities
    let desejado = dados.flatMap(Lembrete.init)

    for atividade in atuais where atividade.attributes.idAgendamento != desejado?.atributos.idAgendamento {
      await atividade.end(nil, dismissalPolicy: .immediate)
    }

    guard let lembrete = desejado else {
      return false
    }

    if let url = lembrete.atributos.fotoProfissional {
      await TokensAtividade.baixarFoto(url)
    }

    // Aguardando: obsoleta no início do horário, quando a contagem vira o botão do QR Code.
    let conteudo = ActivityContent(
      state: lembrete.estado,
      staleDate: lembrete.estado.estado == .aguardando ? lembrete.estado.dataInicio : nil
    )

    if let existente = atuais.first(where: { $0.attributes.idAgendamento == lembrete.atributos.idAgendamento }) {
      if existente.content.state != lembrete.estado {
        await existente.update(conteudo)
      }
      return true
    }

    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      return false
    }

    do {
      // Com a chave, o token de atualização vai para a API e o servidor segue mudando o estado com o app fechado.
      _ = try Activity.request(
        attributes: lembrete.atributos,
        content: conteudo,
        pushType: lembrete.atributos.chave == nil ? nil : .token
      )
      return true
    } catch {
      return false
    }
  }
}

/// Dados que o Dart manda. Datas em milissegundos desde 1970.
@available(iOS 16.2, *)
private struct Lembrete {
  let atributos: AgendamentoActivityAttributes
  let estado: AgendamentoActivityAttributes.ContentState

  init?(_ dados: [String: Any]) {
    guard
      let id = (dados["id"] as? NSNumber)?.intValue,
      let inicio = (dados["inicio"] as? NSNumber)?.doubleValue,
      let fim = (dados["fim"] as? NSNumber)?.doubleValue,
      let estado = AgendamentoActivityAttributes.ContentState.Estado(rawValue: dados["estado"] as? String ?? "")
    else {
      return nil
    }

    atributos = AgendamentoActivityAttributes(
      idAgendamento: id,
      servico: dados["servico"] as? String ?? "Seu serviço",
      barbearia: dados["barbearia"] as? String ?? "",
      profissional: dados["profissional"] as? String,
      fotoProfissional: dados["foto"] as? String,
      chave: dados["chave"] as? String
    )
    self.estado = AgendamentoActivityAttributes.ContentState(
      estado: estado,
      inicio: inicio / 1000,
      fim: fim / 1000,
      inicioAtendimento: (dados["inicio_atendimento"] as? NSNumber).map { $0.doubleValue / 1000 }
    )
  }
}

/// Links tocados na atividade. Com o app fechado, o link fica guardado até o Dart pedir.
final class LinksAtividade {
  static let shared = LinksAtividade()

  var aoReceber: ((URL) -> Void)?
  private var pendente: URL?

  func receber(_ url: URL) {
    guard url.scheme == "razor" else {
      return
    }
    pendente = url
    aoReceber?(url)
  }

  func retirarPendente() -> URL? {
    defer { pendente = nil }
    return pendente
  }
}

/// Tokens de push das atividades, sem depender do Flutter: começa no lançamento do app (inclusive quando o
/// iOS acorda o app em segundo plano depois de o servidor iniciar uma atividade por push).
///
/// O token de atualização de cada atividade vai para `PUT /api/v1/atividades-ao-vivo` com a chave assinada
/// pela API que veio nos atributos; não usa o login do usuário. O token nunca vai para o log.
final class TokensAtividade {
  static let shared = TokensAtividade()

  private static let chaveApi = "razor.atividade.api"
  private var observando = false
  private var tokenDeInicio: String?

  static var api: String? {
    get { UserDefaults.standard.string(forKey: chaveApi) }
    set { UserDefaults.standard.set(newValue, forKey: chaveApi) }
  }

  func iniciar() {
    guard #available(iOS 16.2, *), !observando else {
      return
    }
    observando = true

    Task {
      // As que já existem (o app foi fechado e aberto de novo) e as que surgirem, inclusive por push.
      for atividade in Activity<AgendamentoActivityAttributes>.activities {
        observar(atividade)
      }
      for await atividade in Activity<AgendamentoActivityAttributes>.activityUpdates {
        observar(atividade)
      }
    }

    if #available(iOS 17.2, *) {
      Task {
        for await dados in Activity<AgendamentoActivityAttributes>.pushToStartTokenUpdates {
          tokenDeInicio = Self.hex(dados)
        }
      }
    }
  }

  @available(iOS 17.2, *)
  func tokenInicio() async -> String? {
    // O primeiro token chega logo depois de começar a observar; espera um pouco antes de desistir.
    for _ in 0..<20 where tokenDeInicio == nil {
      try? await Task.sleep(nanoseconds: 150_000_000)
    }
    return tokenDeInicio
  }

  @available(iOS 16.2, *)
  private func observar(_ atividade: Activity<AgendamentoActivityAttributes>) {
    Task {
      if let url = atividade.attributes.fotoProfissional, await Self.baixarFoto(url) {
        // Desenha de novo para trocar as iniciais pela foto.
        await atividade.update(atividade.content)
      }
    }
    Task {
      for await dados in atividade.pushTokenUpdates {
        await enviar(token: Self.hex(dados), de: atividade.attributes)
      }
    }
  }

  @available(iOS 16.2, *)
  private func enviar(token: String, de atributos: AgendamentoActivityAttributes) async {
    guard
      let chave = atributos.chave,
      let base = Self.api,
      let url = URL(string: base + "/api/v1/atividades-ao-vivo")
    else {
      return
    }

    var requisicao = URLRequest(url: url, timeoutInterval: 20)
    requisicao.httpMethod = "PUT"
    requisicao.setValue("application/json", forHTTPHeaderField: "Content-Type")
    requisicao.httpBody = try? JSONSerialization.data(withJSONObject: [
      "id_agendamento": atributos.idAgendamento,
      "chave": chave,
      "token": token,
    ])

    let tarefa = await UIApplication.shared.beginBackgroundTask(withName: "token-atividade")
    for tentativa in 0..<3 {
      if let resposta = try? await URLSession.shared.data(for: requisicao),
         let http = resposta.1 as? HTTPURLResponse, http.statusCode < 500 {
        break
      }
      try? await Task.sleep(nanoseconds: UInt64(2 + tentativa * 3) * 1_000_000_000)
    }
    await UIApplication.shared.endBackgroundTask(tarefa)
  }

  /// Guarda a foto do profissional no App Group, já reduzida (a atividade tem limite de tamanho de imagem).
  /// Devolve true quando baixou agora.
  @discardableResult
  static func baixarFoto(_ endereco: String) async -> Bool {
    guard
      let arquivo = FotoProfissional.arquivo(endereco),
      !FileManager.default.fileExists(atPath: arquivo.path),
      let url = URL(string: endereco),
      let resposta = try? await URLSession.shared.data(from: url),
      let imagem = UIImage(data: resposta.0)
    else {
      return false
    }

    let lado: CGFloat = 120
    let formato = UIGraphicsImageRendererFormat()
    formato.scale = 1
    let reduzida = UIGraphicsImageRenderer(size: CGSize(width: lado, height: lado), format: formato).image { _ in
      let escala = max(lado / imagem.size.width, lado / imagem.size.height)
      let tamanho = CGSize(width: imagem.size.width * escala, height: imagem.size.height * escala)
      imagem.draw(in: CGRect(
        x: (lado - tamanho.width) / 2,
        y: (lado - tamanho.height) / 2,
        width: tamanho.width,
        height: tamanho.height
      ))
    }

    guard let jpeg = reduzida.jpegData(compressionQuality: 0.8) else {
      return false
    }
    try? FileManager.default.createDirectory(
      at: arquivo.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    return (try? jpeg.write(to: arquivo, options: .atomic)) != nil
  }

  private static func hex(_ dados: Data) -> String {
    dados.map { String(format: "%02x", $0) }.joined()
  }
}
