
// lib/tools/pdfmerge/ui_kit.dart

import 'dart:ui';

import 'package:flutter/material.dart';

class PdfGlassSurface extends StatelessWidget {
  const PdfGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.blur = 24,
    this.opacity,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double fillOpacity = opacity ?? (isDark ? 0.08 : 0.55);
    final Color borderColor = Colors.white.withOpacity(isDark ? 0.14 : 0.65);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(fillOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.03 : 0.6),
                blurRadius: 1,
                spreadRadius: 0.5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class PdfGlassBackground extends StatelessWidget {
  const PdfGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                colors.surface,
                colors.surfaceContainerHighest,
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _blob(colors.primary.withOpacity(0.35), 260),
        ),
        Positioned(
          bottom: -100,
          right: -60,
          child: _blob(colors.tertiary.withOpacity(0.30), 240),
        ),
        Positioned(
          top: 220,
          right: -100,
          child: _blob(colors.secondary.withOpacity(0.22), 220),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: const SizedBox.expand(),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class PdfGlassButton extends StatelessWidget {
  const PdfGlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool active = enabled && !loading;
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: active
              ? colors.primary.withOpacity(0.9)
              : colors.primary.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: active ? onPressed : null,
        icon: loading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class PdfGlassIconButton extends StatelessWidget {
  const PdfGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PdfGlassSurface(
      radius: 14,
      padding: EdgeInsets.zero,
      child: IconButton(
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}