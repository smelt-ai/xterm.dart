enum TerminalMouseButton {
  left(id: 0),

  middle(id: 1),

  right(id: 2),

  wheelUp(id: 64 + 0, isWheel: true),

  wheelDown(id: 64 + 1, isWheel: true),

  wheelLeft(id: 64 + 2, isWheel: true),

  wheelRight(id: 64 + 3, isWheel: true),
  ;

  /// The id that is used to report a button press or release to the terminal.
  ///
  /// A wheel button is reported with bit 6 set (+64) and its button number
  /// carried in the low two bits, giving 64 (up), 65 (down), 66 (left) and
  /// 67 (right). The button number is transposed into those bits rather than
  /// added on top of 64: bits 2 and 3 are the shift and meta modifiers, so
  /// `64 + 5` reports wheel-down *with shift* instead of wheel-down. Strict
  /// applications reject a wheel report that carries a modifier, and since the
  /// alternate screen has no scrollback of its own and is scrolled purely by
  /// these reports, scrolling a full screen application does nothing at all.
  final int id;

  /// Whether this button is a mouse wheel button.
  final bool isWheel;

  const TerminalMouseButton({required this.id, this.isWheel = false});
}
