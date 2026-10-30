import 'package:flutter/foundation.dart';

/// Avisa a aba de agendamentos (que fica montada no menu) que algo mudou no servidor: push recebido ou
/// aviso de pagamento, devolução ou mudança no horário (RAZ-11). A aba recarrega sem cache.
final ValueNotifier<int> agendamentosAtualizados = ValueNotifier<int>(0);

void avisarAgendamentosAtualizados() {
  agendamentosAtualizados.value++;
}
