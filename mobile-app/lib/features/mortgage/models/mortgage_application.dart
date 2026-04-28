class MortgageApplication {
  const MortgageApplication({
    required this.id,
    required this.answers,
    required this.submittedAt,
  });

  final String id;
  final Map<String, String> answers;
  final DateTime submittedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'answers': answers,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory MortgageApplication.fromJson(Map<String, dynamic> json) =>
      MortgageApplication(
        id: json['id'] as String,
        answers: Map<String, String>.from(json['answers'] as Map),
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );
}
