import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../../profile/providers/contact_provider.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final contactAsync = ref.watch(contactProvider);

    final firstName = contactAsync.maybeWhen(
      data: (c) => c?.fullName.split(' ').first ?? 'there',
      orElse: () => '',
    );

    final balance = contactAsync.maybeWhen(
      data: (c) => c?.currentBalance,
      orElse: () => null,
    );

    final balanceText = balance != null
        ? '\$${balance.toStringAsFixed(2).replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+\.)'),
              (m) => '${m[1]},',
            )}'
        : '—';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.brandRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'FB',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FDE Bank',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.secondaryLabel,
              ),
            ),
            const SizedBox(height: 2),
            contactAsync.when(
              loading: () => _shimmerName(scheme),
              error: (_, __) => _nameText('Welcome back!', scheme),
              data: (c) => _nameText(
                firstName.isNotEmpty ? firstName : 'Welcome back!',
                scheme,
              ),
            ),
            const SizedBox(height: 20),
            _BalanceCard(balanceText: balanceText, isLoading: contactAsync.isLoading),
            const SizedBox(height: 28),
            Text(
              'Quick Actions',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _QuickAction(icon: Icons.north_east_rounded, label: 'Send'),
                SizedBox(width: 10),
                _QuickAction(icon: Icons.south_west_rounded, label: 'Receive'),
                SizedBox(width: 10),
                _QuickAction(icon: Icons.swap_horiz_rounded, label: 'Transfer'),
                SizedBox(width: 10),
                _QuickAction(icon: Icons.apps_rounded, label: 'More'),
              ],
            ),
            const SizedBox(height: 28),
            _MortgageBanner(),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See all',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.brandRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _TransactionList(scheme: scheme),
          ],
        ),
      ),
    );
  }

  Widget _nameText(String text, ColorScheme scheme) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
  }

  Widget _shimmerName(ColorScheme scheme) {
    return Container(
      width: 160,
      height: 32,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ─── Balance card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceText, required this.isLoading});

  final String balanceText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 148,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.brandRed, Color(0xFF8B0014)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandRed.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white.withValues(alpha: 0.6),
            size: 24,
          ),
          const SizedBox(height: 10),
          Text(
            'Total Balance',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? Container(
                  width: 140,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              : Text(
                  balanceText,
                  style: GoogleFonts.dmSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppTheme.brandRed),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mortgage banner ──────────────────────────────────────────────────────────

class _MortgageBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/mortgage'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_rounded,
                  color: AppTheme.brandRed, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request a Mortgage',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Start your application in 3 minutes',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.secondaryLabel),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction list ─────────────────────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.scheme});

  final ColorScheme scheme;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final transactions = TransactionModel.fakeTransactions;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: transactions.asMap().entries.map((e) {
          final i = e.key;
          final tx = e.value;
          final isLast = i == transactions.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tx.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tx.icon, color: tx.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.merchant,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tx.category} · ${_formatDate(tx.date)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppTheme.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${tx.isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tx.isCredit ? Colors.green : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 66,
                  color: isDark
                      ? AppTheme.darkSeparator
                      : AppTheme.lightSeparator,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
