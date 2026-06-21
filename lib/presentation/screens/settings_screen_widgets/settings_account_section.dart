// lib/presentation/screens/settings_screen_widgets/settings_account_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'settings_shared_widgets.dart';
import 'auth_dialog.dart';
import 'subscription_dialog.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key, required this.appState, this.firstFocusNode});
  final AppState appState;
  // সাইডবার থেকে → চাপলে সরাসরি এই সেকশনের প্রথম কার্ডে ফোকাস আনার জন্য
  final FocusNode? firstFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Accounts'),
        const SizedBox(height: 16),

        // ── ১. লগইন থাকলে প্রোফাইল কার্ড (সাইজ ছোট ও কম্প্যাক্ট করা হয়েছে) ──
        if (appState.isAuthenticated && appState.userProfile != null) ...[
          AccountCard(profile: appState.userProfile!),
          const SizedBox(height: 16),
        ],

        // ── ২. অ্যাকশন কার্ড জোন: লগইন এবং সাবস্ক্রিপশন ───────────────────────
        SettingsTwoColRow(
          children: [
            SettingCard(
              icon: appState.isAuthenticated
                  ? Icons.manage_accounts_rounded
                  : Icons.login_rounded,
              title: appState.isAuthenticated ? 'Manage Account' : 'Login',
              subtitle: appState.isAuthenticated
                  ? appState.userProfile?.email ?? ''
                  : 'Log in with a subscribed account to watch premium channels.',
              highlight: appState.isAuthenticated,
              focusNode: firstFocusNode,
              onTap: () => showDialog(
                context: context,
                barrierDismissible: false, // রিমোট ইউজারদের জন্য নিরাপদ পপ-আপ কন্ট্রোল
                builder: (_) => const AuthDialog(),
              ),
            ),
            SettingCard(
              icon: Icons.card_membership_rounded,
              title: 'Subscription',
              subtitle: appState.isAuthenticated
                  ? 'Plan: ${appState.userProfile?.plan ?? "–"}'
                  : 'Packages & Pricing',
              onTap: () => showDialog(
                context: context,
                builder: (_) => SubscriptionDialog(plans: appState.plans),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),


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
            child: Text(
              text,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ৪. কম্প্যাক্ট অ্যাকাউন্ট প্রোফাইল কার্ড (টিভি রিমোট অপ্টিমাইজড) ──────────────────

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.profile});
  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>(); 
    
    return Container(
      // প্যাডিং কমিয়ে কার্ডটি অনেক ছোট এবং প্রফেশনাল করা হয়েছে
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
          // ছোট সাইজের প্রোফাইল অবতার
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            child: Text(
              profile.email.isNotEmpty ? profile.email[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFEAB308),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Plan: ${profile.plan}',
                      style: const TextStyle(
                        color: Color(0xFFEAB308),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // টিভি রিমোটের জন্য ফোকাস-অ্যাওয়ার লগআউট বাটন
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(
              // রিমোট দিয়ে বাটনে আসলে ব্যাকগ্রাউন্ড লালচে হাইলাইট হবে
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.focused)) {
                    return Colors.red.withOpacity(0.15);
                  }
                  return null;
                },
              ),
            ),
            onPressed: () {
              // সেটিংস স্ক্রিন পপ না করে শুধুমাত্র স্টেট লগআউট করা হলো
              appState.logout();
            },
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
