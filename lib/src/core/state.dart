import 'package:xterm/src/core/cursor.dart';
import 'package:xterm/src/core/mouse/mode.dart';

abstract class TerminalState {
  int get viewWidth;

  int get viewHeight;

  CursorStyle get cursor;

  bool get reflowEnabled;

  /* Modes */

  bool get insertMode;

  bool get lineFeedMode;

  /* DEC Private modes */

  bool get cursorKeysMode;

  bool get reverseDisplayMode;

  bool get originMode;

  bool get autoWrapMode;

  MouseMode get mouseMode;

  MouseReportMode get mouseReportMode;

  bool get cursorBlinkMode;

  bool get cursorVisibleMode;

  bool get appKeypadMode;

  bool get reportFocusMode;

  bool get altBufferMouseScrollMode;

  bool get bracketedPasteMode;

  /// The flags at the top of the kitty keyboard protocol stack, or 0 when no
  /// application has asked for it. Bit 1 is `DISAMBIGUATE`, under which a key
  /// that has an ambiguous legacy encoding must be reported as `CSI u`
  /// instead — the legacy form is suppressed, so sending it reaches nothing.
  ///
  /// https://sw.kovidgoyal.net/kitty/keyboard-protocol/
  int get keyboardFlags;
}
