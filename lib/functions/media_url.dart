import 'package:app_razor/app_config/const/app_endpoints.dart';

String? resolveMediaUrl(String? value) {
  if (value == null) {
    return null;
  }

  final String trimmed = value.trim();

  if (trimmed.isEmpty) {
    return null;
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  if (trimmed.startsWith('/')) {
    return '$server$trimmed';
  }

  return trimmed;
}
