import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

class SalesforceContactIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final service = ref.watch(salesforceServiceProvider);
    return service.getContactId();
  }

  Future<void> save(String id) async {
    final service = ref.read(salesforceServiceProvider);
    await service.setContactId(id);
    state = AsyncData(id);
  }

  Future<void> clear() async {
    final service = ref.read(salesforceServiceProvider);
    await service.clearContactId();
    state = const AsyncData(null);
  }
}

final salesforceContactIdProvider =
    AsyncNotifierProvider<SalesforceContactIdNotifier, String?>(
  SalesforceContactIdNotifier.new,
);
