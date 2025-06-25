
import 'dart:convert';

import 'package:flutter_application_1/config/sso_config.dart';
import 'package:flutter_application_1/service/pkce.dart';
import 'package:http/http.dart' as http;
class ParService {
  static Future<String> requestToken (String destination, String destinationLink, String token) async {
    final response = await http.post(
      Uri.parse('${SsoConfig.instance.ssoPortalUri}/par/request.token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'client_id': SsoConfig.instance.clientId,
        'source': 'myweb://',
        'destination': destination,
        'destination_link': destinationLink,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['destination_link'] as String;
    } else {
      throw Exception('Failed to request token: ${response.reasonPhrase}');
    }
  }

  static startPar(String destination, String ssoToken) async {
    // Generate PKCE code verifier and challenge
    final pkce = Pkce();
    final parUri = Uri.parse('$destination/par')
        .replace(queryParameters: {
      'client_id': SsoConfig.instance.clientId,
      'sso_token': ssoToken,
      'code_challenge': pkce.codeChallenge,
      'code_challenge_method': 'S256',
      'redirect_uri': 'http://localhost:8081/callback',
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    return parUri.toString();
  }
}