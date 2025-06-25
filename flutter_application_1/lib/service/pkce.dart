import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class Pkce {
  late final String codeVerifier;
  late final String codeChallenge;

  Pkce() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (i) => rand.nextInt(256));
    codeVerifier = base64UrlEncode(bytes).replaceAll('=', '');
    
    final bytesVerifier = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytesVerifier);
    codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}
