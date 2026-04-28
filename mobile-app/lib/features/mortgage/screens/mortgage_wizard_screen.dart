import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mortgage_question.dart';
import '../providers/mortgage_provider.dart';
import '../widgets/wizard_progress_bar.dart';
import '../widgets/question_input.dart';
import '../../../theme/app_theme.dart';

class MortgageWizardScreen extends ConsumerWidget {
  const MortgageWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);

    if (state.isIntro) return const _IntroPage();
    if (state.isComplete) {
      return state.submitted
          ? const _ConfirmationPage()
          : const _SummaryPage();
    }
    return const _QuestionPage();
  }
}

// ─── Intro ────────────────────────────────────────────────────────────────────

class _IntroPage extends ConsumerWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Mortgage Application',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.home_work_rounded,
                    color: AppTheme.brandRed, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                'Request a Mortgage',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Answer ${mortgageQuestions.length} quick questions and '
                'we\'ll prepare your mortgage application. '
                'It takes about 3 minutes.',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  height: 1.5,
                  color: AppTheme.secondaryLabel,
                ),
              ),
              const SizedBox(height: 32),
              const _InfoRow(
                icon: Icons.lock_outline_rounded,
                text: 'Your information is encrypted and secure',
              ),
              const SizedBox(height: 12),
              const _InfoRow(
                icon: Icons.schedule_rounded,
                text: '10 steps · about 3 minutes',
              ),
              const SizedBox(height: 12),
              const _InfoRow(
                icon: Icons.savings_outlined,
                text: 'No commitment — review before submitting',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brandRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () =>
                      ref.read(wizardProvider.notifier).start(),
                  child: Text(
                    'Start Application',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/mortgage/chat'),
                  child: Text(
                    'Prefer to talk to someone? Chat with FrED →',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppTheme.brandRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.secondaryLabel),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppTheme.secondaryLabel),
          ),
        ),
      ],
    );
  }
}

// ─── Question ─────────────────────────────────────────────────────────────────

class _QuestionPage extends ConsumerWidget {
  const _QuestionPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);
    final question = mortgageQuestions[state.currentStep];
    final answer = state.answers[question.id] ?? '';
    final canAdvance = answer.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: notifier.back,
        ),
        title: Text(
          'Mortgage Application',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: WizardProgressBar(
                current: state.currentStep,
                total: mortgageQuestions.length,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.questionText,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    QuestionInput(
                      question: question,
                      currentAnswer: answer,
                      onChanged: (val) =>
                          notifier.setAnswer(question.id, val),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: canAdvance
                        ? AppTheme.brandRed
                        : AppTheme.secondaryLabel.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: canAdvance ? notifier.next : null,
                  child: Text(
                    state.currentStep == mortgageQuestions.length - 1
                        ? 'Review Application'
                        : 'Next',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary ──────────────────────────────────────────────────────────────────

class _SummaryPage extends ConsumerWidget {
  const _SummaryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: notifier.back,
        ),
        title: Text(
          'Review Application',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Text(
                    'Please review your answers before submitting.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppTheme.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: mortgageQuestions.asMap().entries.map((e) {
                        final i = e.key;
                        final q = e.value;
                        final ans = state.answers[q.id] ?? '—';
                        final isLast =
                            i == mortgageQuestions.length - 1;
                        return Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            q.questionText,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              color:
                                                  AppTheme.secondaryLabel,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            ans,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 0.5,
                                thickness: 0.5,
                                indent: 16,
                                color: scheme.brightness == Brightness.dark
                                    ? AppTheme.darkSeparator
                                    : AppTheme.lightSeparator,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brandRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => notifier.submit(),
                  child: Text(
                    'Submit Application',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirmation ─────────────────────────────────────────────────────────────

class _ConfirmationPage extends ConsumerWidget {
  const _ConfirmationPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.green, size: 40),
              ),
              const SizedBox(height: 28),
              Text(
                'Application Submitted!',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for applying. A mortgage advisor will review '
                'your application and contact you within 2 business days.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  height: 1.5,
                  color: AppTheme.secondaryLabel,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brandRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    ref.read(wizardProvider.notifier).reset();
                    context.go('/');
                  },
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
