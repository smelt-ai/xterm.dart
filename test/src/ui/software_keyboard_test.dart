import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

/// Mounts a focused [TerminalView] with a software keyboard connection and
/// returns what the terminal writes back to the host.
Future<List<String>> _connect(WidgetTester tester, Terminal terminal) async {
  final output = <String>[];
  terminal.onOutput = output.add;

  final focusNode = FocusNode();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TerminalView(
          terminal,
          focusNode: focusNode,
          autofocus: true,
          deleteDetection: true,
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.testTextInput.hasAnyClients, isTrue);
  return output;
}

/// The baseline the editing state is reset to. [TerminalView] is mounted with
/// delete detection, which parks the cursor behind two spaces so that a
/// backspace is visible as a shrinking value.
const _baseline = '  ';

void main() {
  group('the software keyboard return key', () {
    testWidgets('is sent once when the platform reports it twice', (
      tester,
    ) async {
      final terminal = Terminal();
      final output = await _connect(tester, terminal);

      // What iOS does: the engine sends the newline action, then returns YES
      // and lets the "\n" through into the editing value. Acting on both
      // submits the line and then drops a stray LF into the next prompt.
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '$_baseline\n',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(output, ['\r']);
    });

    testWidgets('is sent when only the action is reported', (tester) async {
      final terminal = Terminal();
      final output = await _connect(tester, terminal);

      // What an Android keyboard on a non-multiline connection does.
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      await tester.pump();

      expect(output, ['\r']);
    });

    testWidgets('is sent when the newline is only committed as text', (
      tester,
    ) async {
      final terminal = Terminal();
      final output = await _connect(tester, terminal);

      // What the Android keyboards in TerminalStudio/xterm.dart#164 do. CR is
      // what the enter key sends; a raw LF would leave the line unsubmitted.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '$_baseline\n',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(output, ['\r']);
    });

    testWidgets('does not swallow a newline typed after other input', (
      tester,
    ) async {
      final terminal = Terminal();
      final output = await _connect(tester, terminal);

      await tester.testTextInput.receiveAction(TextInputAction.newline);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '${_baseline}a',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '$_baseline\n',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(output, ['\r', 'a', '\r']);
    });

    testWidgets('leaves ordinary text alone', (tester) async {
      final terminal = Terminal();
      final output = await _connect(tester, terminal);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '${_baseline}ls',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();

      expect(output, ['ls']);
    });
  });
}
