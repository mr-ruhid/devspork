
import 'package:flutter/material.dart';

class EdgePanel extends StatefulWidget {
  const EdgePanel({super.key, required this.child});

  final Widget child;

  @override
  State<EdgePanel> createState() => _EdgePanelState();
}

class _EdgePanelState extends State<EdgePanel>
    with SingleTickerProviderStateMixin {
  static const double _panelWidth = 260;
  static const double _handleWidth = 22;
  static const double _handleHeight = 56;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  bool _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setOpen(bool value) {
    if (_open == value) return;
    setState(() => _open = value);
    if (value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: widget.child),
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            final double t = _controller.value;
            final double left = -_panelWidth + (_panelWidth * t);
            return Positioned(
              left: left,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: _panelWidth,
                child: widget.child,
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            final double t = _controller.value;
            final double left = (_panelWidth * t) - _handleWidth + 4;
            return Positioned(
              left: left,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onHorizontalDragUpdate: (DragUpdateDetails d) {
                    if (d.delta.dx > 2 && !_open) _setOpen(true);
                    if (d.delta.dx < -2 && _open) _setOpen(false);
                  },
                  onTap: () => _setOpen(!_open),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: _handleWidth,
                      height: _handleHeight,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Icon(
                        _open
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}