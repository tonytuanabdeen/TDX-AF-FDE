import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _seedContactId();
  runApp(const ProviderScope(child: FdeBankApp()));
}

// Writes the dev contact ID to prefs on first launch if not already set.
Future<void> _seedContactId() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(AppConstants.sfContactIdKey) == null) {
    await prefs.setString(AppConstants.sfContactIdKey, AppConstants.sfContactId);
  }
}
