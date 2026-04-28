import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'features/profile/providers/contact_provider.dart';
import 'theme/app_theme.dart';

class FdeBankApp extends ConsumerWidget {
  const FdeBankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Pre-warm contact data so the Profile tab loads instantly
    ref.watch(contactProvider);

    return MaterialApp.router(
      title: 'FDE Bank',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
