// lib/presentation/screens/player_widgets/loading_overlay.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.hasError,
    required this.retryCount,
    required this.maxRetry,
    required this.channelName,
    required this.onRetry,
    required this.onNext,
  });

  final bool hasError;
  final int retryCount;
  final int maxRetry;
  final String channelName;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError) ...[
              const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4,
                  color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              Text(
                '$channelName is Offline',
                style: const TextStyle(
                    color: Colors.white60, fontSize: 18),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Retry',
                    onTap: onRetry,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _OverlayBtn(
                    icon: Icons.skip_next_rounded,
                    label: 'Next Channels',
                    onTap: onNext,
                    color: Colors.white24,
                  ),
                ],
              ),
            ] else ...[
              CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 3),
              const SizedBox(height: 16),
              if (retryCount > 0)
                Text(
                  'Retring... ($retryCount/$maxRetry)',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 14),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  const _OverlayBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withOpacity(0.4))),
      ),
      icon: Icon(icon),
      label: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }
}
