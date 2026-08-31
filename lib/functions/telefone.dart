import 'package:app_razor/functions/abrir_rota.dart';
import 'package:url_launcher/url_launcher.dart';

const String contatoMensagemIndisponivel = 'Não foi possível abrir o contato.';

String digitosTelefone(String? value) {
  if (value == null) {
    return '';
  }

  return value.replaceAll(RegExp(r'\D'), '');
}

String normalizaTelefoneBr(String? value) {
  String digits = digitosTelefone(value);

  if (digits.startsWith('55') && (digits.length == 12 || digits.length == 13)) {
    digits = digits.substring(2);
  }

  return digits;
}

String formataTelefone(String? value) {
  final String digits = normalizaTelefoneBr(value);

  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }

  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }

  final String? original = value?.trim();
  return original == null || original.isEmpty ? '' : original;
}

bool ehCelularWhatsApp(String? value) {
  final String digits = normalizaTelefoneBr(value);
  return digits.length == 11 && digits[2] == '9';
}

String? telefoneE164(String? value) {
  final String digits = normalizaTelefoneBr(value);

  if (digits.length != 10 && digits.length != 11) {
    return null;
  }

  return '55$digits';
}

Uri? telefoneUri(String? value) {
  final String? e164 = telefoneE164(value);

  if (e164 == null) {
    return null;
  }

  return Uri.parse('tel:+$e164');
}

Uri? whatsappUri(String? value) {
  if (!ehCelularWhatsApp(value)) {
    return null;
  }

  final String? e164 = telefoneE164(value);

  if (e164 == null) {
    return null;
  }

  return Uri.https('wa.me', '/$e164');
}

Future<void> _abrirContato(Uri? uri, {LaunchRota? launch}) async {
  if (uri == null) {
    throw const RotaException(contatoMensagemIndisponivel);
  }

  final LaunchRota launcher = launch ?? _launchPadrao;
  final bool abriu = await launcher(uri);

  if (!abriu) {
    throw const RotaException(contatoMensagemIndisponivel);
  }
}

Future<bool> _launchPadrao(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> abrirTelefone(String? telefone, {LaunchRota? launch}) {
  return _abrirContato(telefoneUri(telefone), launch: launch);
}

Future<void> abrirWhatsApp(String? telefone, {LaunchRota? launch}) {
  return _abrirContato(whatsappUri(telefone), launch: launch);
}
