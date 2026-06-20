// lib/presentation/screens/settings_screen_widgets/settings_tv_section.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'settings_shared_widgets.dart';

class SettingsTvSection extends StatelessWidget {
  const SettingsTvSection({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    // প্লেয়ার স্ক্রিনের মেথড ও স্টেট নেমিং কনভেনশনের সাথে ১০০% সিঙ্ক করা হলো
    final isBootEnabled = appState.isPlayerBootEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'TV সেটিংস'),
        const SizedBox(height: 16),

        SettingsTwoColRow(
          children: [
            // ── Boot Player toggle ─────────────────────────────────────────
            SettingCard(
              icon: Icons.rocket_launch_rounded,
              title: 'Boot Player (অটো প্লেয়ার)',
              subtitle: isBootEnabled
                  ? 'চালু — অ্যাপ খুললেই লাইভ টিভি শুরু হবে'
                  : 'বন্ধ — হোম পেজে যাবে',
              highlight: isBootEnabled,
              // টিভি রিমোটের ফোকাস যেন কনফ্লিক্ট না করে, তাই সুইচের onChanged ডিরেক্ট কার্ডের টগলে পাস করা হলো
              trailing: Switch(
                value: isBootEnabled,
                activeColor: AppTheme.primary,
                onChanged: null, // null রাখলে ফোকাস সরাসরি মাদার 'SettingCard' রিসিভ করবে, যা টিভির জন্য আইডিয়াল
              ),
              onTap: () => appState.togglePlayerBoot(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Right panel hint ───────────────────────────────────────────────
        _BootHintCard(enabled: isBootEnabled),
      ],
    );
  }
}

class _BootHintCard extends StatelessWidget {
  const _BootHintCard({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled
            ? AppTheme.primary.withOpacity(0.08)
            : const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppTheme.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: enabled ? AppTheme.primary : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'বর্তমানে: TV সেটিংস',
                  style: TextStyle(
                    color: enabled ? AppTheme.primary : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enabled
                      ? 'Boot Player চালু আছে। অ্যাপ রান হওয়ার সাথে সাথে সরাসরি লাইভ টিভি প্লেয়ার ওপেন হবে।'
                      : 'Boot Player বন্ধ আছে। অ্যাপ রান হওয়ার পর প্রথমে স্ট্যান্ডার্ড হোম পেজ ওপেন হবে।',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
