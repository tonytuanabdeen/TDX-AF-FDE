enum InputType { text, currency, picklist, yesNo, yesNoWithDetail }

class MortgageQuestion {
  const MortgageQuestion({
    required this.id,
    required this.questionText,
    required this.inputType,
    this.options = const [],
    this.detailHint,
  });

  final String id;
  final String questionText;
  final InputType inputType;
  final List<String> options;
  final String? detailHint;
}

const List<MortgageQuestion> mortgageQuestions = [
  MortgageQuestion(
    id: 'purpose',
    questionText: 'What is the purpose of the loan?',
    inputType: InputType.picklist,
    options: ['Primary Residence', 'Second Home', 'Investment Property'],
  ),
  MortgageQuestion(
    id: 'purchase_price',
    questionText: 'What is the property purchase price?',
    inputType: InputType.currency,
  ),
  MortgageQuestion(
    id: 'loan_amount',
    questionText: 'What is the amount you wish to borrow?',
    inputType: InputType.currency,
  ),
  MortgageQuestion(
    id: 'loan_term',
    questionText: 'What is the loan term you are looking for?',
    inputType: InputType.picklist,
    options: ['10 years', '15 years', '20 years', '25 years', '30 years'],
  ),
  MortgageQuestion(
    id: 'employment_status',
    questionText: 'What is your employment status?',
    inputType: InputType.picklist,
    options: ['Employed', 'Self-Employed', 'Retired', 'Other'],
  ),
  MortgageQuestion(
    id: 'annual_income',
    questionText: 'What is your gross annual income?',
    inputType: InputType.currency,
  ),
  MortgageQuestion(
    id: 'existing_loans',
    questionText: 'Do you have any existing loans or financial obligations?',
    inputType: InputType.yesNoWithDetail,
    detailHint: 'Please describe your existing obligations',
  ),
  MortgageQuestion(
    id: 'credit_score',
    questionText: 'What is your estimated credit score range?',
    inputType: InputType.picklist,
    options: ['Excellent 750+', 'Good 700–749', 'Fair 650–699', 'Below 650'],
  ),
  MortgageQuestion(
    id: 'co_applicant',
    questionText: 'Do you have a co-applicant?',
    inputType: InputType.yesNo,
  ),
  MortgageQuestion(
    id: 'property_identified',
    questionText: 'Have you already identified a property?',
    inputType: InputType.yesNoWithDetail,
    detailHint: 'Enter the property address',
  ),
];
