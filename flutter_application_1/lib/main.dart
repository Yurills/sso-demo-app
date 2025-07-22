import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/sso_login_page.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides(); //overrides any https cert checks
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSO Client Demo App',
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SsoLoginPage(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Allow all certificates for development purposes
      return true;
    };
    return client;
  }
}
