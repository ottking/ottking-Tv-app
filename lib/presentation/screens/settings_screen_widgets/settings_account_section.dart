// lib/presentation/screens/settings_screen_widgets/settings_account_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/tv_focus.dart';
import 'settings_shared_widgets.dart';
import 'auth_dialog.dart';
import 'subscription_dialog.dart';

/// Account section focus order:
///   card1 (Sign In / Manage) → card2 (Subscription) → logout btn [if logged in]
///
/// last item:
///   - লগইন থাকলে → logout btn (lastFocusNode)
///   - লগইন না থাকলে → card2 (lastFocusNode)
class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.appState,
    this.firstFocusNode,
    this.lastFocusNode,
    this.onNavigateLeft,
    this.onLastItemDown,
  });

  final AppState appState;
  final FocusNode? firstFocusNode;
  final FocusNode? lastFocusNode;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onLastItemDown;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn =
        appState.isAuthenticated && appState.userProfile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'ACCOUNTS'),
        const SizedBox(height: 16),

        if (isLoggedIn) ...[
          AccountCard(
            profile: appState.userProfile!,
            // logout btn হলো last item যখন logged in
            logoutFocusNode: lastFocusNode,
            onLastItemDown: onLastItemDown,
            onNavigateLeft: onNavigateLeft,
          ),
          const SizedBox(height: 16),
        ],

        SettingsTwoColRow(
          children: [
            // card1 → always first
            SettingCard(
              focusNode: firstFocusNode,
              onNavigateLeft: onNavigateLeft,
              icon: isLoggedIn
                  ? Icons.manage_accounts_rounded
                  : Icons.login_rounded,
              title: isLoggedIn ? 'Account Management' : 'Sign In',
              subtitle: isLoggedIn
                  ? appState.userProfile?.email ?? ''
                  : 'Sign in to access premium channels',
              highlight: isLoggedIn,
              // logged out এর সময় card2 নেই তাই card1 = last? No, card2 সবসময় আছে
              onTap: () {
                if (isLoggedIn) {
                  showDialog(
                    context: context,
                    builder: (_) => AccountInfoDialog(
                      profile: appState.userProfile!,
                      onLogout: () {
                        appState.logout();
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AuthDialog(),
                  );
                }
              },
            ),

            // card2 → last item যখন NOT logged in
            SettingCard(
              focusNode: isLoggedIn ? null : lastFocusNode,
              isLastItem: !isLoggedIn,
              onLastItemDown: isLoggedIn ? null : onLastItemDown,
              onNavigateLeft: onNavigateLeft,
              icon: Icons.card_membership_rounded,
              title: 'SUBSCRIPTION',
              subtitle: isLoggedIn
                  ? 'Plan: ${appState.userProfile?.plan ?? "–"}'
                  : 'View packages and prices',
              onTap: () => showDialog(
                context: context,
                builder: (_) =>
                    SubscriptionDialog(plans: appState.plans),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const _SectionHint(
          icon: Icons.info_outline_rounded,
          text: 'Current: Account Settings — Manage login and subscription.',
        ),
      ],
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Account Card (logout button = last focusable item when logged in) ─────────
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.profile,
    this.logoutFocusNode,
    this.onLastItemDown,
    this.onNavigateLeft,
  });
  final dynamic profile;
  final FocusNode? logoutFocusNode;
  final VoidCallback? onLastItemDown;
  final VoidCallback? onNavigateLeft;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.card, const Color(0xFF131B2E).withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            child: Text(
              profile.email.isNotEmpty ? profile.email[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.email,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.stars_rounded,
                      color: Color(0xFFEAB308), size: 12),
                  const SizedBox(width: 4),
                  Text('Plan: ${profile.plan}',
                      style: const TextStyle(
                          color: Color(0xFFEAB308),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),

          // Logout button — last focusable item (logged in state)
          TvFocus(
            focusNode: logoutFocusNode,
            onActivate: () => appState.logout(),
            // ↓ Down চাপলে sidebar এ wrap, ← Left চাপলে sidebar এ ফেরত
            onKeyEvent: (event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                onLastItemDown?.call();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                onNavigateLeft?.call();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            builder: (context, focused) => TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.focused)
                      ? Colors.red.withOpacity(0.15)
                      : null,
                ),
              ),
              onPressed: () => appState.logout(),
              icon: const Icon(Icons.logout_rounded, size: 14),
              label: const Text('Logout',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountInfoDialog extends StatelessWidget {
  const AccountInfoDialog(
      {super.key, required this.profile, required this.onLogout});
  final dynamic profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131B2E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Account Information',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccountInfoRow(label: 'Email', value: profile.email),
            const SizedBox(height: 12),
            _AccountInfoRow(label: 'Plan', value: profile.plan),
            const SizedBox(height: 12),
            const _AccountInfoRow(label: 'Status', value: 'Logged in'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        TvFocus(
          onActivate: onLogout,
          builder: (context, focused) => FilledButton(
            onPressed: onLogout,
            style: FilledButton.styleFrom(
              backgroundColor:
                  focused ? Colors.redAccent : AppTheme.primary,
            ),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text('$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
