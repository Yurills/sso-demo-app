import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/sso_config.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/service/par_service.dart';
import 'package:flutter_application_1/service/pkce.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SsoLoginPage extends StatefulWidget {
  const SsoLoginPage({super.key});

  @override
  State<SsoLoginPage> createState() => _SsoLoginPageState();
}

class _SsoLoginPageState extends State<SsoLoginPage> {
  StreamSubscription? _sub;
  String? _token;
  Map<String, dynamic>? _jwtClaims;
  Pkce? _pkce; 
  @override
  void initState() {
    super.initState();
    _listentoRedirect();
  }

  void _listentoRedirect() {
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;
      
      final prefs = await SharedPreferences.getInstance();

      // Handle the callback from the Auth login
      if (uri.host == 'callback' && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code'];

        if (_pkce == null) {
          final verifier = prefs.getString('code_verifier');
          if (verifier != null){
            _pkce = Pkce.restore(codeVerifier: verifier);
          }else {
            print("No PKCE code verifier found in SharedPreferences");
            return;
          }
        }

        final token = await AuthService.exchangeCodeForToken(code!, _pkce!.codeVerifier);
        setState(() {
          _token = token;
          _jwtClaims = AuthService.readJWTClaims(token!);
        });

        successfullyLoggedIn();
      }

      // Handle SSO callback
      if (uri.host == 'sso' && uri.queryParameters.containsKey('sso_token')) {
        final ssoToken = uri.queryParameters['sso_token'];
        if (ssoToken == null) {
          print("No SSO token found in the URI");
          return;
        }

        _pkce = Pkce();
        await prefs.setString('code_verifier', _pkce!.codeVerifier);
        print("New PKCE initialized with code verifier: ${_pkce!.codeVerifier}");

        final response = await ParService.startPar(ssoToken, _pkce!.codeChallenge);

        String? authCode;
        //check if the response is auth code or request uri
        if (response['request_uri'] != null) {
          final destinationLink = response['request_uri'];
          authCode = await ParService.authorizePar(destinationLink);
        } else if (response['authCode'] != null) {
          authCode = response['authCode'];
        }
        if (authCode == null){
          print("No auth code found in the response");
          return;
        }

        //exchange token
        final token = await AuthService.exchangeCodeForToken(authCode, _pkce!.codeVerifier);
        setState(() {
          _token = token;
          _jwtClaims = AuthService.readJWTClaims(token!);
        });

        successfullyLoggedIn();


    }});
  }


  void _startSsoLogin() async {
    final pkce = Pkce();

    //save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('code_verifier', pkce.codeVerifier);

    setState(() {
      _pkce = pkce;
    });

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

  void successfullyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('code_verifier'); // Clear the code verifier after successful login
    setState(() {
      _pkce = null;
    });

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
