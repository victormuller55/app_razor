import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCBZS_CCJuKJ2oraOtG_llZg3a1nUl556k")
    // Antes do Flutter: o iOS pode abrir o app em segundo plano só para entregar o token de uma atividade
    // que o servidor iniciou por push.
    TokensAtividade.shared.iniciar()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LembreteAgendamentoPlugin") {
      LembreteAgendamentoPlugin.register(with: registrar)
    }
  }
}
