import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _keyToken = 'jwt_token';

const FlutterSecureStorage _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

Future<void> saveToken(String? token) async {
  if (token == null || token.isEmpty) {
    await _storage.delete(key: _keyToken);
    return;
  }

  await _storage.write(key: _keyToken, value: token);
}

Future<String?> getToken() async {
  return _storage.read(key: _keyToken);
}

Future<Map<String, String>?> getAuthHeaders() async {
  final String? token = await getToken();

  if (token == null || token.isEmpty) {
    return null;
  }

  return <String, String>{'Authorization': 'Bearer $token'};
}

Future<void> clearToken() async {
  await _storage.delete(key: _keyToken);
}
