import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// প্লেয়ার রিমোট ও টিভি ফোকাস অ্যাকশন সার্বজনীন হেল্পার
bool isTvActivateKey(KeyEvent event) {
  return event is KeyDownEvent &&
      (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.space);
}

bool isTvBackKey(KeyEvent event) {
  return event is KeyDownEvent &&
      (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack);
}

KeyEventResult handleTvActivate(KeyEvent event, VoidCallback onActivate) {
  if (isTvActivateKey(event)) {
    onActivate();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

KeyEventResult handleTvBack(KeyEvent event, VoidCallback onBack) {
  if (isTvBackKey(event)) {
    onBack();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
