import 'package:xterm/src/core/input/keys.dart';
import 'package:xterm/src/core/input/keytab/keytab.dart';
import 'package:xterm/src/core/state.dart';
import 'package:xterm/src/core/platform.dart';

/// The key event received from the keyboard, along with the state of the
/// modifier keys and state of the terminal. Typically consumed by the
/// [TerminalInputHandler] to produce a escape sequence that can be recognized
/// by the terminal.
///
/// See also:
/// - [TerminalInputHandler]
class TerminalKeyboardEvent {
  final TerminalKey key;

  final bool shift;

  final bool ctrl;

  final bool alt;

  final TerminalState state;

  final bool altBuffer;

  final TerminalTargetPlatform platform;

  TerminalKeyboardEvent({
    required this.key,
    required this.shift,
    required this.ctrl,
    required this.alt,
    required this.state,
    required this.altBuffer,
    required this.platform,
  });

  TerminalKeyboardEvent copyWith({
    TerminalKey? key,
    bool? shift,
    bool? ctrl,
    bool? alt,
    TerminalState? state,
    bool? altBuffer,
    TerminalTargetPlatform? platform,
  }) {
    return TerminalKeyboardEvent(
      key: key ?? this.key,
      shift: shift ?? this.shift,
      ctrl: ctrl ?? this.ctrl,
      alt: alt ?? this.alt,
      state: state ?? this.state,
      altBuffer: altBuffer ?? this.altBuffer,
      platform: platform ?? this.platform,
    );
  }

  @override
  String toString() {
    return 'TerminalKeyboardEvent(key: $key, shift: $shift, ctrl: $ctrl, alt: $alt, state: $state, altBuffer: $altBuffer, platform: $platform)';
  }
}

/// TerminalInputHandler contains the logic for translating a [TerminalKeyboardEvent]
/// into escape sequences that can be recognized by the terminal.
abstract class TerminalInputHandler {
  /// Translates a [TerminalKeyboardEvent] into an escape sequence. If the event
  /// cannot be translated, null is returned.
  String? call(TerminalKeyboardEvent event);
}

/// A [TerminalInputHandler] that chains multiple handlers together. If any
/// handler returns a non-null value, it is returned. Otherwise, null is
/// returned.
class CascadeInputHandler implements TerminalInputHandler {
  final List<TerminalInputHandler> _handlers;

  const CascadeInputHandler(this._handlers);

  @override
  String? call(TerminalKeyboardEvent event) {
    for (var handler in _handlers) {
      final result = handler(event);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

/// A [TerminalInputHandler] that reports keys through the kitty keyboard
/// protocol while an application has it enabled.
///
/// Under the `DISAMBIGUATE` flag the terminal must report a key that has an
/// ambiguous legacy encoding as `CSI unicode-key-code ; modifiers u`, and the
/// legacy form is suppressed. So an application that asked for the protocol —
/// Claude Code does, from v2.1 — hears nothing when it is sent `ESC [ Z` for
/// Shift+Tab. This handler runs ahead of the keytab so those keys take the
/// CSI u form, and declines everything else so the legacy path still owns
/// unmodified keys, which the protocol leaves alone.
class KittyInputHandler implements TerminalInputHandler {
  const KittyInputHandler();

  /// `DISAMBIGUATE`, the only flag whose reporting this handler implements.
  static const disambiguate = 1;

  /// The protocol's own key codes for keys that are not a unicode code point.
  static const _functionalKeyCodes = {
    TerminalKey.arrowUp: 1,
    TerminalKey.arrowDown: 2,
    TerminalKey.arrowLeft: 3,
    TerminalKey.arrowRight: 4,
    TerminalKey.tab: 9,
    TerminalKey.home: 11,
    TerminalKey.end: 12,
    TerminalKey.pageUp: 13,
    TerminalKey.pageDown: 14,
    TerminalKey.insert: 15,
    TerminalKey.delete: 16,
    TerminalKey.f1: 17,
    TerminalKey.f2: 18,
    TerminalKey.f3: 19,
    TerminalKey.f4: 20,
    TerminalKey.f5: 21,
    TerminalKey.f6: 22,
    TerminalKey.f7: 23,
    TerminalKey.f8: 24,
    TerminalKey.f9: 25,
    TerminalKey.f10: 26,
    TerminalKey.f11: 27,
    TerminalKey.f12: 28,
    TerminalKey.enter: 13,
    TerminalKey.escape: 27,
    TerminalKey.backspace: 127,
  };

  /// `CSI u` numbers the modifiers from 1, one bit each.
  static int encodeModifiers(TerminalKeyboardEvent event) =>
      1 + (event.shift ? 1 : 0) + (event.alt ? 2 : 0) + (event.ctrl ? 4 : 0);

  @override
  String? call(TerminalKeyboardEvent event) {
    if (event.state.keyboardFlags & disambiguate == 0) {
      return null;
    }

    final modifiers = encodeModifiers(event);
    if (modifiers == 1) {
      // An unmodified key keeps its legacy encoding under this flag.
      return null;
    }

    // Ctrl with a plain letter stays a C0 control code: readline and friends
    // read 0x03 as interrupt, and reporting it as CSI u would break them. The
    // protocol only asks for the ambiguous cases, and this one is not.
    final code = _functionalKeyCodes[event.key];
    if (code == null) {
      return null;
    }

    return '\x1b[$code;${modifiers}u';
  }
}

/// The default input handler for the terminal. That is composed of a
/// [KeytabInputHandler], a [CtrlInputHandler], and a [AltInputHandler].
///
/// It's possible to override the default input handler behavior by chaining
/// another input handler before or after the default input handler using
/// [CascadeInputHandler].
///
/// See also:
///  * [CascadeInputHandler]
const defaultInputHandler = CascadeInputHandler([
  KittyInputHandler(),
  KeytabInputHandler(),
  CtrlInputHandler(),
  AltInputHandler(),
]);

/// A [TerminalInputHandler] that translates key events according to a keytab
/// file. If no keytab is provided, [Keytab.defaultKeytab] is used.
class KeytabInputHandler implements TerminalInputHandler {
  const KeytabInputHandler([this.keytab]);

  final Keytab? keytab;

  @override
  String? call(TerminalKeyboardEvent event) {
    final keytab = this.keytab ?? Keytab.defaultKeytab;

    final record = keytab.find(
      event.key,
      ctrl: event.ctrl,
      alt: event.alt,
      shift: event.shift,
      newLineMode: event.state.lineFeedMode,
      appCursorKeys: event.state.cursorKeysMode,
      appKeyPad: event.state.appKeypadMode,
      appScreen: event.altBuffer,
      macos: event.platform == TerminalTargetPlatform.macos,
    );

    if (record == null) {
      return null;
    }

    var result = record.action.unescapedValue();
    result = insertModifiers(event, result);
    return result;
  }

  String insertModifiers(TerminalKeyboardEvent event, String action) {
    String? code;

    if (event.shift && event.alt && event.ctrl) {
      code = '8';
    } else if (event.ctrl && event.alt) {
      code = '7';
    } else if (event.shift && event.ctrl) {
      code = '6';
    } else if (event.ctrl) {
      code = '5';
    } else if (event.shift && event.alt) {
      code = '4';
    } else if (event.alt) {
      code = '3';
    } else if (event.shift) {
      code = '2';
    }

    if (code != null) {
      return action.replaceAll('*', code);
    }

    return action;
  }
}

/// A [TerminalInputHandler] that translates ctrl + key events into escape
/// sequences. For example, ctrl + a becomes ^A.
class CtrlInputHandler implements TerminalInputHandler {
  const CtrlInputHandler();

  @override
  String? call(TerminalKeyboardEvent event) {
    if (!event.ctrl || event.shift || event.alt) {
      return null;
    }

    final key = event.key;

    if (key.index >= TerminalKey.keyA.index &&
        key.index <= TerminalKey.keyZ.index) {
      final input = key.index - TerminalKey.keyA.index + 1;
      return String.fromCharCode(input);
    }

    return null;
  }
}

/// A [TerminalInputHandler] that translates alt + key events into escape
/// sequences. For example, alt + a becomes ^[a.
class AltInputHandler implements TerminalInputHandler {
  const AltInputHandler();

  @override
  String? call(TerminalKeyboardEvent event) {
    if (!event.alt || event.ctrl || event.shift) {
      return null;
    }

    if (event.platform == TerminalTargetPlatform.macos) {
      return null;
    }

    final key = event.key;

    if (key.index >= TerminalKey.keyA.index &&
        key.index <= TerminalKey.keyZ.index) {
      final charCode = key.index - TerminalKey.keyA.index + 65;
      final input = [0x1b, charCode];
      return String.fromCharCodes(input);
    }

    return null;
  }
}
