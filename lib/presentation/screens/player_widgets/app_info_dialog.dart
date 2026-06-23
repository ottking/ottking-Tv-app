// lib/presentation/screens/player_widgets/app_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class AppInfoDialog extends StatefulWidget {
  const AppInfoDialog({super.key});

  @override
  State<AppInfoDialog> createState() => _AppInfoDialogState();
}

class _AppInfoDialogState extends State<AppInfoDialog> {
  final FocusNode _closeFocusNode = FocusNode(debugLabel: 'dialog-close-btn');
  bool _isCloseFocused = false;

  @override
  void initState() {
    super.initState();
    // ডায়ালগ ওপেন হওয়ার সাথে সাথে বন্ধ বোতামে রিমোট ফোকাস সেট হবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _closeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.info_rounded, color: AppTheme.primary),
          SizedBox(width: 10),
          Text(
            'App Info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 320, // টিভির জন্য একটি স্ট্যান্ডার্ড চওড়া সাইজ
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== ১. অ্যাপ নাম ও ভার্সন কার্ড =====
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'LTV Player', // App Name
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0', // App Version
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ===== ২. ডেভেলপার ও কোম্পানি তথ্য কার্ড =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // কোম্পানি তথ্য
                  const Text(
                    'Company:',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ltv digital Limited',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Colors.white10, height: 1),
                  ),

                  // ডেভেলপার তথ্য
                  const Text(
                    'Developer:',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Anirban Sumon',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== ৩. Powered By সেকশন =====
            Center(
              child: Text(
                'Powered by OTTKING',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
      actions: [
        // ===== ৪. ফোকাসযোগ্য বন্ধ (Close) বোতাম =====
        Focus(
          focusNode: _closeFocusNode,
          onFocusChange: (hasFocus) {
            setState(() {
              _isCloseFocused = hasFocus;
            });
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.space)) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                // রিমোট দিয়ে সিলেক্ট করলেই কেবল ব্যাকগ্রাউন্ড কালার ও বর্ডার আসবে
                color: _isCloseFocused
                    ? AppTheme.primary.withOpacity(0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isCloseFocused ? AppTheme.primary : Colors.white24,
                  width: _isCloseFocused ? 2 : 1,
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  color: _isCloseFocused ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
