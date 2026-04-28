import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/contact_model.dart';
import '../providers/contact_provider.dart';
import '../../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Listen after first frame so ScaffoldMessenger is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(contactProvider, _onContactChanged);
    });
  }

  void _onContactChanged(
    AsyncValue<ContactModel?>? previous,
    AsyncValue<ContactModel?> next,
  ) {
    // Only react to transitions from loading → data/error (ignore first null)
    if (previous == null || previous is AsyncLoading) {
      if (next is AsyncData<ContactModel?>) {
        final contact = next.value;
        if (contact != null) {
          _toast(
            message: '${contact.fullName} loaded successfully',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          );
        }
      } else if (next is AsyncError) {
        _toast(
          message: _friendlyError(next.error ?? 'Unknown error'),
          icon: Icons.error_rounded,
          color: Colors.red,
        );
      }
    }
  }

  String _friendlyError(Object error) {
    final s = error.toString();
    if (s.contains('SalesforceAuthException')) {
      return s.replaceFirst('SalesforceAuthException: ', '');
    }
    if (s.contains('ContactNotFoundException')) {
      return 'Contact not found in Salesforce';
    }
    if (s.contains('SocketException') || s.contains('HandshakeException')) {
      return 'Cannot reach Salesforce — check your connection';
    }
    return 'Failed to load profile';
  }

  void _toast({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final contactAsync = ref.watch(contactProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text('Profile',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.invalidate(contactProvider);
              // Re-attach listener after invalidation triggers a new load
              ref.listenManual(contactProvider, _onContactChanged);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: contactAsync.when(
        loading: () => const _LoadingBody(),
        error: (e, _) => _ErrorBody(
          error: e,
          onRetry: () {
            ref.invalidate(contactProvider);
            ref.listenManual(contactProvider, _onContactChanged);
          },
        ),
        data: (contact) => contact == null
            ? const _NoContactBody()
            : _ContactBody(contact: contact),
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.brandRed,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile…',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppTheme.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

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
              'Could not load profile',
              style:
                  GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w600),
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

// ─── No Contact ID ────────────────────────────────────────────────────────────

class _NoContactBody extends StatelessWidget {
  const _NoContactBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 28),
          CircleAvatar(
            radius: 42,
            backgroundColor: AppTheme.brandRed.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.brandRed, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            'No profile linked',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact your advisor to link your account',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppTheme.secondaryLabel),
          ),
          const SizedBox(height: 32),
          _SettingsSections(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Contact loaded ───────────────────────────────────────────────────────────

class _ContactBody extends StatelessWidget {
  const _ContactBody({required this.contact});

  final ContactModel contact;

  String get _initials {
    final parts = contact.fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return contact.fullName.isNotEmpty
        ? contact.fullName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 28),
          CircleAvatar(
            radius: 42,
            backgroundColor: AppTheme.brandRed,
            child: Text(
              _initials,
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            contact.fullName,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (contact.email != null) ...[
            const SizedBox(height: 4),
            Text(
              contact.email!,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppTheme.secondaryLabel),
            ),
          ],
          const SizedBox(height: 32),
          _Section(
            label: 'CONTACT DETAILS',
            children: [
              if (contact.phone != null)
                _InfoRow(
                  iconBg: Colors.green,
                  icon: Icons.phone_rounded,
                  title: 'Phone',
                  value: contact.phone!,
                  showDivider: contact.email != null,
                ),
              if (contact.email != null)
                _InfoRow(
                  iconBg: Colors.blue,
                  icon: Icons.email_rounded,
                  title: 'Email',
                  value: contact.email!,
                  showDivider: false,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsSections(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Shared settings rows ─────────────────────────────────────────────────────

class _SettingsSections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Section(
          label: 'PREFERENCES',
          children: [
            _SettingsRow(
              iconBg: Colors.blue,
              icon: Icons.lock_rounded,
              title: 'Security',
              onTap: () {},
            ),
            _SettingsRow(
              iconBg: Colors.red,
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              onTap: () {},
            ),
            _SettingsRow(
              iconBg: Colors.green,
              icon: Icons.help_rounded,
              title: 'Help & Support',
              onTap: () {},
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          children: [
            _SettingsRow(
              iconBg: Colors.grey,
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              titleColor: Colors.red,
              onTap: () {},
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({this.label, required this.children});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppTheme.secondaryLabel,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.value,
    required this.showDivider,
  });

  final Color iconBg;
  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppTheme.secondaryLabel),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 58,
            color: isDark ? AppTheme.darkSeparator : AppTheme.lightSeparator,
          ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.showDivider = true,
  });

  final Color iconBg;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          borderRadius: showDivider
              ? BorderRadius.zero
              : const BorderRadius.vertical(bottom: Radius.circular(16)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: titleColor ?? scheme.onSurface,
                    ),
                  ),
                ),
                if (titleColor == null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.secondaryLabel,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 58,
            color: isDark ? AppTheme.darkSeparator : AppTheme.lightSeparator,
          ),
      ],
    );
  }
}
