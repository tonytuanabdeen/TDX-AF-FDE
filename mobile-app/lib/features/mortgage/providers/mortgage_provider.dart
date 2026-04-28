import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mortgage_application.dart';
import '../models/mortgage_question.dart';

// ─── Wizard state ─────────────────────────────────────────────────────────────

class WizardState {
  const WizardState({
    this.currentStep = -1, // -1 = intro screen
    this.answers = const {},
    this.submitted = false,
  });

  final int currentStep;
  final Map<String, String> answers;
  final bool submitted;

  bool get isIntro => currentStep == -1;
  bool get isComplete => currentStep >= mortgageQuestions.length;

  WizardState copyWith({
    int? currentStep,
    Map<String, String>? answers,
    bool? submitted,
  }) =>
      WizardState(
        currentStep: currentStep ?? this.currentStep,
        answers: answers ?? this.answers,
        submitted: submitted ?? this.submitted,
      );
}

class WizardNotifier extends StateNotifier<WizardState> {
  WizardNotifier() : super(const WizardState());

  void start() => state = state.copyWith(currentStep: 0);

  void setAnswer(String questionId, String value) {
    final updated = Map<String, String>.from(state.answers);
    updated[questionId] = value;
    state = state.copyWith(answers: updated);
  }

  void next() {
    if (state.currentStep < mortgageQuestions.length) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void back() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    } else if (state.currentStep == 0) {
      state = state.copyWith(currentStep: -1);
    }
  }

  Future<void> submit() async {
    final app = MortgageApplication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      answers: Map.from(state.answers),
      submittedAt: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mortgage_application_${app.id}', jsonEncode(app.toJson()));
    state = state.copyWith(submitted: true);
  }

  void reset() => state = const WizardState();
}

final wizardProvider = StateNotifierProvider.autoDispose<WizardNotifier, WizardState>(
  (ref) => WizardNotifier(),
);

