import 'dart:convert';

import 'package:flutter_application_1/config/sso_config.dart';
import 'package:http/http.dart' as http;
class AuthService {
  static Future<String?> exchangeCodeForToken (String code, String codeVerifier) async {
    final response = await http.post(
      Uri.parse('${SsoConfig.instance.ssoPortalUri}/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': SsoConfig.instance.clientId,
        'grant_type': 'authorization_code',
        'code': code,
        "code_verifier": codeVerifier
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'] as String?;
    } else {
      throw Exception('Failed to exchange code for token: ${response.reasonPhrase}');
    }
  }

  static readJWTClaims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token');
    }
    final payload = parts[1];
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
    return json.decode(decoded);
  }
} 
