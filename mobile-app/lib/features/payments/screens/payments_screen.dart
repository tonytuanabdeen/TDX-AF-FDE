import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int _selectedAccountIndex = 0;

  static const _accounts = [
    'Checking  ·  **** 4242',
    'Savings  ·  **** 8888',
  ];

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text('Payments', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Payment',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              const _Label('FROM ACCOUNT'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: List.generate(_accounts.length, (i) {
                    final selected = _selectedAccountIndex == i;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedAccountIndex = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _accounts[i],
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_rounded,
                                  size: 18, color: AppTheme.brandRed),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              const _Label('RECIPIENT'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recipientController,
                style: GoogleFonts.dmSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Name or account number',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 15, color: AppTheme.secondaryLabel),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              const _Label('AMOUNT'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.dmSans(fontSize: 15),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 15, color: AppTheme.secondaryLabel),
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const _Label('NOTE (OPTIONAL)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: GoogleFonts.dmSans(fontSize: 15),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What is this for?',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 15, color: AppTheme.secondaryLabel),
                ),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  icon: const Icon(Icons.north_east_rounded, size: 18),
                  label: Text(
                    'Send Payment',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brandRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment flow coming soon',
                              style: GoogleFonts.dmSans()),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppTheme.secondaryLabel,
      ),
    );
  }
}
