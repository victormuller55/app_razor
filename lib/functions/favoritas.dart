import 'package:flutter/foundation.dart';

/// Muda a cada barbearia marcada ou desmarcada como favorita, para a tela
/// inicial recarregar a seção "Barbearias Favoritas".
final ValueNotifier<int> favoritasAlteradas = ValueNotifier<int>(0);
