import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/account_model.dart';
import '../../../theme/app_theme.dart';

final _placeholderAccounts = [
  const AccountModel(
    id: '1',
    name: 'Checking Account',
    type: 'Checking',
    balance: '300,000.00',
    currency: '\$',
    maskedNumber: '**** 4242',
  ),
  const AccountModel(
    id: '2',
    name: 'Savings Account',
    type: 'Savings',
    balance: '150,000.00',
    currency: '\$',
    maskedNumber: '**** 8888',
  ),
];

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text('Accounts',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _placeholderAccounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _AccountRow(account: _placeholderAccounts[index]),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.brandRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppTheme.brandRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.maskedNumber,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${account.currency} ${account.balance}',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandRed,
                ),
              ),
              Text(
                account.type,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.secondaryLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
