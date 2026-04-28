import 'dart:convert';
import 'dart:developer' as dev;
import 'salesforce_config.dart';
import 'salesforce_http_client.dart';

class SalesforceAuthException implements Exception {
  SalesforceAuthException(this.message);
  final String message;
  @override
  String toString() => 'SalesforceAuthException: $message';
}

class SalesforceAuthService {
  final _http = const SalesforceHttpClient();
  String? _cachedToken;

  Future<String> getAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedToken != null) {
      dev.log('[SF Auth] Using cached token', name: 'SF:HTTP');
      return _cachedToken!;
    }
    return _fetchToken();
  }

  void clearToken() {
    dev.log('[SF Auth] Token cache cleared', name: 'SF:HTTP');
    _cachedToken = null;
  }

  Future<String> _fetchToken() async {
    dev.log('[SF Auth] Fetching token via client credentials flow…', name: 'SF:HTTP');

    final uri = Uri.parse('${SalesforceConfig.instanceUrl}/services/oauth2/token');
    final response = await _http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'grant_type=client_credentials'
          '&client_id=${Uri.encodeComponent(SalesforceConfig.clientId)}'
          '&client_secret=${Uri.encodeComponent(SalesforceConfig.clientSecret)}',
    );

    if (response.statusCode != 200) {
      String msg;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        msg = json['error_description'] as String? ??
            json['error'] as String? ??
            'HTTP ${response.statusCode}';
      } catch (_) {
        msg = 'HTTP ${response.statusCode}';
      }
      throw SalesforceAuthException('Token request failed — $msg');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw SalesforceAuthException('No access_token in response');
    }

    _cachedToken = token;
    dev.log('[SF Auth] ✓ Token acquired', name: 'SF:HTTP');
    return token;
  }
}
