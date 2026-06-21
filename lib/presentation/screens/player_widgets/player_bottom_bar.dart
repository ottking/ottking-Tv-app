// lib/presentation/screens/player_widgets/player_bottom_bar.dart


import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerBottomBar extends StatelessWidget {
  const PlayerBottomBar({
    super.key,
    required this.ctrl,
    required this.isLive,
    required this.liveBlink,
  });

  final VideoPlayerController ctrl;
  final bool isLive;
  final bool liveBlink;

  @override
  Widget build(BuildContext context) {
    final bool showLive = isLive && ctrl.value.isPlaying;
    if (!showLive) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // ===== LIVE ব্লিংকিং ব্যাজ =====
            AnimatedOpacity(
              opacity: liveBlink ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
