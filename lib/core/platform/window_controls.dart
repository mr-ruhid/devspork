import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'platform_detector.dart';

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (PlatformDetector.supportsWindowControls) {
      windowManager.addListener(this);
      _syncMaximized();
    }
  }

  @override
  void dispose() {
    if (PlatformDetector.supportsWindowControls) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    final bool value = await windowManager.isMaximized();
    if (!mounted) return;
    setState(() => _isMaximized = value);
  }

  @override
  void onWindowMaximize() {
    if (!mounted) return;
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (!mounted) return;
    setState(() => _isMaximized = false);
  }

  Future<void> _minimize() async {
    await windowManager.minimize();
  }

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _close() async {
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.supportsWindowControls) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _WindowButton(
          icon: Icons.remove_rounded,
          tooltip: 'Minimize',
          hoverColor: const Color(0xFF64B5F6),
          onTap: _minimize,
        ),
        const SizedBox(width: 6),
        _WindowButton(
          icon: _isMaximized
              ? Icons.filter_none_rounded
              : Icons.crop_square_rounded,
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
          hoverColor: const Color(0xFF81C784),
          onTap: _toggleMaximize,
        ),
        const SizedBox(width: 6),
        _WindowButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          hoverColor: const Color(0xFFE57373),
          onTap: _close,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.hoverColor,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color hoverColor;
  final VoidCallback onTap;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovered
                  ? widget.hoverColor.withOpacity(0.28)
                  : Colors.white.withOpacity(0.08),
              border: Border.all(
                color: _hovered
                    ? widget.hoverColor.withOpacity(0.55)
                    : Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}