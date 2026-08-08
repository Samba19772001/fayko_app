import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralise tous les appels à l'API Fayko. Toutes les autres parties de
/// l'app (écrans, providers) passent par ce service plutôt que d'appeler
/// http directement — ça évite de dupliquer la gestion du jeton et des
/// erreurs partout.
class ApiService {
  // À changer pour l'URL réelle du serveur en production.
  // 10.0.2.2 = alias spécial pour "localhost de la machine hôte" depuis
  // un émulateur Android. Sur un simulateur iOS ou en web, utilise
  // http://127.0.0.1:8000 à la place.
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() => _storage.read(key: 'auth_token');

  Future<void> saveToken(String token) =>
      _storage.write(key: 'auth_token', value: token);

  Future<void> deleteToken() => _storage.delete(key: 'auth_token');

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // Les erreurs de notre API renvoient toujours {"message": "..."} —
    // on la propage sous forme d'exception pour que l'écran l'affiche.
    final message = decoded is Map && decoded['message'] != null
        ? decoded['message']
        : 'Une erreur est survenue (${response.statusCode}).';
    throw ApiException(message, statusCode: response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}
