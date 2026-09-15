import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';

String netTr(BuildContext context, String key, String fallback) {
  try {
    final String value = context.t(key);
    if (value.isEmpty || value == key) return fallback;
    return value;
  } catch (_) {
    return fallback;
  }
}

class NetCard extends StatelessWidget {
  const NetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class NetIconButton extends StatelessWidget {
  const NetIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color tint = color ?? Colors.white;
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: highlighted
                ? NetColors.success.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: 18,
                  color: onTap == null
                      ? Colors.white24
                      : (highlighted ? NetColors.success : tint),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NetPrimaryButton extends StatelessWidget {
  const NetPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: onTap == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[NetColors.accentA, NetColors.accentB],
                ),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NetSectionTitle extends StatelessWidget {
  const NetSectionTitle(this.icon, this.text, {super.key});

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

class NetTextField extends StatelessWidget {
  const NetTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.maxLines = 1,
    this.minLines,
    this.monospace = true,
    this.obscure = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.suffixIcon,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final int? maxLines;
  final int? minLines;
  final bool monospace;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          maxLines: obscure ? 1 : maxLines,
          minLines: minLines,
          obscureText: obscure,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          autofocus: autofocus,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: monospace ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
              fontFamily: monospace ? 'monospace' : null,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: NetColors.accentA, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class NetSwitchRow extends StatelessWidget {
  const NetSwitchRow({
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
          Switch.adaptive(
            value: value,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class NetChipPicker<T> extends StatelessWidget {
  const NetChipPicker({
    super.key,
    this.label,
    required this.values,
    required this.current,
    required this.labelOf,
    required this.onChanged,
    this.scrollable = true,
  });

  final String? label;
  final List<T> values;
  final T current;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final Widget chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((T v) {
        final bool selected = v == current;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                colors: <Color>[
                  NetColors.accentA,
                  NetColors.accentB,
                ],
              )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              labelOf(v),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: chips,
          )
        else
          chips,
      ],
    );
  }
}

class NetErrorBox extends StatelessWidget {
  const NetErrorBox({
    super.key,
    required this.errorKey,
    this.detail,
    this.color,
  });

  final String errorKey;
  final String? detail;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? NetColors.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error_outline, size: 16, color: c),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  netTr(context, errorKey, errorKey),
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null && detail!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: TextStyle(
                color: c.withOpacity(0.8),
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

class NetInfoBanner extends StatelessWidget {
  const NetInfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? NetColors.warning;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: c.withOpacity(0.9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetOutputBlock extends StatelessWidget {
  const NetOutputBlock({
    super.key,
    required this.label,
    required this.value,
    required this.onCopy,
    this.copied = false,
    this.emptyHint,
    this.maxHeight,
    this.selectable = true,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool copied;
  final String? emptyHint;
  final double? maxHeight;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = value.isEmpty;
    final Widget text = selectable
        ? SelectableText(
      isEmpty ? (emptyHint ?? '—') : value,
      style: TextStyle(
        color: isEmpty ? Colors.white38 : Colors.white,
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.5,
      ),
    )
        : Text(
      isEmpty ? (emptyHint ?? '—') : value,
      style: TextStyle(
        color: isEmpty ? Colors.white38 : Colors.white,
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.5,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: NetColors.accentA,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            if (!isEmpty)
              NetIconButton(
                icon: copied ? Icons.check_rounded : Icons.copy_rounded,
                tooltip: copied
                    ? netTr(context, 'net_copied', 'Copied')
                    : netTr(context, 'net_copy', 'Copy'),
                onTap: onCopy,
                highlighted: copied,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 44,
            maxHeight: maxHeight ?? double.infinity,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: maxHeight != null
              ? SingleChildScrollView(child: text)
              : text,
        ),
      ],
    );
  }
}

class NetKeyValueRow extends StatelessWidget {
  const NetKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 130,
    this.valueColor,
    this.monospaceValue = true,
    this.copyValue = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final double labelWidth;
  final Color? valueColor;
  final bool monospaceValue;
  final bool copyValue;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 12,
                fontFamily: monospaceValue ? 'monospace' : null,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (copyValue && onCopy != null)
            NetIconButton(
              icon: Icons.copy_rounded,
              tooltip: netTr(context, 'net_copy', 'Copy'),
              onTap: onCopy!,
            ),
        ],
      ),
    );
  }
}

class NetStatusPill extends StatelessWidget {
  const NetStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class NetBlob extends StatelessWidget {
  const NetBlob(this.size, this.color, {super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}

class NetTabBar extends StatelessWidget implements PreferredSizeWidget {
  const NetTabBar({
    super.key,
    required this.controller,
    required this.labels,
    this.onTap,
  });

  final TabController controller;
  final List<String> labels;
  final ValueChanged<int>? onTap;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final bool scrollable = labels.length > 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: NetCard(
        padding: const EdgeInsets.all(4),
        radius: 16,
        child: TabBar(
          controller: controller,
          onTap: onTap,
          isScrollable: scrollable,
          tabAlignment:
          scrollable ? TabAlignment.start : TabAlignment.fill,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: <Color>[
                NetColors.accentA,
                NetColors.accentB,
              ],
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: labels
              .map((String l) => Tab(text: l))
              .toList(growable: false),
        ),
      ),
    );
  }
}

class NetScaffold extends StatelessWidget {
  const NetScaffold({super.key, required this.body});

  final TabBarView body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            NetColors.bgTop,
            NetColors.bgMid,
            NetColors.bgBot,
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            left: -60,
            child: NetBlob(220, NetColors.accentA),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: NetBlob(260, NetColors.accentB),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 56),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> netCopy(
    BuildContext context,
    String text, {
      String? label,
    }) async {
  if (text.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.lightImpact();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black.withOpacity(0.8),
      content: Text(label ?? netTr(context, 'net_copied', 'Copied')),
      duration: const Duration(seconds: 1),
    ),
  );
}

Future<void> netPaste(
    BuildContext context,
    TextEditingController controller,
    ) async {
  final ClipboardData? c = await Clipboard.getData(Clipboard.kTextPlain);
  if (c == null || c.text == null) return;
  HapticFeedback.selectionClick();
  controller.text = c.text!;
}