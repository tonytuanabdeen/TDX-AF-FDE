import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/salesforce_service.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final salesforceServiceProvider = Provider<SalesforceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return SalesforceService(prefs);
});
