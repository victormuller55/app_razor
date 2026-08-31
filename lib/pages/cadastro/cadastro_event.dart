abstract class CadastroEvent {}

class CadastroSaveEvent extends CadastroEvent {
  final String nome;
  final String email;
  final String senha;

  CadastroSaveEvent({
    required this.nome,
    required this.email,
    required this.senha,
  });
}
