import 'package:flutter/material.dart';

class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null || !primaryFocus.hasFocus) return;

    if (_isInsideFocusedEditable(event.position, primaryFocus)) return;

    primaryFocus.unfocus();
  }

  bool _isInsideFocusedEditable(Offset globalPosition, FocusNode focusNode) {
    final renderObject = focusNode.context?.findRenderObject();
    if (renderObject is! RenderBox) return false;

    final localPosition = renderObject.globalToLocal(globalPosition);
    return renderObject.paintBounds.contains(localPosition);
  }
}
