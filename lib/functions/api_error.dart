import 'dart:convert';

import 'package:muller_package/muller_package.dart';

ErrorModel errorModelFromApi(Object e) {
  if (e is ApiException) {
    try {
      final dynamic decoded = jsonDecode(e.response.body);

      if (decoded is Map<String, dynamic>) {
        return ErrorModel(
          tipo: '${decoded['status'] ?? e.response.statusCode}',
          mensagem: _buildMensagem(decoded),
          erro: decoded['error']?.toString() ?? '',
        );
      }
    } catch (_) {
      // Resposta não é JSON.
    }

    return ErrorModel(
      tipo: 'http_error',
      mensagem: 'Erro ${e.response.statusCode}',
      erro: e.response.body,
    );
  }

  return ErrorModel(
    tipo: '',
    mensagem: AppStrings.ocorreuUmErro,
    erro: '',
  );
}

String _buildMensagem(Map<String, dynamic> json) {
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

  return AppStrings.ocorreuUmErro;
}
