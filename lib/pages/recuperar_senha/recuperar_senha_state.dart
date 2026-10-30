enum RecuperarSenhaPasso { email, codigo, senha, concluido }

/// Estado da recuperação de senha. O token de redefinição fica só no bloc, nunca no estado nem no aparelho.
class RecuperarSenhaState {
  final RecuperarSenhaPasso passo;
  final bool carregando;
  final String email;
  final String mensagem;
  final String erro;
  final int reenviarEmSegundos;
  final int validadeMinutos;

  const RecuperarSenhaState({
    this.passo = RecuperarSenhaPasso.email,
    this.carregando = false,
    this.email = '',
    this.mensagem = '',
    this.erro = '',
    this.reenviarEmSegundos = 0,
    this.validadeMinutos = 10,
  });

  RecuperarSenhaState copyWith({
    RecuperarSenhaPasso? passo,
    bool? carregando,
    String? email,
    String? mensagem,
    String? erro,
    int? reenviarEmSegundos,
    int? validadeMinutos,
  }) {
    return RecuperarSenhaState(
      passo: passo ?? this.passo,
      carregando: carregando ?? this.carregando,
      email: email ?? this.email,
      mensagem: mensagem ?? this.mensagem,
      erro: erro ?? this.erro,
      reenviarEmSegundos: reenviarEmSegundos ?? this.reenviarEmSegundos,
      validadeMinutos: validadeMinutos ?? this.validadeMinutos,
    );
  }
}
