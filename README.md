
## xterm.dart

> **This is a fork.** It is maintained by Smelt for Smelt's own use and is not
> a general purpose release of xterm. The upstream package at
> [TerminalStudio/xterm.dart](https://github.com/TerminalStudio/xterm.dart) has
> not merged a pull request since February 2024, so the fixes below live here
> rather than upstream. They are not offered back; consume this fork directly.
>
> ### What this fork changes
>
> - **A scroll no longer detaches the lines it moves.** `scrollUp`,
>   `scrollDown` and `deleteLines` moved a line with `lines[i] = lines[j]`,
>   which leaves the line referenced from both slots, so the pass that later
>   overwrites the source detaches the line it had already moved. The detached
>   line makes the next `insert` fail its `attached` assertion, and dereference
>   a null owner in a release build. They now move lines through `swap`, as
>   `insertLines` already did.
> - **A resize no longer resurrects trimmed scrollback.** `replaceWith` stored
>   the replacement through the ring's old rotation and reset that rotation
>   afterwards, so every later read landed `_startIndex` slots off. The
>   rotation is now reset before adopting.
> - **Wheel ticks are reported as wheel ticks.** The wheel buttons were
>   declared as `64 + 4` and `64 + 5`; bits 2 and 3 are the shift and meta
>   modifiers, so every tick went out as a modified click and strict
>   applications ignored it. They now carry their X11 numbers, 64 through 67.
> - **The kitty keyboard protocol is understood.** `CSI > flags u`,
>   `CSI < n u` and `CSI = flags ; mode u` are parsed and tracked on a stack,
>   and with the disambiguate flag set the keys a legacy encoding cannot tell
>   apart are reported as `CSI unicode ; modifiers u`. Applications that ask
>   for the protocol - Claude Code does, from v2.1 - stop reading the legacy
>   sequences once they have asked, so without this a terminal that keeps
>   sending them is one the application hears nothing from. Shift+Tab is the
>   visible case: `CSI Z` goes unread and the key does nothing at all.
> - **The arrow keys follow DECCKM.** The keytab was consulted with
>   `appKeypadMode` where it wanted `cursorKeysMode`, so an application that
>   set only DECCKM - the usual case - never saw `SS3 A`, and one that set only
>   DECKPAM saw it when it should not have.
> - **Shift+Enter reports LF.** It was indistinguishable from Enter, since the
>   `Enter` keytab entries carry no Shift variant and the `Return` ones Flutter
>   never reaches. LF is what the terminals that applications wanting
>   "Enter submits, Shift+Enter inserts a newline" are written against send.
> - **The software keyboard's return key is sent once.** iOS reports it twice:
>   `FlutterTextInputPlugin` sends the newline action and then returns YES,
>   letting the `"\n"` through into the editing value as well - the newline
>   action is the one action whose insertion it does not suppress. Acting on
>   both submits the line and then leaves a stray LF in the next prompt. The
>   action always arrives first, so a newline insert directly behind one is
>   dropped as the same key press; the Android keyboards that only commit the
>   newline as text and never report an action still work, and now report it as
>   the enter key rather than a raw LF.
> - The discontinued `dart_code_metrics` analyzer plugin is dropped, since it
>   no longer resolves on a supported SDK and blocked running the test suite.
>
> Each fix has a regression test that fails without it.
>
> ### Maintaining it
>
> `smelt` is the default branch and the one consumers pin against; `master`
> tracks upstream untouched. To take upstream changes, merge `master` into
> `smelt` and run `flutter test` - the regression tests above will say whether
> upstream has fixed any of this itself, at which point the corresponding
> change here can be dropped. Consumers pin a commit rather than the branch,
> so moving `smelt` never changes a build on its own.


<p>
    <a href="https://github.com/TerminalStudio/xterm.dart/actions/workflows/ci.yml">
      <img alt="Actions" src="https://github.com/TerminalStudio/xterm.dart/actions/workflows/ci.yml/badge.svg">
    </a>
    <a href="https://pub.dev/packages/xterm">
      <img alt="Package version" src="https://img.shields.io/pub/v/xterm?color=blue&include_prereleases">
    </a>
    <img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/TerminalStudio/xterm.dart">
    <img alt="GitHub issues" src="https://img.shields.io/github/issues-raw/TerminalStudio/xterm.dart">
    <img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/TerminalStudio/xterm.dart">
</p>


**xterm.dart** is a fast and fully-featured terminal emulator for Flutter applications, with support for mobile and desktop platforms.

> This package requires Flutter version >=3.0.0

## Screenshots

<table>
  <tr>
    <td>
		<img width="200px" src="https://raw.githubusercontent.com/TerminalStudio/xterm.dart/master/media/demo-shell.png">
    </td>
    <td>
       <img width="200px" src="https://raw.githubusercontent.com/TerminalStudio/xterm.dart/master/media/demo-vim.png">
    </td>
  <tr>
  </tr>
    <td>
       <img width="200px" src="https://raw.githubusercontent.com/TerminalStudio/xterm.dart/master/media/demo-htop.png">
    </td>
    <td>
       <img width="200px" src="https://raw.githubusercontent.com/TerminalStudio/xterm.dart/master/media/demo-dialog.png">
    </td>
  </tr>
</table>

## Features

- 📦 **Works out of the box** No special configuration required.
- 🚀 **Fast** Renders at 60fps.
- 😀 **Wide character support** Supports CJK and emojis.
- ✂️ **Customizable** 
- ✔ **Frontend independent**: The terminal core can work without flutter frontend.

**What's new in 3.0.0:**

- 📱 Enhanced support for **mobile** platforms.
- ⌨️ Integrates with Flutter's **shortcut** system.
- 🎨 Allows changing **theme** at runtime.
- 💪 Better **performance**. No tree rebuilds anymore.
- 🈂️ Works with **IMEs**.

## Getting Started

**1.** Add this to your package's pubspec.yaml file:

```yml
dependencies:
  ...
  xterm: ^3.2.6
```

**2.** Create the terminal:

```dart
import 'package:xterm/xterm.dart';
...
terminal = Terminal();
```

Listen to user interaction with the terminal by simply adding a `onOutput` callback:

```dart
terminal = Terminal();

terminal.onOutput = (output) {
  print('output: $output');
}
```

**3.** Create the view, attach the terminal to the view:

```dart
import 'package:xterm/flutter.dart';
...
child: TerminalView(terminal),
```

**4.** Write something to the terminal:

```dart
terminal.write('Hello, world!');
```

**Done!**

## More examples

- Write a simple terminal in ~100 lines of code:
  https://github.com/TerminalStudio/xterm.dart/blob/master/example/lib/main.dart

- Write a SSH client in ~100 lines of code with [dartssh2]:
  https://github.com/TerminalStudio/xterm.dart/blob/master/example/lib/ssh.dart
  
  <img width="400px" src="https://raw.githubusercontent.com/TerminalStudio/xterm.dart/master/media/example-ssh.png">

For a complete project built with xterm.dart, check out [TerminalStudio].

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/TerminalStudio/xterm.dart/issues).

Contributions are always welcome!

## License

This project is licensed under an MIT license.

[dartssh2]: https://pub.dev/packages/dartssh2
[TerminalStudio]: https://github.com/TerminalStudio/studio