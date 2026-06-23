// lib/presentation/screens/settings_screen_widgets/settings_shared_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/tv_focus.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5),
    );
  }
}

class SettingsTwoColRow extends StatelessWidget {
  const SettingsTwoColRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length == 1) {
      return SizedBox(height: 76, child: children.first);
    }
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}

/// Focusable setting card
///
/// [focusNode]      — inject করা হলে সেটা ব্যবহার হয় (first/last node)
/// [isLastItem]     — true হলে ↓ চাপলে [onLastItemDown] call হয় (যদি [onMoveDown] না দেওয়া হয়)
/// [onNavigateLeft] — ← চাপলে sidebar এ ফেরত (যদি [onMoveLeft] না দেওয়া হয়)
/// [onLastItemDown] — last item এ ↓ চাপলে sidebar এ wrap
/// [onMoveRight]    — → চাপলে কাস্টম নেভিগেশন (যেমন: একই row এর পাশের card এ ফোকাস)
/// [onMoveDown]     — ↓ চাপলে কাস্টম নেভিগেশন (যেমন: নিচের row এর card এ ফোকাস)
/// [onMoveUp]       — ↑ চাপলে কাস্টম নেভিগেশন (যেমন: উপরের row এর card এ ফোকাস)
/// [onMoveLeft]     — ← চাপলে কাস্টম নেভিগেশন; দেওয়া না হলে [onNavigateLeft] ব্যবহার হবে
///
/// গুরুত্বপূর্ণ: একটি গ্রিডে ২টির বেশি card থাকলে (যেমন ২x২ লেআউট) প্রতিটি card এর
/// জন্য [onMoveRight]/[onMoveDown]/[onMoveUp] ঠিকভাবে wire করতে হবে — নাহলে arrow
/// key চাপলে কোনো handler না পেয়ে ফোকাস "হারিয়ে যাওয়ার" মতো (কোনো প্রতিক্রিয়া না হওয়া) অনুভূত হয়।
class SettingCard extends StatefulWidget {
  const SettingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.focusNode,
    this.trailing,
    this.highlight = false,
    this.onNavigateLeft,
    this.isLastItem = false,
    this.onLastItemDown,
    this.onMoveRight,
    this.onMoveDown,
    this.onMoveUp,
    this.onMoveLeft,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final Widget? trailing;
  final bool highlight;
  final VoidCallback? onNavigateLeft;
  final bool isLastItem;
  final VoidCallback? onLastItemDown;
  final VoidCallback? onMoveRight;
  final VoidCallback? onMoveDown;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveLeft;

  @override
  State<SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<SettingCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || widget.highlight;

    return TvFocus(
      focusNode: widget.focusNode,
      onFocusChange: (v) => setState(() => _focused = v),
      onActivate: widget.onTap,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        // ← কাস্টম হ্যান্ডলার থাকলে সেটা, নাহলে sidebar এ ফেরত (ডিফল্ট আচরণ)
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (widget.onMoveLeft != null) {
            widget.onMoveLeft!.call();
          } else {
            widget.onNavigateLeft?.call();
          }
          return KeyEventResult.handled;
        }
        // → পাশের card এ ফোকাস (একই row)
        if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
            widget.onMoveRight != null) {
          widget.onMoveRight!.call();
          return KeyEventResult.handled;
        }
        // ↑ উপরের row এর card এ ফোকাস
        if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
            widget.onMoveUp != null) {
          widget.onMoveUp!.call();
          return KeyEventResult.handled;
        }
        // ↓ নিচের row এর card এ ফোকাস (কাস্টম), নাহলে last item হলে sidebar এ wrap
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (widget.onMoveDown != null) {
            widget.onMoveDown!.call();
            return KeyEventResult.handled;
          }
          if (widget.isLastItem) {
            widget.onLastItemDown?.call();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      builder: (context, focused) => GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.card : const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? AppTheme.primary
                  : Colors.white.withOpacity(0.04),
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primary.withOpacity(0.15)
                      : const Color(0xFF0B0F19),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon,
                    color: active ? AppTheme.primary : Colors.white54,
                    size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              widget.trailing ??
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white24, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
