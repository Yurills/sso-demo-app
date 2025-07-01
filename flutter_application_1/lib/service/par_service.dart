
import 'dart:convert';
import 'dart:math';

import 'package:flutter_application_1/config/sso_config.dart';
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

  static startPar(String ssoToken, String codeChallenge) async {

    final response = await http.post(
      Uri.parse('${SsoConfig.instance.ssoPortalUri}/par'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'client_id': SsoConfig.instance.clientId,
        'sso_token': ssoToken,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'redirect_uri': SsoConfig.instance.redirectUri,
        'state': Random.secure().nextInt(1000000).toString(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to start PAR: ${response.reasonPhrase}');
    }
  }
  static Future<String> authorizePar(String requestUri) async {
    final response = await http.post(
      Uri.parse('${SsoConfig.instance.ssoPortalUri}/par/authorize'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'request_uri': requestUri,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      return data['code'] as String;
    } else {
      throw Exception('Failed to authorize PAR: ${response.reasonPhrase}');
    }
  }



}