/// Base local da API Razor.
///
/// Emulador Android: use `http://10.0.2.2:5000` no lugar de `localhost`
/// (10.0.2.2 é o loopback do PC no emulador).
/// Dispositivo físico na mesma rede: use o IP Wi-Fi do notebook.
const String server = 'http://10.0.2.2:5000';

class AppEndpoints {
  static String get endpointAuthCadastro => '$server/api/v1/auth/cadastro';

  static String get endpointAuthLogin => '$server/api/v1/auth/login';

  static String get endpointUsuariosEu => '$server/api/v1/usuarios/eu';

  static String get endpointUsuariosEuSenha => '$server/api/v1/usuarios/eu/senha';

  static String get endpointUsuariosEuEmail => '$server/api/v1/usuarios/eu/email';

  static String get endpointUsuariosEuFoto => '$server/api/v1/usuarios/eu/foto';

  static String get endpointUsuariosEuExcluir =>
      '$server/api/v1/usuarios/eu/excluir';

  static String get endpointBarbearias => '$server/api/v1/barbearias';

  static String get endpointBarbeariasFavoritas =>
      '$server/api/v1/barbearias/favoritas';

  static String get endpointBarbeariasProximas =>
      '$server/api/v1/barbearias/proximas';

  static String get endpointPromocoesProximas =>
      '$server/api/v1/barbearias/promocoes-proximas';

  static String endpointBarbeariaPerfil(int id) =>
      '$server/api/v1/barbearias/$id';

  static String get endpointAgendamentos => '$server/api/v1/agendamentos';

  static String get endpointAgendamentosContexto =>
      '$server/api/v1/agendamentos/contexto';

  static String get endpointAgendamentosHorarios =>
      '$server/api/v1/agendamentos/horarios-disponiveis';

  static String get endpointAgendamentosNovo =>
      '$server/api/v1/agendamentos/novo';

  static String endpointAgendamentosCancelar(int id) =>
      '$server/api/v1/agendamentos/$id/cancelar';
}
