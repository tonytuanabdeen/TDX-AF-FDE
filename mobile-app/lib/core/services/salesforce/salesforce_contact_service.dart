import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'salesforce_auth_service.dart';
import 'salesforce_config.dart';
import 'salesforce_http_client.dart';
import '../../../features/profile/models/contact_model.dart';

class ContactNotFoundException implements Exception {
  ContactNotFoundException(this.contactId);
  final String contactId;
  @override
  String toString() => 'ContactNotFoundException: $contactId not found';
}

class SalesforceContactService {
  SalesforceContactService(this._auth);

  final SalesforceAuthService _auth;
  final _http = const SalesforceHttpClient();

  static const _fields = 'Id,FirstName,LastName,Email,Phone,Current_Balance__c';

  Future<ContactModel> getContact(String contactId) async {
    final token = await _auth.getAccessToken();
    final result = await _fetch(contactId, token);

    if (result.statusCode == 401) {
      dev.log('[SF Contact] 401 — refreshing token and retrying', name: 'SF:HTTP');
      _auth.clearToken();
      final retryToken = await _auth.getAccessToken(forceRefresh: true);
      final retry = await _fetch(contactId, retryToken);
      return _parse(retry, contactId);
    }

    return _parse(result, contactId);
  }

  Future<http.Response> _fetch(String contactId, String token) {
    final uri = Uri.parse(
      '${SalesforceConfig.instanceUrl}'
      '/services/data/${SalesforceConfig.apiVersion}'
      '/sobjects/Contact/$contactId'
      '?fields=$_fields',
    );
    return _http.get(uri, headers: {'Authorization': 'Bearer $token'});
  }

  ContactModel _parse(http.Response response, String contactId) {
    if (response.statusCode == 404) {
      throw ContactNotFoundException(contactId);
    }
    if (response.statusCode != 200) {
      throw Exception('Salesforce error ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final contact = ContactModel.fromJson(json);
    dev.log('[SF Contact] ✓ Loaded: ${contact.fullName}', name: 'SF:HTTP');
    return contact;
  }
}
