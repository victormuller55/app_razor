abstract class RecuperarSenhaEvent {}

/// Pede o código (ou reenvia, com o mesmo e-mail).
class RecuperarSenhaSolicitarEvent extends RecuperarSenhaEvent {
  final String email;

  RecuperarSenhaSolicitarEvent({required this.email});
}

class RecuperarSenhaVerificarEvent extends RecuperarSenhaEvent {
  final String codigo;

  RecuperarSenhaVerificarEvent({required this.codigo});
}

class RecuperarSenhaRedefinirEvent extends RecuperarSenhaEvent {
  final String senha;
  final String confirmacao;

  RecuperarSenhaRedefinirEvent({required this.senha, required this.confirmacao});
}

/// Volta ao primeiro passo (trocar e-mail ou pedir outro código).
class RecuperarSenhaRecomecarEvent extends RecuperarSenhaEvent {}
