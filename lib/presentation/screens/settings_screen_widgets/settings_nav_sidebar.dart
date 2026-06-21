// lib/presentation/screens/settings_screen_widgets/settings_nav_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class SettingsNavSidebar extends StatefulWidget {
  const SettingsNavSidebar({
    super.key,
    required this.activeSection,
    required this.onSelect,
    required this.onBack,
    required this.navNodes,
    this.onMoveRight,
  });

  final int activeSection;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;
  final List<FocusNode> navNodes;
  final VoidCallback? onMoveRight;

  @override
  State<SettingsNavSidebar> createState() => _SettingsNavSidebarState();
}

class _SettingsNavSidebarState extends State<SettingsNavSidebar> {
  final FocusNode _backNode = FocusNode(debugLabel: 'settings-back-btn');

  static const _items = [
    _NavMeta(icon: Icons.account_circle_rounded, label: 'Accounts', hint: 'Login/Subscriptions'),
    _NavMeta(icon: Icons.tv_rounded, label: 'TV Settings', hint: 'Boot Player & More'),
    _NavMeta(icon: Icons.settings_applications_rounded, label: 'Systems', hint: 'Update & more'),
  ];

  @override
  void dispose() {
    _backNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _BackButton(
                    focusNode: _backNode,
                    onTap: widget.onBack,
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        widget.navNodes[0].requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              return _NavItem(
                focusNode: widget.navNodes[i],
                icon: item.icon,
                label: item.label,
                hint: item.hint,
                isActive: widget.activeSection == i,
                onTap: () => widget.onSelect(i),
                onMoveRight: widget.onMoveRight,
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('v1.0.2  |  OTTKING Smart TV', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.hint,
    required this.isActive,
    required this.onTap,
    this.onMoveRight,
  });
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final String hint;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onMoveRight;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_update);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
    if (widget.focusNode.hasFocus) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = widget.focusNode.hasFocus;
    final bool active = isFocused || widget.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () {
          widget.focusNode.requestFocus();
          widget.onTap();
        },
        child: Focus(
          focusNode: widget.focusNode,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select)) {
              widget.onTap();
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
              widget.onMoveRight?.call();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isFocused ? AppTheme.primary.withOpacity(0.2) : (widget.isActive ? AppTheme.primary.withOpacity(0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? AppTheme.primary : Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: active ? AppTheme.primary : Colors.white38, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(widget.hint, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.focusNode, required this.onTap, this.onKeyEvent});
  final FocusNode focusNode;
  final VoidCallback onTap;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (_, event) => onKeyEvent?.call(event) ?? KeyEventResult.ignored,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: onTap,
        style: IconButton.styleFrom(foregroundColor: focusNode.hasFocus ? AppTheme.primary : Colors.white70),
      ),
    );
  }
}

class _NavMeta {
  const _NavMeta({required this.icon, required this.label, required this.hint});
  final IconData icon;
  final String label;
  final String hint;
}