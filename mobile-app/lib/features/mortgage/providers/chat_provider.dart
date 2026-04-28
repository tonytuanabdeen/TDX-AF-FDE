import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/salesforce_contact_id_provider.dart';
import '../../profile/providers/contact_provider.dart';
import '../models/agent_session.dart';
import '../models/chat_message.dart';
import '../services/agent_service.dart';

export '../models/chat_message.dart';
export '../models/agent_session.dart';

// ─── Service provider ─────────────────────────────────────────────────────────

final agentServiceProvider = Provider<AgentService>((ref) {
  return AgentService(ref.watch(salesforceAuthServiceProvider));
});

// ─── Active session ───────────────────────────────────────────────────────────

final agentSessionProvider = StateProvider<AgentSession?>((ref) => null);

// ─── Chat messages ────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this._ref) : super([]);

  final Ref _ref;
  static const _loadingId = '__loading__';
  bool _isSending = false;

  bool get isSending => _isSending;

  Future<void> initSession(String contactId) async {
    final service = _ref.read(agentServiceProvider);
    try {
      final session = await service.createSession(contactId);
      _ref.read(agentSessionProvider.notifier).state = session;

      final greetingText = (session.welcomeMessage != null && session.welcomeMessage!.isNotEmpty)
          ? session.welcomeMessage!
          : "Hi, I'm FrED, FDE Bank's AI agent. How can I help you today?";
      state = [
        ChatMessage(
          id: 'greeting',
          text: greetingText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    } on Exception {
      rethrow; // surfaced by the screen's FutureBuilder
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    final session = _ref.read(agentSessionProvider);
    if (session == null) return;

    _isSending = true;

    // Append user message + loading bubble
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    final loadingBubble = ChatMessage(
      id: _loadingId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [...state, userMsg, loadingBubble];

    try {
      final service = _ref.read(agentServiceProvider);
      final reply = await service.sendMessage(session.sessionId, text.trim());

      _replaceBubble(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_reply',
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } on Exception catch (e) {
      // Session might have expired — try once to re-create it
      if (e.toString().contains('401') || e.toString().contains('expired')) {
        final recovered = await _tryRecreateSession();
        if (recovered) {
          try {
            final newSession = _ref.read(agentSessionProvider)!;
            final service = _ref.read(agentServiceProvider);
            final reply = await service.sendMessage(newSession.sessionId, text.trim());
            _replaceBubble(ChatMessage(
              id: '${DateTime.now().millisecondsSinceEpoch}_reply',
              text: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isSending = false;
            return;
          } catch (_) {}
        }
      }
      _replaceBubble(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_err',
        text: 'Sorry, something went wrong. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isSending = false;
    }
  }

  Future<bool> _tryRecreateSession() async {
    try {
      final contactIdAsync = _ref.read(salesforceContactIdProvider);
      final contactId = contactIdAsync.valueOrNull;
      if (contactId == null) return false;
      final service = _ref.read(agentServiceProvider);
      final newSession = await service.createSession(contactId);
      _ref.read(agentSessionProvider.notifier).state = newSession;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> endSession() async {
    final session = _ref.read(agentSessionProvider);
    if (session == null) return;
    final service = _ref.read(agentServiceProvider);
    await service.endSession(session.sessionId);
    if (!mounted) return;
    _ref.read(agentSessionProvider.notifier).state = null;
    state = [];
  }

  void _replaceBubble(ChatMessage replacement) {
    state = [
      for (final m in state)
        if (m.id == _loadingId) replacement else m,
    ];
  }
}

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(ref),
);

// Exposes whether a reply is in-flight so the input bar can disable the send button
final chatIsSendingProvider = Provider.autoDispose<bool>((ref) {
  final notifier = ref.watch(chatProvider.notifier);
  ref.watch(chatProvider); // rebuild when messages change
  return notifier.isSending;
});
