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
    required this.navNodes, // অ্যাকাউন্ট / TV / সিস্টেম — ৩টি ফোকাস নোড, প্যারেন্ট থেকে আসে
    // বাগ ফিক্স: → চাপলে আগে FocusScope.of(context).nextFocus() কল হতো, যা এই
    // সাইডবারের নিজস্ব FocusTraversalGroup স্কোপের মধ্যেই আটকে থাকতো এবং কখনোই
    // ডানপাশের কনটেন্ট এরিয়াতে যেতে পারতো না। এখন সরাসরি কলব্যাক দিয়ে
    // কনটেন্টের প্রথম ফোকাসেবল উইজেটে ফোকাস পাঠানো হবে।
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
    _NavMeta(
      icon: Icons.account_circle_rounded,
      label: 'Accounts',
      hint: 'Login/Subscriptions',
    ),
    _NavMeta(
  icon: Icons.tv_rounded,
  label: 'TV Settings',
  hint: 'Boot Player & More', // এখানে শেষে একটি ' ব্যবহার করুন
),
    _NavMeta(
      icon: Icons.settings_applications_rounded,
      label: 'Systems',
      hint: 'Update & more',
    ),
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

            // ── Header with Back Button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _BackButton(
                    focusNode: _backNode,
                    onTap: widget.onBack,
                    // ব্যাক বাটনে উপরে গেলে ফোকাস নষ্ট না হওয়ার জন্য
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent) {
                        // ব্যাক বাটন থেকে নিচে গেলে প্রথম নেভ আইটেমে
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          widget.navNodes[0].requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Nav Items ───────────────────────────────────────────
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = widget.activeSection == i;
              return _NavItem(
                focusNode: widget.navNodes[i],
                icon: item.icon,
                label: item.label,
                hint: item.hint,
                isActive: isActive,
                onTap: () => widget.onSelect(i),
                onMoveRight: widget.onMoveRight,
                // প্রথম আইটেম থেকে উপরে গেলে ব্যাক বাটনে ফোকাস
                onKeyEvent: i == 0
                    ? (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          _backNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      }
                    : null,
              );
            }),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'v1.0.2  |  OTTKING Smart TV',
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
  const _NavMeta(
      {required this.icon, required this.label, required this.hint});
  final IconData icon;
  final String label;
  final String hint;
}

// ── Back Button ─────────────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  const _BackButton({
    required this.focusNode,
    required this.onTap,
    this.onKeyEvent,
  });
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
            color: _focused
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppTheme.primary : Colors.transparent,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _focused ? AppTheme.primary : Colors.white70,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  const _NavItem({
    super.key,
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.hint,
    required this.isActive,
    required this.onTap,
    this.onKeyEvent,
    this.onMoveRight,
  });
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final String hint;
  final bool isActive;
  final VoidCallback onTap;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;
  final VoidCallback? onMoveRight;

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
          if (v) widget.onTap(); // ফোকাস হলেই সেকশন সুইচ
        },
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onMoveRight?.call();
            return KeyEventResult.handled;
          }
          return widget.onKeyEvent?.call(event) ?? KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _focused
                  ? AppTheme.primary.withOpacity(0.2)
                  : widget.isActive
                      ? AppTheme.primary.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppTheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon,
                    color: active ? AppTheme.primary : Colors.white38,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.hint,
                        style: const TextStyle(
                            color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: active ? AppTheme.primary : Colors.white12,
                    size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
