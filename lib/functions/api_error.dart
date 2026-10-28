import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:muller_package/muller_package.dart';

/// Falhas sem resposta do servidor: o `tipo` diz qual foi, para a tela decidir se confere o estado real.
const String tipoSemConexao = 'sem_conexao';
const String tipoTempoEsgotado = 'tempo_esgotado';

const String mensagemSemConexao =
    'Não foi possível concluir esta operação agora. Verifique sua conexão e tente novamente.';
const String mensagemTempoEsgotado =
    'O servidor demorou a responder. Confira se a operação foi concluída antes de tentar de novo.';
const String mensagemServidor =
    'O servidor não conseguiu concluir agora. Tente novamente em instantes.';

ErrorModel errorModelFromApi(Object e) {
  if (e is TimeoutException) {
    return ErrorModel(tipo: tipoTempoEsgotado, mensagem: mensagemTempoEsgotado, erro: '');
  }
  if (_semConexao(e)) {
    return ErrorModel(tipo: tipoSemConexao, mensagem: mensagemSemConexao, erro: '');
  }
  if (e is ApiException) {
    final int status = e.response.statusCode;
    try {
      final dynamic decoded = jsonDecode(e.response.body);

      if (decoded is Map<String, dynamic>) {
        // Corpo que o muller_package monta quando o aparelho está sem rede (só tem "mensagem").
        if (decoded['message'] == null && decoded['tipo'] == 'BAD GATEWAY') {
          return ErrorModel(tipo: tipoSemConexao, mensagem: mensagemSemConexao, erro: '');
        }
        return ErrorModel(
          tipo: '${decoded['status'] ?? status}',
          // O 500 da API é sempre genérico; nunca mostra texto técnico nem o campo error.
          mensagem: status >= 500 && status != 503 ? mensagemServidor : _buildMensagem(decoded, status),
          erro: status >= 500 ? '' : decoded['error']?.toString() ?? '',
        );
      }
    } catch (_) {
      // Resposta não é JSON (HTML de proxy, corpo cortado...).
    }

    return ErrorModel(
      tipo: 'http_error',
      mensagem: status >= 500 ? mensagemServidor : AppStrings.ocorreuUmErro,
      erro: '',
    );
  }

  return ErrorModel(
    tipo: '',
    mensagem: AppStrings.ocorreuUmErro,
    erro: '',
  );
}

/// Rede caiu, servidor fora do ar ou TLS falhou. O `ClientException` do pacote http (que embrulha o
/// SocketException) é reconhecido pelo nome para não depender do pacote só por isso.
bool _semConexao(Object e) {
  return e is SocketException ||
      e is HandshakeException ||
      e is HttpException ||
      e.runtimeType.toString() == 'ClientException';
}

String _buildMensagem(Map<String, dynamic> json, int status) {
  final String message = json['message']?.toString().trim() ?? '';
  final dynamic errors = json['errors'];

  if (errors is Map && errors.isNotEmpty) {
    final List<String> fieldMessages = errors.values
        .map((dynamic value) => value.toString().trim())
        .where((String value) => value.isNotEmpty)
        .toList();

    if (fieldMessages.isNotEmpty) {
      final String joined = fieldMessages.join('\n');
      if (message.isEmpty) {
        return joined;
      }
      return '$message\n$joined';
    }
  }

  if (message.isNotEmpty) {
    return message;
  }

  return status >= 500 ? mensagemServidor : AppStrings.ocorreuUmErro;
}
