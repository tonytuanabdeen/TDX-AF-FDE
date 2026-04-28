class AgentSession {
  AgentSession({
    required this.sessionId,
    required this.sessionKey,
    this.welcomeMessage,
  });

  final String sessionId;
  final String sessionKey;
  String? welcomeMessage;

  factory AgentSession.fromJson(Map<String, dynamic> json) {
    return AgentSession(
      sessionId: json['sessionId'] as String,
      sessionKey: json['sessionKey'] as String? ?? '',
    );
  }
}
