import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// ১. গ্লোবাল অ্যাপ এক্সিট হ্যান্ডলার মেকানিজম
/// ───────────────────────────────────────────────────────────────────────────
class AppExitHandler {
  static Future<void> handleExit({
    required BuildContext context,
    required AppState appState,
    required VoidCallback onBeforeDispose,
  }) async {
    final shouldFullExit = appState.isPlayerBootEnabled;

    if (shouldFullExit) {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          title: const Text(
            'অ্যাপ এক্সিট করবেন?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'সম্পূর্ণ অ্যাপ বন্ধ করতে চান?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('না', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('হ্যাঁ', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        onBeforeDispose();
        try { await WakelockPlus.disable(); } catch (_) {}
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        exit(0);
      }
    } else {
      onBeforeDispose();
      try { await WakelockPlus.disable(); } catch (_) {}
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}

/// ───────────────────────────────────────────────────────────────────────────
/// ২. প্লেয়ার সেটিংস ডায়লগ উইজেট (Android TV Remote Optimized)
/// ───────────────────────────────────────────────────────────────────────────
class PlayerSettingsDialog extends StatefulWidget {
  const PlayerSettingsDialog({
    super.key,
    required this.state,
    required this.onAppInfo,
    required this.onNavigateSettings,
    required this.onClose,
  });

  final AppState state;
  final VoidCallback onAppInfo;
  final VoidCallback onNavigateSettings;
  final VoidCallback onClose;

  @override
  State<PlayerSettingsDialog> createState() => _PlayerSettingsDialogState();
}

class _PlayerSettingsDialogState extends State<PlayerSettingsDialog> {
  final List<FocusNode> _focusNodes = [];
  int _focusedIndex = 0;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    
    _totalItems = widget.state.isAuthenticated ? 4 : 3; 
    _totalItems += 1; // সেটিংস অ্যাকশন বাটনের জন্য

    for (int i = 0; i < _totalItems; i++) {
      _focusNodes.add(FocusNode(debugLabel: 'settings-item-$i'));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final n in _focusNodes) n.dispose();
    super.dispose();
  }

  void _moveFocus(int dir) {
    if (_focusNodes.isEmpty) return;
    final next = (_focusedIndex + dir).clamp(0, _focusNodes.length - 1);
    setState(() => _focusedIndex = next);
    _focusNodes[next].requestFocus();
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _focusableItem({
    required int listIndex,
    required Widget child,
    required VoidCallback onActivate,
  }) {
    final isFocused = _focusedIndex == listIndex;
    return Focus(
      focusNode: _focusNodes[listIndex],
      onFocusChange: (v) {
        if (v) setState(() => _focusedIndex = listIndex);
      },
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            (e.logicalKey == LogicalKeyboardKey.enter ||
                e.logicalKey == LogicalKeyboardKey.select)) {
          onActivate();
          return KeyEventResult.handled;
        }
        return _onKey(e);
      },
      child: GestureDetector(
        onTap: onActivate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isFocused ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused ? AppTheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    int currentVisualIndex = 0; 

    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.white),
          Spacer(),
          Text('প্লেয়ার সেটিংস', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _focusableItem(
            listIndex: currentVisualIndex++,
            onActivate: () => state.togglePlayerBoot(),
            child: SwitchListTile(
              title: const Text('Boot Player (অটো প্লেয়ার)', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'অ্যাপ চালু হলে সরাসরি লাইভ টিভি ওপেন হবে',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
              ),
              activeColor: AppTheme.primary,
              value: state.isPlayerBootEnabled,
              onChanged: (v) => state.togglePlayerBoot(),
            ),
          ),

          if (state.isAuthenticated)
            _focusableItem(
              listIndex: currentVisualIndex++,
              onActivate: () {},
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ListTile(
                  leading: const Icon(Icons.stars_rounded, color: Color(0xFFEAB308)),
                  title: Text(
                    state.userProfile?.email ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'প্যাকেজ: ${state.userProfile?.plan ?? ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            ),

          const Divider(color: Colors.white12, height: 20),

          _focusableItem(
            listIndex: currentVisualIndex++,
            onActivate: widget.onAppInfo,
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppTheme.primary),
              title: const Text('অ্যাপ তথ্য (App Info)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('ভার্সন ও ডেভেলপার তথ্য',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            ),
          ),
        ],
      ),
      actions: [
        _focusableItem(
          listIndex: currentVisualIndex++,
          onActivate: widget.onNavigateSettings,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'সেটিংস', 
              style: TextStyle(color: _focusedIndex == (currentVisualIndex - 1) ? Colors.white : Colors.white54),
            ),
          ),
        ),
        TextButton(
          onPressed: widget.onClose,
          child: Text('বন্ধ', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}
