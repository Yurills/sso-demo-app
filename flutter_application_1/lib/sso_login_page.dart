import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/sso_config.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/service/par_service.dart';
import 'package:flutter_application_1/service/pkce.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

class SsoLoginPage extends StatefulWidget {
  const SsoLoginPage({super.key});

  @override
  State<SsoLoginPage> createState() => _SsoLoginPageState();
}

class _SsoLoginPageState extends State<SsoLoginPage> {
  StreamSubscription? _sub;
  String? _token;
  Map<String, dynamic>? _jwtClaims;
  @override
  void initState() {
    super.initState();
    _listentoRedirect();
  }

  void _listentoRedirect() {
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri != null && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code'];
        final token = await AuthService.exchangeCodeForToken(code!, _pkce!.codeVerifier);
        setState(() {
          _token = token;
          _jwtClaims = AuthService.readJWTClaims(token!);
        });
      }
      
    });
  }

  Pkce? _pkce;  

  void _startSsoLogin() async {
    _pkce = Pkce();
    final ssoUri = Uri.parse('${SsoConfig.instance.ssoPortalUri}/authorize')
        .replace(queryParameters: {
      'client_id': SsoConfig.instance.clientId,
      'response_type': 'code',
      'redirect_uri': SsoConfig.instance.redirectUri,
      'scope': SsoConfig.instance.scope,
      'code_challenge': _pkce!.codeChallenge,
      'code_challenge_method': 'S256',  
      'state': Random.secure().nextInt(1000000).toString(),
    });
    if (await canLaunchUrl(ssoUri)){
      await launchUrl(ssoUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $ssoUri';
    }
  }

  void _sendPar(String token) async {

    final destinationLink = await ParService.requestToken(
      'http://localhost:8081', 
      'http://localhost:8081',
      token,
    );

    _pkce = Pkce();
    final uri = Uri.parse(destinationLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  }

  @override
  void dispose() { 
    _sub?.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('SSO Login'),
    ),
    body: Center(
      child: _token == null
          ? ElevatedButton(
              onPressed: _startSsoLogin,
              child: const Text('Login with SSO'),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Successfully Logged In!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'User: ${_jwtClaims?['sub']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Email: ${_jwtClaims?['email']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Expired At: ${DateTime.fromMillisecondsSinceEpoch(_jwtClaims?['exp'] * 1000)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _token = null;  // Reset token to log out
                    });
                  },
                  child: const Text('Logout'),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _sendPar(_token ?? "");
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.deepPurple, // Set the text color
                  ),
                  child: const Text('Push Authorization Request'),
                )
              ],
            ),
    ),
  );
}

}
