// lib/core/theme/app_ui_kit.dart
//
// Mərkəzləşdirilmiş "glass" UI kit — bütün mini-tool səhifələri eyni
// widget-lərdən istifadə etsin deyə. iOS/iPhone-un Liquid Glass estetikasına
// uyğunlaşdırılıb: ContinuousRectangleBorder (squircle künclər), spesifik
// "işıq düşmə" zolağı, scale-down toxunma animasiyaları.

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kAccentA = Color(0xFF7C4DFF);
const Color kAccentB = Color(0xFF00E5FF);
const Color kDanger = Color(0xFFFF5C5C);
const Color kSuccess = Color(0xFF4BD68B);
const Color kWarning = Color(0xFFFFC24B);
const Color kBgTop = Color(0xFF1B1035);
const Color kBgMid = Color(0xFF2A1550);
const Color kBgBot = Color(0xFF0F2A4A);
const Color kScaffoldBg = Color(0xFF0B0B12);

/// Bütün "glass" widget-lərin istifadə etdiyi ortaq dizayn tokenləri.
/// Dəyəri burada dəyişsən, bütün tətbiqdə eyni anda yenilənir.
class GlassTokens {
  GlassTokens._();

  static const double radiusLg = 20;
  static const double radiusMd = 14;
  static const double radiusSm = 10;
  static const double radiusPill = 999;

  static const double blurStrong = 24;
  static const double blurMedium = 16;
  static const double blurLight = 10;

  static const double borderOpacity = 0.22;
  static const double highlightOpacity = 0.55;

  static const Duration pressDuration = Duration(milliseconds: 120);
  static const Duration fadeDuration = Duration(milliseconds: 150);

  static const double pressScale = 0.96;
  static const double pressOpacity = 0.75;
}

/// iOS-vari toxunma effekti: ripple yox, scale-down + yüngül opacity dim.
/// Bütün glass düymə/chip-lər bunun üzərində qurulur.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool haptic;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!widget.enabled) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) return;
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: active ? _handleTap : null,
      child: AnimatedOpacity(
        duration: GlassTokens.fadeDuration,
        opacity: !active
            ? 0.5
            : (_pressed ? GlassTokens.pressOpacity : 1.0),
        child: AnimatedScale(
          scale: (_pressed && active) ? GlassTokens.pressScale : 1.0,
          duration: GlassTokens.pressDuration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Aşağı səviyyəli şüşə səth: blur + gradient tint + squircle sərhəd +
/// üst tərəfdə incə "işıq" zolağı. `GlassCard` və digər glass widget-lər
/// bunun üzərində qurulur.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = GlassTokens.radiusLg,
    this.blur = GlassTokens.blurStrong,
    this.borderOpacity = GlassTokens.borderOpacity,
    this.showHighlight = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final double borderOpacity;
  final bool showHighlight;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);
    final ShapeBorder shape = ContinuousRectangleBorder(borderRadius: br);

    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Stack(
          children: <Widget>[
            Container(
              padding: padding,
              decoration: ShapeDecoration(
                shape: ContinuousRectangleBorder(
                  borderRadius: br,
                  side: BorderSide(
                    color: Colors.white.withOpacity(borderOpacity),
                    width: 1,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withOpacity(0.13),
                    Colors.white.withOpacity(0.045),
                  ],
                ),
                shadows: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: child,
            ),
            if (showHighlight)
              Positioned(
                top: 0,
                left: radius * 0.7,
                right: radius * 0.7,
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.transparent,
                          Colors.white
                              .withOpacity(GlassTokens.highlightOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: GlassTokens.blurStrong,
            sigmaY: GlassTokens.blurStrong,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.35),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = GlassTokens.radiusLg,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: padding,
      radius: radius,
      child: child,
    );
  }
}

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[kBgTop, kBgMid, kBgBot],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(top: -80, left: -60, child: glassBlob(220, kAccentA)),
          Positioned(bottom: -100, right: -60, child: glassBlob(260, kAccentB)),
          child,
        ],
      ),
    );
  }
}

Widget glassBlob(double size, Color color) {
  return IgnorePointer(
    child: ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.35),
          ),
        ),
      ),
    ),
  );
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onTap: onTap,
        child: GlassSurface(
          padding: const EdgeInsets.all(8),
          radius: GlassTokens.radiusSm,
          blur: GlassTokens.blurLight,
          showHighlight: false,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class MiniIconButton extends StatelessWidget {
  const MiniIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget button = _Pressable(
      onTap: onTap,
      haptic: false,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: color ?? Colors.white70,
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
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
    final bool active = enabled && !loading && onPressed != null;
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
    );

    return _Pressable(
      enabled: active,
      onTap: onPressed,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[kAccentA, kAccentB],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Şüşəli düymələrin üstündə incə glossy overlay.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.white.withOpacity(0.22),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
    );

    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GlassTokens.fadeDuration,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          shape: shape,
          gradient: selected
              ? const LinearGradient(colors: <Color>[kAccentA, kAccentB])
              : null,
          color: selected ? null : Colors.white.withOpacity(0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassActionChip extends StatelessWidget {
  const GlassActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      side: BorderSide(color: Colors.white.withOpacity(0.15)),
    );

    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          shape: shape,
          color: Colors.white.withOpacity(0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({
    super.key,
    required this.message,
    this.detail,
  });

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      side: BorderSide(color: kDanger.withOpacity(0.4)),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        shape: shape,
        color: kDanger.withOpacity(0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 18,
                color: kDanger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFFFBFBF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null && detail!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: const TextStyle(
                color: Color(0xFFFFBFBF),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MetricBox extends StatelessWidget {
  const MetricBox({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      side: BorderSide(color: color.withOpacity(0.3)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: ShapeDecoration(
        shape: shape,
        color: color.withOpacity(0.08),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class GlassSliderRow extends StatelessWidget {
  const GlassSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: ShapeDecoration(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                  ),
                  color: kAccentB.withOpacity(0.15),
                ),
                child: Text(
                  '${value.round()}${suffix ?? ''}',
                  style: const TextStyle(
                    color: kAccentB,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kAccentA,
              inactiveTrackColor: Colors.white24,
              thumbColor: kAccentB,
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions ?? (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassSwitchRow extends StatelessWidget {
  const GlassSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              value: value,
              activeColor: kAccentA,
              onChanged: (bool v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ToastBubble extends StatelessWidget {
  const ToastBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        radius: GlassTokens.radiusMd,
        blur: GlassTokens.blurMedium,
        borderOpacity: 0.15,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

void showGlassToast(BuildContext context, String message) {
  final OverlayState overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext ctx) => Positioned(
      bottom: 90,
      left: 40,
      right: 40,
      child: ToastBubble(message: message),
    ),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 1600), entry.remove);
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String sanitizeFileName(String name, {String fallback = 'output'}) {
  final String trimmed = name.trim();
  final String cleaned = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return cleaned.isEmpty ? fallback : cleaned;
}

List<int> parsePageRange(String raw, int total) {
  final Set<int> pages = <int>{};
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return List<int>.generate(total, (int i) => i + 1);
  }
  final List<String> parts = trimmed.split(',');
  for (final String rawPart in parts) {
    final String part = rawPart.trim();
    if (part.isEmpty) continue;
    if (part.contains('-')) {
      final List<String> bounds = part.split('-');
      if (bounds.length != 2) continue;
      final int? lo = int.tryParse(bounds[0].trim());
      final int? hi = int.tryParse(bounds[1].trim());
      if (lo == null || hi == null) continue;
      final int start = lo < 1 ? 1 : lo;
      final int end = hi > total ? total : hi;
      for (int i = start; i <= end; i++) {
        pages.add(i);
      }
    } else {
      final int? single = int.tryParse(part);
      if (single == null) continue;
      if (single >= 1 && single <= total) pages.add(single);
    }
  }
  return pages.toList()..sort();
}