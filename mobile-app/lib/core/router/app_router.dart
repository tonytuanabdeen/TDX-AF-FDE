import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/mortgage/screens/mortgage_wizard_screen.dart';
import '../../features/mortgage/screens/mortgage_chat_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

enum AppRoute {
  home('/'),
  accounts('/accounts'),
  payments('/payments'),
  profile('/profile'),
  mortgage('/mortgage'),
  mortgageChat('/mortgage/chat');

  const AppRoute(this.path);
  final String path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.home.path,
    routes: [
      // Tab shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.accounts.path,
                builder: (context, state) => const AccountsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.payments.path,
                builder: (context, state) => const PaymentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Mortgage flow — full-screen above the tab bar
      GoRoute(
        path: AppRoute.mortgage.path,
        builder: (context, state) => const MortgageWizardScreen(),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) => const MortgageChatScreen(),
          ),
        ],
      ),
    ],
  );
});
