import 'dart:io';

import 'package:app_razor/functions/local_storage.dart';
import 'package:app_razor/functions/token_storage.dart';
import 'package:app_razor/pages/login/login_page.dart';
import 'package:muller_package/muller_package.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CachedResponse {
  final String body;
  final int statusCode;
  final DateTime timestamp;

  _CachedResponse(this.body, this.statusCode, this.timestamp);

  bool isValid() {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(timestamp);
    return difference.inMinutes < HttpCache._cacheDurationMinutes;
  }
}

class HttpCache {
  static const String _cachePrefix = 'http_cache_';
  static const String _timestampPrefix = 'http_timestamp_';
  static const int _cacheDurationMinutes = 5;

  static final Map<String, _CachedResponse> _memoryCache = {};

  static String _generateCacheKey(
    String endpoint,
    Map<String, String>? parameters,
  ) {
    String key = endpoint;
    if (parameters != null && parameters.isNotEmpty) {
      final Map<String, String> sortedParams = Map<String, String>.fromEntries(
        parameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      key +=
          '?${sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    return key;
  }

  static Map<String, String>? _convertParameters(
    Map<String, dynamic>? parameters,
  ) {
    if (parameters == null) {
      return null;
    }
    return parameters.map(
      (String key, dynamic value) => MapEntry(key, value.toString()),
    );
  }

  static Future<Map<String, String>?> _authHeaders() async {
    return getAuthHeaders();
  }

  static Future<void> _handle401() async {
    await clearCache();
    await clearLocalData();
    open(screen: const LoginPage(), closePrevious: true);
  }

  static Future<void> _saveToCache(
    String key,
    String responseBody,
    int statusCode,
  ) async {
    try {
      _memoryCache[key] = _CachedResponse(
        responseBody,
        statusCode,
        DateTime.now(),
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', responseBody);
      await prefs.setInt(
        '$_timestampPrefix$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Erro silencioso
    }
  }

  static Future<AppResponse?> _getFromCache(String key) async {
    try {
      final _CachedResponse? memoryCached = _memoryCache[key];
      if (memoryCached != null && memoryCached.isValid()) {
        return AppResponse(
          statusCode: memoryCached.statusCode,
          body: memoryCached.body,
        );
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? body = prefs.getString('$_cachePrefix$key');
      final int? timestampMs = prefs.getInt('$_timestampPrefix$key');

      if (body == null || timestampMs == null) {
        return null;
      }

      final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(
        timestampMs,
      );
      final _CachedResponse cached = _CachedResponse(body, 200, timestamp);
      if (!cached.isValid()) {
        await prefs.remove('$_cachePrefix$key');
        await prefs.remove('$_timestampPrefix$key');
        _memoryCache.remove(key);
        return null;
      }

      _memoryCache[key] = cached;
      return AppResponse(statusCode: cached.statusCode, body: cached.body);
    } catch (_) {
      return null;
    }
  }

  static Future<AppResponse> getHTTPCached({
    required String endpoint,
    Map<String, dynamic>? parameters,
    bool forceRefresh = false,
  }) async {
    final Map<String, String>? stringParams = _convertParameters(parameters);
    final String cacheKey = _generateCacheKey(endpoint, stringParams);
    final Map<String, String>? headers = await _authHeaders();

    try {
      if (!forceRefresh) {
        final AppResponse? cached = await _getFromCache(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      final AppResponse response = await getHTTP(
        endpoint: endpoint,
        parameters: stringParams,
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _saveToCache(cacheKey, response.body, response.statusCode);
      }

      return response;
    } on ApiException catch (e) {
      if (e.response.statusCode == 401) {
        await _handle401();
      }
      rethrow;
    }
  }

  static Future<AppResponse> postHTTPCached({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, dynamic>? parameters,
    File? file,
  }) async {
    final Map<String, String>? stringParams = _convertParameters(parameters);
    final Map<String, String>? headers = await _authHeaders();

    try {
      return await postHTTP(
        endpoint: endpoint,
        body: body ?? <String, dynamic>{},
        parameters: stringParams,
        file: file,
        headers: headers,
      );
    } on ApiException catch (e) {
      if (e.response.statusCode == 401) {
        await _handle401();
      }
      rethrow;
    }
  }

  static Future<AppResponse> putHTTPCached({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, dynamic>? parameters,
  }) async {
    final Map<String, String>? stringParams = _convertParameters(parameters);
    final Map<String, String>? headers = await _authHeaders();

    try {
      return await putHTTP(
        endpoint: endpoint,
        body: body,
        parameters: stringParams,
        headers: headers,
      );
    } on ApiException catch (e) {
      if (e.response.statusCode == 401) {
        await _handle401();
      }
      rethrow;
    }
  }

  static Future<AppResponse> deleteHTTPCached({
    required String endpoint,
    Map<String, dynamic>? parameters,
  }) async {
    final Map<String, String>? stringParams = _convertParameters(parameters);
    final Map<String, String>? headers = await _authHeaders();

    try {
      return await deleteHTTP(
        endpoint: endpoint,
        parameters: stringParams,
        headers: headers,
      );
    } on ApiException catch (e) {
      if (e.response.statusCode == 401) {
        await _handle401();
      }
      rethrow;
    }
  }

  static Future<void> invalidateContaining(String fragment) async {
    try {
      _memoryCache.removeWhere((String key, _) => key.contains(fragment));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> keys = prefs.getKeys().where((String key) {
        final bool isCacheKey =
            key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix);
        return isCacheKey && key.contains(fragment);
      }).toList();

      for (final String key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Erro silencioso
    }
  }

  static Future<void> clearCache() async {
    try {
      _memoryCache.clear();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();
      for (final String key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {
      // Erro silencioso
    }
  }
}
