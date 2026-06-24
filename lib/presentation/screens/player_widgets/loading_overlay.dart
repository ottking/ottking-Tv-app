// lib/presentation/screens/player_widgets/loading_overlay.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Non-interactive overlay — keeps focus on the player so remote keys still work.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.hasError,
    required this.isLoading,
    required this.channelName,
  });

  final bool hasError;
  final bool isLoading;
  final String channelName;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasError) ...[
                const Icon(
                  Icons.signal_wifi_statusbar_connected_no_internet_4,
                  color: Colors.white38,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  '$channelName — Offline',
                  style: const TextStyle(color: Colors.white60, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Use ↑ ↓ or CH+/CH− to change channel',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ] else if (isLoading) ...[
                const CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading $channelName...',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
