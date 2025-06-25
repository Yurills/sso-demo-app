class SsoConfig {
  final String clientId;
  final String redirectUri;
  final String scope;
  final String ssoPortalUri;

  SsoConfig({
    required this.clientId,
    required this.redirectUri,
    required this.scope,
    required this.ssoPortalUri,
  });

  static SsoConfig get instance => SsoConfig(
        clientId: 'client-app-demo',
        redirectUri: 'myapp://callback',
        scope: 'openid profile email',
        ssoPortalUri: 'http://localhost:8080/api/sso',
      );
}