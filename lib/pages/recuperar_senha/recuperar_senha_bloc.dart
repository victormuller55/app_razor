import 'package:app_razor/functions/api_error.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_event.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_service.dart';
import 'package:app_razor/pages/recuperar_senha/recuperar_senha_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef SolicitarCodigo = Future<Map<String, dynamic>> Function({required String email});
typedef VerificarCodigo = Future<Map<String, dynamic>> Function({
  required String email,
  required String codigo,
});
typedef RedefinirSenha = Future<Map<String, dynamic>> Function({
  required String token,
  required String senha,
  required String confirmacao,
});

/// RAZ-08: recuperação de senha em três passos. Ao terminar, emite [RecuperarSenhaPasso.concluido] e a tela
/// volta para o login: não há login automático.
class RecuperarSenhaBloc extends Bloc<RecuperarSenhaEvent, RecuperarSenhaState> {
  static const int senhaMin = 8;
  static const int senhaMax = 128;

  final SolicitarCodigo _solicitar;
  final VerificarCodigo _verificar;
  final RedefinirSenha _redefinir;

  /// Autorização devolvida pela verificação do código. Só em memória, apagada ao terminar ou recomeçar.
  String _token = '';

  RecuperarSenhaBloc({
    SolicitarCodigo? solicitar,
    VerificarCodigo? verificar,
    RedefinirSenha? redefinir,
  })  : _solicitar = solicitar ?? solicitarCodigoRecuperacao,
        _verificar = verificar ?? verificarCodigoRecuperacao,
        _redefinir = redefinir ?? redefinirSenhaRecuperacao,
        super(const RecuperarSenhaState()) {
    on<RecuperarSenhaSolicitarEvent>(_onSolicitar);
    on<RecuperarSenhaVerificarEvent>(_onVerificar);
    on<RecuperarSenhaRedefinirEvent>(_onRedefinir);
    on<RecuperarSenhaRecomecarEvent>(_onRecomecar);
  }

  bool get temAutorizacao => _token.isNotEmpty;

  Future<void> _onSolicitar(RecuperarSenhaSolicitarEvent event, Emitter<RecuperarSenhaState> emit) async {
    final String email = event.email.trim();
    emit(state.copyWith(carregando: true, erro: '', email: email));
    try {
      final Map<String, dynamic> corpo = await _solicitar(email: email);
      emit(state.copyWith(
        passo: RecuperarSenhaPasso.codigo,
        carregando: false,
        mensagem: corpo['mensagem'] as String? ?? '',
        reenviarEmSegundos: (corpo['reenviar_em_segundos'] as num?)?.toInt() ?? 60,
        validadeMinutos: (corpo['validade_minutos'] as num?)?.toInt() ?? 10,
      ));
    } catch (e) {
      emit(state.copyWith(carregando: false, erro: errorModelFromApi(e).mensagem));
    }
  }

  Future<void> _onVerificar(RecuperarSenhaVerificarEvent event, Emitter<RecuperarSenhaState> emit) async {
    final String codigo = event.codigo.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      emit(state.copyWith(erro: 'O código tem 6 números.'));
      return;
    }
    emit(state.copyWith(carregando: true, erro: ''));
    try {
      final Map<String, dynamic> corpo = await _verificar(email: state.email, codigo: codigo);
      _token = corpo['token'] as String? ?? '';
      emit(state.copyWith(passo: RecuperarSenhaPasso.senha, carregando: false, mensagem: ''));
    } catch (e) {
      emit(state.copyWith(carregando: false, erro: errorModelFromApi(e).mensagem));
    }
  }

  Future<void> _onRedefinir(RecuperarSenhaRedefinirEvent event, Emitter<RecuperarSenhaState> emit) async {
    if (event.senha.length < senhaMin || event.senha.length > senhaMax) {
      emit(state.copyWith(erro: 'A senha deve ter entre $senhaMin e $senhaMax caracteres.'));
      return;
    }
    if (event.senha != event.confirmacao) {
      emit(state.copyWith(erro: 'A confirmação não confere com a nova senha.'));
      return;
    }
    emit(state.copyWith(carregando: true, erro: ''));
    try {
      final Map<String, dynamic> corpo =
          await _redefinir(token: _token, senha: event.senha, confirmacao: event.confirmacao);
      _token = '';
      emit(state.copyWith(
        passo: RecuperarSenhaPasso.concluido,
        carregando: false,
        mensagem: corpo['mensagem'] as String? ?? 'Senha redefinida. Entre com a nova senha.',
      ));
    } catch (e) {
      emit(state.copyWith(carregando: false, erro: errorModelFromApi(e).mensagem));
    }
  }

  void _onRecomecar(RecuperarSenhaRecomecarEvent event, Emitter<RecuperarSenhaState> emit) {
    _token = '';
    emit(RecuperarSenhaState(email: state.email));
  }

  @override
  Future<void> close() {
    _token = '';
    return super.close();
  }
}
