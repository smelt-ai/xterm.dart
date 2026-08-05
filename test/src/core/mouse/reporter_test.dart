import 'package:test/test.dart';
import 'package:xterm/src/core/mouse/reporter.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('MouseReporter', () {
    test('report() supports normal mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.normal,
      );

      expect(output, equals('\x1B[M !"'));
    });

    test('report() supports utf mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.utf,
      );

      expect(output, equals('\x1B[M !"'));
    });

    test('report() supports sgr mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.sgr,
      );

      expect(output, equals('\x1B[<0;1;1M'));
    });

    test('report() supports urxvt mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.urxvt,
      );

      expect(output, equals('\x1B[32;1;1M'));
    });

    group('mouse wheel buttons', () {
      test('report() encodes a wheel tick without a modifier', () {
        // Bit 6 marks a wheel and the low two bits carry the button number.
        // Adding the button number on top of 64 instead would set the shift
        // and meta bits, which strict applications reject.
        expect(TerminalMouseButton.wheelUp.id, equals(64));
        expect(TerminalMouseButton.wheelDown.id, equals(65));
        expect(TerminalMouseButton.wheelLeft.id, equals(66));
        expect(TerminalMouseButton.wheelRight.id, equals(67));
      });

      test('report() supports sgr mode for the wheel', () {
        expect(
          MouseReporter.report(
            TerminalMouseButton.wheelUp,
            TerminalMouseButtonState.down,
            CellOffset(2, 3),
            MouseReportMode.sgr,
          ),
          equals('\x1B[<64;3;4M'),
        );
        expect(
          MouseReporter.report(
            TerminalMouseButton.wheelDown,
            TerminalMouseButtonState.down,
            CellOffset(2, 3),
            MouseReportMode.sgr,
          ),
          equals('\x1B[<65;3;4M'),
        );
      });
    });
  });
}
