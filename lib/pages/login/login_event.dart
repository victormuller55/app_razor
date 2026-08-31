abstract class LoginEvent {}

class LoginSaveEvent extends LoginEvent {
  final String email;
  final String senha;

  LoginSaveEvent({
    required this.email,
    required this.senha,
  });
}
