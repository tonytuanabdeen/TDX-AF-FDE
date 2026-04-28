import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/salesforce_contact_id_provider.dart';
import '../providers/chat_provider.dart';
import '../../../theme/app_theme.dart';

class MortgageChatScreen extends ConsumerStatefulWidget {
  const MortgageChatScreen({super.key});

  @override
  ConsumerState<MortgageChatScreen> createState() =>
      _MortgageChatScreenState();
}

class _MortgageChatScreenState extends ConsumerState<MortgageChatScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late ChatNotifier _chatNotifier;

  // Tracks async session init so we can show loading / error states
  late Future<void> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _chatNotifier = ref.read(chatProvider.notifier);
    _sessionFuture = _initSession();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      _chatNotifier.endSession();
    }
  }

  Future<void> _initSession() async {
    final contactId =
        await ref.read(salesforceContactIdProvider.future);
    if (!mounted) return;
    if (contactId == null || contactId.isEmpty) return; // no-contact state handled in build
    await ref.read(chatProvider.notifier).initSession(contactId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatNotifier.endSession();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isSending = ref.watch(chatIsSendingProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            ref.read(chatProvider.notifier).endSession();
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.brandRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'F',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat with FrED',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  'AI Agent · Powered by Agentforce',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.secondaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          // No contact ID
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            final contactId = ref.watch(salesforceContactIdProvider).valueOrNull;
            if (contactId == null || contactId.isEmpty) {
              return _NoContactView();
            }
          }

          // Session init failed
          if (snapshot.hasError) {
            return _ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() {
                _sessionFuture = _initSession();
              }),
            );
          }

          // Loading session
          if (snapshot.connectionState != ConnectionState.done) {
            return const _InitializingView();
          }

          // Chat UI
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _Bubble(message: messages[index], isDark: isDark),
                ),
              ),
              _InputBar(
                controller: _controller,
                isDark: isDark,
                isSending: isSending,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── State views ──────────────────────────────────────────────────────────────

class _InitializingView extends StatelessWidget {
  const _InitializingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
              color: AppTheme.brandRed, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(
            'Connecting to FrED…',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppTheme.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: Colors.red, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not connect to agent',
              style: GoogleFonts.dmSans(
                  fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.secondaryLabel),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoContactView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.brandRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_off_rounded,
                  color: AppTheme.brandRed, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile not linked',
              style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Please link your account in Profile before chatting with FrED.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppTheme.secondaryLabel),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Go to Profile',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bubble ───────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isDark});

  final ChatMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.brandRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'F',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.brandRed
                    : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: message.isLoading
                  ? const _AnimatedDots()
                  : Text(
                      message.text,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.4,
                        color: isUser
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Animated typing dots ─────────────────────────────────────────────────────

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot peaks at a different phase
            final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4.0 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryLabel,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isDark;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final barBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final sep = isDark ? AppTheme.darkSeparator : AppTheme.lightSeparator;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(top: BorderSide(color: sep, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.dmSans(fontSize: 15),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => isSending ? null : onSend(),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: GoogleFonts.dmSans(
                        fontSize: 15, color: AppTheme.secondaryLabel),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor:
                        isDark ? AppTheme.darkBg : AppTheme.lightBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: isSending
                    ? AppTheme.secondaryLabel.withValues(alpha: 0.3)
                    : AppTheme.brandRed,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isSending ? null : onSend,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
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
