import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/salesforce/salesforce_auth_service.dart';
import '../../../core/services/salesforce/salesforce_contact_service.dart';
import '../../../core/providers/salesforce_contact_id_provider.dart';
import '../models/contact_model.dart';

final salesforceAuthServiceProvider = Provider<SalesforceAuthService>(
  (_) => SalesforceAuthService(),
);

final salesforceContactServiceProvider = Provider<SalesforceContactService>(
  (ref) => SalesforceContactService(ref.watch(salesforceAuthServiceProvider)),
);

final contactProvider = FutureProvider<ContactModel?>((ref) async {
  final contactId = await ref.watch(salesforceContactIdProvider.future);
  if (contactId == null || contactId.isEmpty) return null;

  final service = ref.watch(salesforceContactServiceProvider);
  return service.getContact(contactId);
});
