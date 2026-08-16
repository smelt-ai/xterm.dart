import 'package:test/test.dart';
import 'package:xterm/core.dart';

/// Collects what the terminal would write back to the host.
List<String> _outputOf(void Function(Terminal terminal) body) {
  final output = <String>[];
  final terminal = Terminal();
  terminal.onOutput = output.add;
  body(terminal);
  return output;
}

/// Turns on the kitty keyboard protocol the way an application does.
void _enableKittyKeyboard(Terminal terminal, {int flags = 1}) {
  terminal.write('\x1b[>${flags}u');
}

void main() {
  group('kitty keyboard protocol state', () {
    test('CSI > flags u pushes the flags', () {
      final terminal = Terminal();
      expect(terminal.keyboardFlags, 0);
      terminal.write('\x1b[>1u');
      expect(terminal.keyboardFlags, 1);
    });

    test('an omitted parameter means flags 1', () {
      final terminal = Terminal();
      terminal.write('\x1b[>u');
      expect(terminal.keyboardFlags, 1);
    });

    test('CSI < u pops', () {
      final terminal = Terminal();
      terminal.write('\x1b[>1u');
      terminal.write('\x1b[<u');
      expect(terminal.keyboardFlags, 0);
    });

    test('a nested application leaving does not take the outer one down', () {
      final terminal = Terminal();
      terminal.write('\x1b[>1u');
      terminal.write('\x1b[>5u');
      terminal.write('\x1b[<u');
      expect(terminal.keyboardFlags, 1);
    });

    test('CSI = flags ; 2 u sets the given bits', () {
      final terminal = Terminal();
      terminal.write('\x1b[>1u');
      terminal.write('\x1b[=4;2u');
      expect(terminal.keyboardFlags, 5);
    });

    test('CSI = flags ; 3 u clears the given bits', () {
      final terminal = Terminal();
      terminal.write('\x1b[>5u');
      terminal.write('\x1b[=1;3u');
      expect(terminal.keyboardFlags, 4);
    });

    test('the sequence is not echoed as text', () {
      final terminal = Terminal();
      terminal.write('a\x1b[>1ub');
      expect(terminal.buffer.getText().trim(), 'ab');
    });
  });

  group('kitty keyboard protocol reporting', () {
    test('Shift+Tab is CSI u once an application asks for the protocol', () {
      // Without it, the legacy backtab is what the application reads.
      expect(
        _outputOf((t) => t.keyInput(TerminalKey.tab, shift: true)),
        ['\x1b[Z'],
      );

      // With it, the legacy form is suppressed by the protocol, so sending it
      // would reach nothing.
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.keyInput(TerminalKey.tab, shift: true);
        }),
        ['\x1b[9;2u'],
      );
    });

    test('Shift+Enter is CSI u under the protocol and LF without it', () {
      expect(
        _outputOf((t) => t.keyInput(TerminalKey.enter, shift: true)),
        ['\n'],
      );

      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.keyInput(TerminalKey.enter, shift: true);
        }),
        ['\x1b[13;2u'],
      );
    });

    test('an unmodified key keeps its legacy encoding', () {
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.keyInput(TerminalKey.tab);
        }),
        ['\t'],
      );
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.keyInput(TerminalKey.enter);
        }),
        ['\r'],
      );
    });

    test('Ctrl with a letter stays a C0 control code', () {
      // readline reads 0x03 as interrupt; reporting it as CSI u breaks it.
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.keyInput(TerminalKey.keyC, ctrl: true);
        }),
        ['\x03'],
      );
    });

    test('flags without DISAMBIGUATE do not change the encoding', () {
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t, flags: 4);
          t.keyInput(TerminalKey.tab, shift: true);
        }),
        ['\x1b[Z'],
      );
    });

    test('popping the protocol restores the legacy encoding', () {
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.write('\x1b[<u');
          t.keyInput(TerminalKey.tab, shift: true);
        }),
        ['\x1b[Z'],
      );
    });

    test('modifiers are numbered from 1, one bit each', () {
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.keyInput(TerminalKey.arrowUp, ctrl: true);
        }),
        ['\x1b[1;5u'],
      );
      expect(
        _outputOf((t) {
          _enableKittyKeyboard(t);
          t.keyInput(TerminalKey.arrowUp, shift: true, ctrl: true);
        }),
        ['\x1b[1;6u'],
      );
    });
  });

  group('application cursor keys', () {
    test('the arrows follow DECCKM, not the keypad mode', () {
      expect(
        _outputOf((t) => t.keyInput(TerminalKey.arrowUp)),
        ['\x1b[A'],
      );

      // DECCKM. Before this fork the keytab was consulted with the keypad
      // mode instead, so this stayed at the CSI form and applications that
      // set only DECCKM never saw an arrow.
      expect(
        _outputOf((t) {
          t.write('\x1b[?1h');
          t.keyInput(TerminalKey.arrowUp);
        }),
        ['\x1bOA'],
      );
    });
  });
}
