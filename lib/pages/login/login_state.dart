import 'package:app_razor/models/login_model.dart';
import 'package:muller_package/muller_package.dart';

abstract class LoginState {
  ErrorModel errorModel;
  LoginModel loginModel;

  LoginState({
    required this.errorModel,
    required this.loginModel,
  });
}

class LoginInitialState extends LoginState {
  LoginInitialState()
      : super(
          errorModel: ErrorModel.empty(),
          loginModel: LoginModel.empty(),
        );
}

class LoginLoadingState extends LoginState {
  LoginLoadingState()
      : super(
          errorModel: ErrorModel.empty(),
          loginModel: LoginModel.empty(),
        );
}

class LoginSuccessState extends LoginState {
  LoginSuccessState({required super.loginModel})
      : super(errorModel: ErrorModel.empty());
}

class LoginErrorState extends LoginState {
  LoginErrorState({required super.errorModel})
      : super(loginModel: LoginModel.empty());
}
