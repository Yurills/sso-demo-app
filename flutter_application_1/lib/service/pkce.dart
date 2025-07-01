import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class Pkce {
  late final String codeVerifier;
  late final String codeChallenge;

  Pkce() {
    codeVerifier = _generateCodeVerifier();
    codeChallenge = _generateCodeChallenge(codeVerifier);
  }

  Pkce.restore({required String codeVerifier}){
    codeVerifier = codeVerifier;
    codeChallenge = base64UrlEncode(sha256.convert(utf8.encode(codeVerifier)).bytes).replaceAll('=', '');

  }

  static String _generateCodeVerifier() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (i) => rand.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _generateCodeChallenge(String codeVerifier) {
    final bytesVerifier = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytesVerifier);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
    
}
