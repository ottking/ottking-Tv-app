// lib/presentation/widgets/tv_focus.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tv_focus_utils.dart';

typedef TvFocusBuilder = Widget Function(BuildContext context, bool isFocused);

class TvFocus extends StatefulWidget {
  const TvFocus({
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.skipTraversal = false,
    this.onFocusChange,
    this.onKeyEvent,
    this.onActivate,
    this.onBack,
    required this.builder,
  });

  final FocusNode? focusNode;
  final bool autofocus;
  final bool skipTraversal;
  final ValueChanged<bool>? onFocusChange;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;
  final VoidCallback? onActivate;
  final VoidCallback? onBack;
  final TvFocusBuilder builder;

  @override
  State<TvFocus> createState() => _TvFocusState();
}

class _TvFocusState extends State<TvFocus> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      skipTraversal: widget.skipTraversal,
      onFocusChange: (v) {
        setState(() => _focused = v);
        widget.onFocusChange?.call(v);
      },
      onKeyEvent: (_, event) {
        // onActivate চেক আগে
        if (widget.onActivate != null && isTvActivateKey(event)) {
          return handleTvActivate(event, widget.onActivate!);
        }
        // Back চেক
        if (widget.onBack != null && isTvBackKey(event)) {
          return handleTvBack(event, widget.onBack!);
        }
        // Custom key handler (Left arrow ইত্যাদি)
        return widget.onKeyEvent?.call(event) ?? KeyEventResult.ignored;
      },
      child: widget.builder(context, _focused),
    );
  }
}
