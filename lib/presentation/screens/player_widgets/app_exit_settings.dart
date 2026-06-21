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
          title: const Text('Are You sure?', style: TextStyle(color: Colors.white)),
          content: const Text('You went to exit app?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('NO', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('YES', style: TextStyle(color: AppTheme.primary)),
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
/// ২. প্লেয়ার সেটিংস ডায়লগ উইজেট (Fixed Layout)
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
  late int _totalItems;

  @override
  void initState() {
    super.initState();
    _totalItems = 4 + (widget.state.isAuthenticated ? 1 : 0);
    for (int i = 0; i < _totalItems; i++) {
      _focusNodes.add(FocusNode(debugLabel: 'settings-item-$i'));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _focusNodes) n.dispose();
    super.dispose();
  }

  Widget _focusableItem({
    required int index,
    required Widget child,
    required VoidCallback onActivate,
  }) {
    final isFocused = _focusedIndex == index;
    return Focus(
      focusNode: _focusNodes[index],
      onFocusChange: (v) { if (v) setState(() => _focusedIndex = index); },
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.select)) {
          onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: onActivate,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isFocused ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isFocused ? AppTheme.primary : Colors.transparent, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int index = 0;
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.primary, width: 1.5)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Text('প্লেয়ার সেটিংস', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: Colors.white24, height: 25),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _focusableItem(
                        index: index++,
                        onActivate: () => widget.state.togglePlayerBoot(),
                        child: SwitchListTile(
                          title: const Text('Boot Player', style: TextStyle(color: Colors.white)),
                          value: widget.state.isPlayerBootEnabled,
                          onChanged: (_) => widget.state.togglePlayerBoot(),
                        ),
                      ),
                      if (widget.state.isAuthenticated)
                        _focusableItem(
                          index: index++,
                          onActivate: () {},
                          child: ListTile(
                            leading: const Icon(Icons.stars_rounded, color: Color(0xFFEAB308)),
                            title: Text(widget.state.userProfile?.email ?? '', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('প্যাকেজ: ${widget.state.userProfile?.plan ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ),
                        ),
                      _focusableItem(
                        index: index++,
                        onActivate: widget.onAppInfo,
                        child: const ListTile(
                          leading: Icon(Icons.info_outline_rounded, color: Colors.white70),
                          title: Text('অ্যাপ তথ্য', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _focusableItem(index: index++, onActivate: widget.onNavigateSettings, child: const Padding(padding: EdgeInsets.all(12), child: Text('সেটিংস', style: TextStyle(color: Colors.white)))),
                  const SizedBox(width: 10),
                  _focusableItem(index: index++, onActivate: widget.onClose, child: Padding(padding: const EdgeInsets.all(12), child: Text('বন্ধ', style: TextStyle(color: AppTheme.primary)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}