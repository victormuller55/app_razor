import 'app_ambiente.dart';

export 'app_ambiente.dart';

class AppEndpoints {

  static String get endpointAuthCadastro => '$server/api/v1/auth/cadastro';
  static String get endpointAuthLogin => '$server/api/v1/auth/login';
  static String get endpointAuthRecuperarSenha => '$server/api/v1/auth/recuperar-senha';
  static String get endpointAuthVerificarCodigo => '$server/api/v1/auth/recuperar-senha/verificar';
  static String get endpointAuthRedefinirSenha => '$server/api/v1/auth/recuperar-senha/redefinir';
  static String get endpointUsuariosEu => '$server/api/v1/usuarios/eu';
  static String get endpointUsuariosEuSenha => '$server/api/v1/usuarios/eu/senha';
  static String get endpointUsuariosEuEmail => '$server/api/v1/usuarios/eu/email';
  static String get endpointUsuariosEuFoto => '$server/api/v1/usuarios/eu/foto';
  static String get endpointUsuariosEuExcluir => '$server/api/v1/usuarios/eu/excluir';
  static String get endpointBarbearias => '$server/api/v1/barbearias';
  static String get endpointBarbeariasFavoritas => '$server/api/v1/barbearias/favoritas';
  static String get endpointBarbeariasProximas => '$server/api/v1/barbearias/proximas';
  static String get endpointPromocoesProximas => '$server/api/v1/barbearias/promocoes-proximas';
  static String endpointBarbeariaPerfil(int id) => '$server/api/v1/barbearias/$id';
  static String endpointBarbeariaFavorito(int id) => '$server/api/v1/barbearias/$id/favorito';
  static String endpointAgendamentosCancelar(int id) => '$server/api/v1/agendamentos/$id/cancelar';
  static String endpointAgendamentoPagamento(int id) => '$server/api/v1/agendamentos/$id/pagamento';
  /// Só com a API no provedor simulado (rodando local).
  static String endpointDevPagamentoAprovar(int id) => '$server/api/v1/dev/pagamentos/$id/aprovar';
  static String endpointAgendamentoAvaliacao(int id) => '$server/api/v1/agendamentos/$id/avaliacao';
  static String endpointAgendamentoAvaliacaoAtendimento(int id) =>
      '$server/api/v1/agendamentos/$id/avaliacao-atendimento';
  static String get endpointNotificacoes => '$server/api/v1/notificacoes';
  static String endpointNotificacaoLida(int id) => '$server/api/v1/notificacoes/$id/lida';
  static String endpointOrdemServicoPagamento(int id) => '$server/api/v1/agendamentos/ordem/$id/pagamento';
  static String get endpointAgendamentosPolitica => '$server/api/v1/agendamentos/politica';
  static String endpointOrdemServicoCancelar(int id) => '$server/api/v1/agendamentos/ordem/$id/cancelar';
  static String endpointAgendamentoEditar(int id) => '$server/api/v1/agendamentos/$id';
  static String endpointOrdemServicoEditar(int id) => '$server/api/v1/agendamentos/ordem/$id';
  static String get endpointOrdemServico => '$server/api/v1/agendamentos/ordem';
  static String get endpointAgendamentos => '$server/api/v1/agendamentos';
  static String get endpointAgendamentosContexto => '$server/api/v1/agendamentos/contexto';
  static String get endpointAgendamentosHorarios => '$server/api/v1/agendamentos/horarios-disponiveis';
  static String get endpointAgendamentosNovo => '$server/api/v1/agendamentos/novo';

}
