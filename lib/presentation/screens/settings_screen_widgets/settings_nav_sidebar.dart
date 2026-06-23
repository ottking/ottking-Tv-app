// lib/presentation/screens/settings_screen_widgets/settings_nav_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class SettingsNavSidebar extends StatefulWidget {
  const SettingsNavSidebar({
    super.key,
    required this.activeSection,
    required this.sidebarNodes,       // ← screen থেকে সব node আসে
    required this.onSelect,
    required this.onBack,
    this.onNavigateRight,
  });

  final int activeSection;
  final List<FocusNode> sidebarNodes; // [nav-0, nav-1, nav-2]
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;
  final VoidCallback? onNavigateRight;

  @override
  State<SettingsNavSidebar> createState() => _SettingsNavSidebarState();
}

class _SettingsNavSidebarState extends State<SettingsNavSidebar> {
  final FocusNode _backNode = FocusNode(debugLabel: 'settings-back-btn');

  static const _items = [
    _NavMeta(icon: Icons.account_circle_rounded,        label: 'ACCOUNT',     hint: 'Login / Subscription'),
    _NavMeta(icon: Icons.tv_rounded,                    label: 'TV SETTINGS', hint: 'Boot Player and More'),
    _NavMeta(icon: Icons.settings_applications_rounded, label: 'SYSTEM',      hint: 'Catalog / App Info'),
  ];

  @override
  void dispose() {
    _backNode.dispose();
    // sidebarNodes গুলো screen থেকে এসেছে, এখানে dispose করা যাবে না
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

            // ── Header + Back ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _BackButton(
                    focusNode: _backNode,
                    onTap: widget.onBack,
                    onKeyEvent: (event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        widget.sidebarNodes[0].requestFocus();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        widget.onNavigateRight?.call();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SETTINGS',
                    style: TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Nav Items ─────────────────────────────────────────────
            ...List.generate(_items.length, (i) {
              return _NavItem(
                focusNode: widget.sidebarNodes[i],
                icon: _items[i].icon,
                label: _items[i].label,
                hint: _items[i].hint,
                isActive: widget.activeSection == i,
                onSelect: () => widget.onSelect(i),
                onKeyEvent: (event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;

                  // ↑ প্রথম item → back button
                  if (i == 0 && event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _backNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  // ↓ শেষ item → absorb (wrap করব না)
                  if (i == _items.length - 1 &&
                      event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    return KeyEventResult.handled;
                  }
                  // ↑↓ normal
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp && i > 0) {
                    widget.sidebarNodes[i - 1].requestFocus();
                    widget.onSelect(i - 1);
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                      i < _items.length - 1) {
                    widget.sidebarNodes[i + 1].requestFocus();
                    widget.onSelect(i + 1);
                    return KeyEventResult.handled;
                  }
                  // → Right → content
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    widget.onNavigateRight?.call();
                    return KeyEventResult.handled;
                  }

                  return KeyEventResult.ignored;
                },
              );
            }),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'v1.0.0  |  Smart TV',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.2), fontSize: 12),
              ),
            ),
          ],
        ),
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

// ── Back Button ───────────────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  const _BackButton(
      {required this.focusNode, required this.onTap, this.onKeyEvent});
  final FocusNode focusNode;
  final VoidCallback onTap;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return widget.onKeyEvent?.call(event) ?? KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _focused ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _focused ? AppTheme.primary : Colors.transparent),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: _focused ? AppTheme.primary : Colors.white70, size: 18),
        ),
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.hint,
    required this.isActive,
    required this.onSelect,
    this.onKeyEvent,
  });
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final String hint;
  final bool isActive;
  final VoidCallback onSelect;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || widget.isActive;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (v) {
          setState(() => _focused = v);
          if (v) widget.onSelect();
        },
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select)) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
          return widget.onKeyEvent?.call(event) ?? KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _focused
                  ? AppTheme.primary.withOpacity(0.2)
                  : widget.isActive
                      ? AppTheme.primary.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active ? AppTheme.primary : Colors.transparent,
                  width: 1.5),
            ),
            child: Row(
              children: [
                Icon(widget.icon,
                    color: active ? AppTheme.primary : Colors.white38, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label,
                          style: TextStyle(
                              color: active ? Colors.white : Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text(widget.hint,
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: active ? AppTheme.primary : Colors.white12, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
