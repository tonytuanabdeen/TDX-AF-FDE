import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

/// Drop-in wrapper around [http] that logs every Salesforce request/response.
/// Auth tokens are truncated to avoid leaking credentials in logs.
class SalesforceHttpClient {
  const SalesforceHttpClient();

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    _logRequest('GET', uri, headers, null);
    final response = await http.get(uri, headers: headers);
    _logResponse('GET', uri, response);
    return response;
  }

  Future<http.Response> post(Uri uri,
      {Map<String, String>? headers, String? body}) async {
    _logRequest('POST', uri, headers, body);
    final response = await http.post(uri, headers: headers, body: body);
    _logResponse('POST', uri, response);
    return response;
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) async {
    _logRequest('DELETE', uri, headers, null);
    final response = await http.delete(uri, headers: headers);
    _logResponse('DELETE', uri, response);
    return response;
  }

  void _logRequest(
    String method,
    Uri uri,
    Map<String, String>? headers,
    String? body,
  ) {
    final sanitizedHeaders = _sanitizeHeaders(headers);
    dev.log(
      '──────────────────────────────────────\n'
      '→ $method ${uri.toString()}\n'
      '  Headers: $sanitizedHeaders\n'
      '  Body: ${body ?? '(none)'}',
      name: 'SF:HTTP',
    );
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    final status = response.statusCode;
    final body = response.body.isEmpty ? '(empty)' : response.body;
    final icon = status >= 200 && status < 300 ? '✓' : '✗';
    dev.log(
      '$icon ← $method ${uri.path} → HTTP $status\n'
      '  Body: $body',
      name: 'SF:HTTP',
    );
  }

  Map<String, String> _sanitizeHeaders(Map<String, String>? headers) {
    if (headers == null) return {};
    return headers.map((k, v) {
      if (k.toLowerCase() == 'authorization' && v.length > 20) {
        return MapEntry(k, '${v.substring(0, 20)}…');
      }
      return MapEntry(k, v);
    });
  }
}
