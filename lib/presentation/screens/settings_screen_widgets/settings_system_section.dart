// lib/presentation/screens/settings_screen_widgets/settings_system_section.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'settings_shared_widgets.dart';

/// System section focus order:
///   card1 (Catalog) → card2 (Update) → card3 (Developer) → card4 (App Info) [last]
class SettingsSystemSection extends StatelessWidget {
  const SettingsSystemSection({
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

  void _refreshCatalog(BuildContext context) {
    appState.loadCatalog();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Channel list is updating...'),
      backgroundColor: AppTheme.card,
      duration: const Duration(seconds: 2),
    ));
  }

  void _checkForUpdates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Checking for new updates...'),
      backgroundColor: AppTheme.card,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'SYSTEM'),
        const SizedBox(height: 16),

        // Row 1: card1, card2
        SettingsTwoColRow(
          children: [
            SettingCard(
              focusNode: firstFocusNode,   // ← first
              onNavigateLeft: onNavigateLeft,
              icon: Icons.sync_rounded,
              title: 'Catalog Refresh',
              subtitle: 'Update channel list',
              onTap: () => _refreshCatalog(context),
            ),
            SettingCard(
              onNavigateLeft: onNavigateLeft,
              icon: Icons.system_update_rounded,
              title: 'App Update',
              subtitle: 'Check for new version',
              onTap: () => _checkForUpdates(context),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Row 2: card3, card4 (card4 = last)
        SettingsTwoColRow(
          children: [
            SettingCard(
              onNavigateLeft: onNavigateLeft,
              icon: Icons.code_rounded,
              title: 'Developer',
              subtitle: 'App development & support',
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => const _DeveloperDialog()),
            ),
            SettingCard(
              focusNode: lastFocusNode,    // ← last
              isLastItem: true,
              onLastItemDown: onLastItemDown,
              onNavigateLeft: onNavigateLeft,
              icon: Icons.info_outline_rounded,
              title: 'App Information',
              subtitle: 'Version and system information',
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => const _AppInfoDialog()),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeveloperDialog extends StatelessWidget {
  const _DeveloperDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      title: const Row(children: [
        Icon(Icons.person_rounded, color: AppTheme.primary),
        SizedBox(width: 10),
        Text('Developer Information', style: TextStyle(color: Colors.white)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Main Developer and Project Architect:',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 6),
          Text('Anirban Sumon',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          const Text('Full Stack Developer (IPTV & Mobile Systems)',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          autofocus: true,
          style: TextButton.styleFrom(foregroundColor: AppTheme.primary)
              .copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (s) => s.contains(WidgetState.focused)
                  ? AppTheme.primary.withOpacity(0.15)
                  : null,
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('বন্ধ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _AppInfoDialog extends StatelessWidget {
  const _AppInfoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      title: const Row(children: [
        Icon(Icons.info_rounded, color: AppTheme.primary),
        SizedBox(width: 10),
        Text('App Information', style: TextStyle(color: Colors.white)),
      ]),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Live TV Player',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Version 1.0.0',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 4),
          Text('All rights reserved.',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
      actions: [
        TextButton(
          autofocus: true,
          style: TextButton.styleFrom(foregroundColor: AppTheme.primary)
              .copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (s) => s.contains(WidgetState.focused)
                  ? AppTheme.primary.withOpacity(0.15)
                  : null,
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child:
                Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
