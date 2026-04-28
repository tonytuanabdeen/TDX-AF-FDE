import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../core/services/salesforce/salesforce_auth_service.dart';
import '../../../core/services/salesforce/salesforce_config.dart';
import '../../../core/services/salesforce/salesforce_http_client.dart';
import '../models/agent_session.dart';

class AgentSessionException implements Exception {
  AgentSessionException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'AgentSessionException: $message';
}

class AgentMessageException implements Exception {
  AgentMessageException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'AgentMessageException: $message';
}

class AgentService {
  AgentService(this._auth);

  final SalesforceAuthService _auth;
  final _http = const SalesforceHttpClient();
  final _uuid = const Uuid();
  int _sequenceId = 1;

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-b3-sampled': '1',
      };

  Future<AgentSession> createSession(String contactId) async {
    final token = await _auth.getAccessToken();
    final uri = Uri.parse(
      '${SalesforceConfig.agentApiBaseUrl}'
      '/agents/${SalesforceConfig.agentId}/sessions',
    );

    final body = jsonEncode({
      'externalSessionKey': _uuid.v4(),
      'instanceConfig': {
        'endpoint': SalesforceConfig.instanceUrl,
      },
      'featureSupport': 'Streaming',
      'streamingCapabilities': {
        'chunkTypes': ['Text'],
      },
      'variables': [
        {
          'name': r'$Context.EndUserLanguage',
          'type': 'Text',
          'value': 'en_US',
        },
        {
          'name': 'salesforceContactId',
          'type': 'Text',
          'value': contactId,
        },
      ],
    });

    final response = await _http.post(uri, headers: _headers(token), body: body);

    if (response.statusCode == 401) {
      dev.log('[Agent] 401 — refreshing token and retrying', name: 'SF:HTTP');
      _auth.clearToken();
      final newToken = await _auth.getAccessToken(forceRefresh: true);
      final retry = await _http.post(uri, headers: _headers(newToken), body: body);
      return _parseSession(retry);
    }

    return _parseSession(response);
  }

  Future<String> sendMessage(String sessionId, String message) async {
    final token = await _auth.getAccessToken();
    final uri = Uri.parse(
      '${SalesforceConfig.agentApiBaseUrl}/sessions/$sessionId/messages',
    );

    final body = jsonEncode({
      'message': {
        'sequenceId': _sequenceId++,
        'type': 'Text',
        'text': message,
      },
      'variables': [],
    });

    dev.log('[Agent] Sending message seq:${_sequenceId - 1} to session $sessionId', name: 'SF:HTTP');
    final response = await _http.post(uri, headers: _headers(token), body: body);

    if (response.statusCode == 401) {
      _auth.clearToken();
      final newToken = await _auth.getAccessToken(forceRefresh: true);
      final retry = await _http.post(uri, headers: _headers(newToken), body: body);
      return _parseReply(retry);
    }

    return _parseReply(response);
  }

  Future<void> endSession(String sessionId) async {
    try {
      final token = await _auth.getAccessToken();
      final uri = Uri.parse(
        '${SalesforceConfig.agentApiBaseUrl}/sessions/$sessionId',
      );
      await _http.delete(uri, headers: _headers(token));
    } catch (e) {
      dev.log('[Agent] endSession silently failed: $e', name: 'Agentforce');
    }
  }

  AgentSession _parseSession(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractError(response.body) ??
          'Failed to create session (HTTP ${response.statusCode})';
      throw AgentSessionException(msg, statusCode: response.statusCode);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final session = AgentSession.fromJson(json);

    // Extract the welcome message returned alongside the session
    final welcome = _extractReply(json);
    if (welcome.isNotEmpty) {
      session.welcomeMessage = welcome;
    }

    _sequenceId = 1;
    return session;
  }

  String _parseReply(http.Response response) {
    if (response.statusCode != 200) {
      final msg = _extractError(response.body) ??
          'Failed to send message (HTTP ${response.statusCode})';
      throw AgentMessageException(msg, statusCode: response.statusCode);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractReply(json);
  }

  // Real API: messages[].message is a plain String (not a nested object)
  String _extractReply(Map<String, dynamic> json) {
    final messages = json['messages'] as List<dynamic>? ?? [];
    final chunks = <String>[];
    for (final m in messages) {
      final msg = m as Map<String, dynamic>?;
      if (msg == null) continue;
      final text = msg['message'] as String?;
      if (text != null && text.isNotEmpty) chunks.add(text);
    }
    if (chunks.isNotEmpty) return chunks.join(' ');
    return '';
  }

  String? _extractError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is List && json.isNotEmpty) {
        return json.first['message'] as String?;
      }
      if (json is Map) {
        return json['message'] as String? ?? json['error'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
