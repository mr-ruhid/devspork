// lib/tools/imagecrop.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/localization/app_localization.dart';
import '../core/theme/app_ui_kit.dart';

enum _AspectMode { free, square, r43, r34, r169, r916, r32, r23 }

extension on _AspectMode {
  double? get value {
    switch (this) {
      case _AspectMode.free:
        return null;
      case _AspectMode.square:
        return 1;
      case _AspectMode.r43:
        return 4 / 3;
      case _AspectMode.r34:
        return 3 / 4;
      case _AspectMode.r169:
        return 16 / 9;
      case _AspectMode.r916:
        return 9 / 16;
      case _AspectMode.r32:
        return 3 / 2;
      case _AspectMode.r23:
        return 2 / 3;
    }
  }

  String get label {
    switch (this) {
      case _AspectMode.free:
        return 'Free';
      case _AspectMode.square:
        return '1:1';
      case _AspectMode.r43:
        return '4:3';
      case _AspectMode.r34:
        return '3:4';
      case _AspectMode.r169:
        return '16:9';
      case _AspectMode.r916:
        return '9:16';
      case _AspectMode.r32:
        return '3:2';
      case _AspectMode.r23:
        return '2:3';
    }
  }
}

enum _DragHandle { none, move, topLeft, topRight, bottomLeft, bottomRight }

class ImageCrop extends StatefulWidget {
  const ImageCrop({super.key});

  @override
  State<ImageCrop> createState() => _ImageCropState();
}

class _ImageCropState extends State<ImageCrop> {
  Uint8List? _originalBytes;

  // NOT: _workingBytes redaktə zəncirinin ortasında HƏMİŞƏ PNG (lossless)
  // saxlanılır. Bu, rotate/flip/crop-u dəfələrlə tətbiq etsən belə keyfiyyət
  // itkisinin toplanmasının (compounding JPEG artifacts) qarşısını alır.
  // JPEG-ə çevrilmə yalnız _save() / _share() çağırılanda, BİR DƏFƏ baş verir.
  Uint8List? _workingBytes;
  String? _fileName;
  ui.Image? _displayImage;

  _AspectMode _aspect = _AspectMode.free;
  Rect _cropRect = const Rect.fromLTWH(0, 0, 1, 1);

  bool _busy = false;
  Uint8List? _resultBytes;
  int _resultWidth = 0;
  int _resultHeight = 0;
  String? _errorKey;
  String? _errorDetail;

  @override
  void dispose() {
    // ui.Image native (GPU/skia) resurs saxlayır — səhifədən çıxanda
    // mütləq dispose edilməlidir, yoxsa memory leak yaranır.
    _displayImage?.dispose();
    super.dispose();
  }

  void _setDisplayImage(ui.Image? next) {
    final ui.Image? old = _displayImage;
    _displayImage = next;
    // Köhnə şəkli YALNIZ widget ağacından çıxdıqdan sonra (bu frame-in
    // sonunda) dispose et — build() metodunda hələ istifadə oluna bilər.
    if (old != null && !identical(old, next)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  Future<ui.Image?> _decode(Uint8List bytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  /// `image` paketi ilə decode edib, itkisiz PNG kimi geri qaytarır.
  /// Bütün daxili redaktə addımları (rotate/flip/crop) bunun üzərindən keçir.
  Uint8List _toLosslessWorking(img.Image image) {
    return Uint8List.fromList(img.encodePng(image, level: 6));
  }

  Future<void> _pick() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _errorKey = null;
      _errorDetail = null;
    });

    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>[
          'jpg', 'jpeg', 'jpe', 'png', 'webp', 'bmp', 'gif', 'tif', 'tiff',
        ],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final PlatformFile file = picked.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
        } catch (_) {}
      }

      if (bytes == null) {
        setState(() => _errorKey = 'imagecrop_error_read');
        return;
      }

      setState(() => _busy = true);

      // Original faylı dərhal itkisiz (PNG) daxili formata çeviririk ki,
      // sonrakı bütün redaktələr eyni keyfiyyət bazasından başlasın —
      // fərqi olmayaraq daxil olunan fayl JPEG, WEBP və ya başqa nə olursa.
      final img.Image? decodedForWorking = img.decodeImage(bytes);
      if (decodedForWorking == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _errorKey = 'imagecrop_error_decode';
        });
        return;
      }
      final Uint8List workingPng = _toLosslessWorking(decodedForWorking);

      final ui.Image? decoded = await _decode(workingPng);
      if (decoded == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _errorKey = 'imagecrop_error_decode';
        });
        return;
      }
      if (!mounted) return;

      setState(() {
        _originalBytes = bytes;
        _workingBytes = workingPng;
        _fileName = file.name;
        _setDisplayImage(decoded);
        _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
        _aspect = _AspectMode.free;
        _resultBytes = null;
        _resultWidth = 0;
        _resultHeight = 0;
        _errorKey = null;
        _errorDetail = null;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'imagecrop_error_pick';
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _rotate(bool clockwise) async {
    final Uint8List? bytes = _workingBytes;
    if (bytes == null || _busy) return;

    HapticFeedback.selectionClick();
    setState(() => _busy = true);

    final Uint8List? out = await Future<Uint8List?>(() {
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final img.Image rotated = img.copyRotate(
        decoded,
        angle: clockwise ? 90 : -90,
      );
      return _toLosslessWorking(rotated);
    });

    if (out == null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'imagecrop_error_process';
      });
      return;
    }

    final ui.Image? decodedImage = await _decode(out);
    if (!mounted) return;

    setState(() {
      _workingBytes = out;
      _setDisplayImage(decodedImage);
      _cropRect = _aspect.value != null
          ? _constrainAspectFor(decodedImage, _aspect.value!)
          : const Rect.fromLTWH(0, 0, 1, 1);
      _resultBytes = null;
      _resultWidth = 0;
      _resultHeight = 0;
      _busy = false;
    });
  }

  Future<void> _flip(bool horizontal) async {
    final Uint8List? bytes = _workingBytes;
    if (bytes == null || _busy) return;

    HapticFeedback.selectionClick();
    setState(() => _busy = true);

    final Uint8List? out = await Future<Uint8List?>(() {
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final img.Image flipped = horizontal
          ? img.flipHorizontal(decoded)
          : img.flipVertical(decoded);
      return _toLosslessWorking(flipped);
    });

    if (out == null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'imagecrop_error_process';
      });
      return;
    }

    final ui.Image? decodedImage = await _decode(out);
    if (!mounted) return;

    setState(() {
      _workingBytes = out;
      _setDisplayImage(decodedImage);
      _resultBytes = null;
      _resultWidth = 0;
      _resultHeight = 0;
      _busy = false;
    });
  }

  Future<void> _resetAll() async {
    final Uint8List? original = _originalBytes;
    if (original == null || _busy) return;

    setState(() => _busy = true);

    final img.Image? decoded = img.decodeImage(original);
    if (decoded == null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'imagecrop_error_process';
      });
      return;
    }
    final Uint8List workingPng = _toLosslessWorking(decoded);
    final ui.Image? decodedImage = await _decode(workingPng);
    if (!mounted) return;

    setState(() {
      _workingBytes = workingPng;
      _setDisplayImage(decodedImage);
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
      _aspect = _AspectMode.free;
      _resultBytes = null;
      _resultWidth = 0;
      _resultHeight = 0;
      _errorKey = null;
      _errorDetail = null;
      _busy = false;
    });
  }

  Future<void> _applyCrop() async {
    final Uint8List? bytes = _workingBytes;
    if (bytes == null || _busy) return;

    setState(() => _busy = true);

    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'imagecrop_error_process';
      });
      return;
    }

    final int x = (_cropRect.left * decoded.width).round().clamp(
      0,
      decoded.width - 1,
    );
    final int y = (_cropRect.top * decoded.height).round().clamp(
      0,
      decoded.height - 1,
    );
    final int w = (_cropRect.width * decoded.width).round().clamp(
      1,
      decoded.width - x,
    );
    final int h = (_cropRect.height * decoded.height).round().clamp(
      1,
      decoded.height - y,
    );

    final img.Image cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: w,
      height: h,
    );
    final Uint8List out = _toLosslessWorking(cropped);

    final ui.Image? decodedImage = await _decode(out);
    if (!mounted) return;

    setState(() {
      _workingBytes = out;
      _setDisplayImage(decodedImage);
      _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
      _resultBytes = out;
      _resultWidth = w;
      _resultHeight = h;
      _busy = false;
    });

    HapticFeedback.mediumImpact();
    showGlassToast(context, context.t('imagecrop_cropped'));
  }

  /// Nəticəni yalnız BURADA — istifadəçi faktiki save/share edəndə —
  /// itkili JPEG-ə çeviririk. Beləliklə bütün redaktə zənciri boyu
  /// keyfiyyət itkisi cəmi 1 dəfə baş verir, hər addımda yox.
  Uint8List? _encodeFinalJpeg() {
    final Uint8List? source = _resultBytes ?? _workingBytes;
    if (source == null) return null;
    final img.Image? decoded = img.decodeImage(source);
    if (decoded == null) return null;
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 95));
  }

  Future<void> _save() async {
    if (_busy) return;
    final Uint8List? jpegBytes = _encodeFinalJpeg();
    if (jpegBytes == null) return;

    final String rawName = _fileName ?? 'image';
    final String base = sanitizeFileName(
      rawName.replaceAll(RegExp(r'\.[^.]+$'), ''),
      fallback: 'image',
    );

    try {
      await FileSaver.instance.saveFile(
        name: '${base}_edited',
        bytes: jpegBytes,
        fileExtension: 'jpg',
        mimeType: MimeType.jpeg,
      );
      if (!mounted) return;
      showGlassToast(context, context.t('imagecrop_saved'));
    } catch (e) {
      if (!mounted) return;
      showGlassToast(context, '${context.t('imagecrop_error_save')}: $e');
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    final Uint8List? jpegBytes = _encodeFinalJpeg();
    if (jpegBytes == null) return;

    final String rawName = _fileName ?? 'image';
    final String base = sanitizeFileName(
      rawName.replaceAll(RegExp(r'\.[^.]+$'), ''),
      fallback: 'image',
    );

    try {
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${base}_edited.jpg');
      await file.writeAsBytes(jpegBytes, flush: true);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: '${base}_edited.jpg',
      );
    } catch (e) {
      if (!mounted) return;
      showGlassToast(context, '${context.t('imagecrop_error_share')}: $e');
    }
  }

  Rect _constrainAspect(Rect r, double ratio) {
    final ui.Image? image = _displayImage;
    if (image == null) return r;
    return _constrainAspectFor(image, ratio, base: r);
  }

  Rect _constrainAspectFor(
      ui.Image? image,
      double ratio, {
        Rect base = const Rect.fromLTWH(0, 0, 1, 1),
      }) {
    if (image == null) return base;

    double pw = base.width * image.width;
    double ph = base.height * image.height;
    if (pw / ph > ratio) {
      pw = ph * ratio;
    } else {
      ph = pw / ratio;
    }
    final double nw = pw / image.width;
    final double nh = ph / image.height;

    double left = base.center.dx - nw / 2;
    double top = base.center.dy - nh / 2;
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + nw > 1) left = 1 - nw;
    if (top + nh > 1) top = 1 - nh;
    return Rect.fromLTWH(left, top, nw, nh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kScaffoldBg,
      appBar: GlassAppBar(
        title: context.t('imagecrop_title'),
        actions: <Widget>[
          if (_originalBytes != null)
            GlassIconButton(
              icon: CupertinoIcons.refresh,
              tooltip: context.t('imagecrop_reset'),
              onTap: _busy ? () {} : _resetAll,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _pickCard(),
                if (_displayImage != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _editorCard(),
                  const SizedBox(height: 14),
                  _toolsCard(),
                  const SizedBox(height: 14),
                  _aspectCard(),
                  const SizedBox(height: 14),
                  GradientActionButton(
                    label: _busy
                        ? context.t('imagecrop_processing')
                        : context.t('imagecrop_apply_crop'),
                    icon: CupertinoIcons.crop,
                    onPressed: _applyCrop,
                    enabled: !_busy,
                    loading: _busy,
                  ),
                ],
                if (_errorKey != null) ...<Widget>[
                  const SizedBox(height: 14),
                  ErrorBox(
                    message: context.t(_errorKey!),
                    detail: _errorDetail,
                  ),
                ],
                if (_resultBytes != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _resultCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickCard() {
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      side: BorderSide(color: kAccentB.withOpacity(0.4), width: 1.2),
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.photo,
            text: context.t('imagecrop_section_image'),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: _busy ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: _busy,
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: ShapeDecoration(
                    shape: shape,
                    color: kAccentB.withOpacity(0.06),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        _displayImage == null
                            ? CupertinoIcons.cloud_upload
                            : CupertinoIcons.photo_fill,
                        size: 36,
                        color: kAccentB,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fileName ?? context.t('imagecrop_pick'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('imagecrop_formats_hint'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorCard() {
    final ui.Image image = _displayImage!;
    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: AspectRatio(
        aspectRatio: image.width / image.height,
        child: _CropEditor(
          image: image,
          cropRect: _cropRect,
          aspectRatio: _aspect.value,
          onChanged: (Rect r) => setState(() => _cropRect = r),
        ),
      ),
    );
  }

  Widget _toolsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.wand_stars,
            text: context.t('imagecrop_section_tools'),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _ToolButton(
                  icon: CupertinoIcons.rotate_left,
                  label: context.t('imagecrop_rotate_left'),
                  enabled: !_busy,
                  onTap: () => _rotate(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolButton(
                  icon: CupertinoIcons.rotate_right,
                  label: context.t('imagecrop_rotate_right'),
                  enabled: !_busy,
                  onTap: () => _rotate(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _ToolButton(
                  icon: CupertinoIcons.arrow_left_right,
                  label: context.t('imagecrop_flip_h'),
                  enabled: !_busy,
                  onTap: () => _flip(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolButton(
                  icon: CupertinoIcons.arrow_up_arrow_down,
                  label: context.t('imagecrop_flip_v'),
                  enabled: !_busy,
                  onTap: () => _flip(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aspectCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.rectangle,
            text: context.t('imagecrop_section_aspect'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _AspectMode.values.map((_AspectMode m) {
              return GlassChip(
                label: m.label,
                selected: _aspect == m,
                onTap: _busy
                    ? () {}
                    : () {
                  setState(() {
                    _aspect = m;
                    final double? ratio = m.value;
                    if (ratio != null) {
                      _cropRect = _constrainAspect(_cropRect, ratio);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.check_mark_circled,
                  text: context.t('imagecrop_result'),
                ),
              ),
              GlassIconButton(
                icon: CupertinoIcons.arrow_down_doc,
                tooltip: context.t('imagecrop_save'),
                onTap: _busy ? () {} : _save,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: CupertinoIcons.share,
                tooltip: context.t('imagecrop_share'),
                onTap: _busy ? () {} : _share,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricBox(
                  label: context.t('imagecrop_width'),
                  value: '$_resultWidth px',
                  color: kAccentB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('imagecrop_height'),
                  value: '$_resultHeight px',
                  color: kAccentA,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('imagecrop_size'),
                  // Qeyd: bu, itkisiz PNG ölçüsüdür (dəqiq iş faylı).
                  // Yekun JPEG faylının ölçüsü save/share zamanı fərqli
                  // (adətən daha kiçik) olacaq.
                  value: formatBytes(_resultBytes?.length ?? 0),
                  color: kSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Squircle formalı, iOS-vari scale-press animasiyası olan alət düyməsi.
class _ToolButton extends StatefulWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!widget.enabled) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      side: BorderSide(color: Colors.white.withOpacity(0.15)),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedOpacity(
        duration: GlassTokens.fadeDuration,
        opacity: !widget.enabled ? 0.4 : (_pressed ? 0.7 : 1),
        child: AnimatedScale(
          scale: (_pressed && widget.enabled) ? GlassTokens.pressScale : 1.0,
          duration: GlassTokens.pressDuration,
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: ShapeDecoration(
              shape: shape,
              color: Colors.white.withOpacity(0.06),
            ),
            child: Column(
              children: <Widget>[
                Icon(widget.icon, size: 20, color: Colors.white),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropEditor extends StatefulWidget {
  const _CropEditor({
    required this.image,
    required this.cropRect,
    required this.aspectRatio,
    required this.onChanged,
  });

  final ui.Image image;
  final Rect cropRect;
  final double? aspectRatio;
  final ValueChanged<Rect> onChanged;

  @override
  State<_CropEditor> createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor> {
  _DragHandle _active = _DragHandle.none;
  Offset _startPos = Offset.zero;
  Rect _startRect = Rect.zero;

  _DragHandle _hitTest(Offset pos, Rect rect) {
    const double handleRadius = 22;
    final List<MapEntry<_DragHandle, Offset>> handles =
    <MapEntry<_DragHandle, Offset>>[
      MapEntry<_DragHandle, Offset>(_DragHandle.topLeft, rect.topLeft),
      MapEntry<_DragHandle, Offset>(_DragHandle.topRight, rect.topRight),
      MapEntry<_DragHandle, Offset>(_DragHandle.bottomLeft, rect.bottomLeft),
      MapEntry<_DragHandle, Offset>(
        _DragHandle.bottomRight,
        rect.bottomRight,
      ),
    ];
    for (final MapEntry<_DragHandle, Offset> e in handles) {
      if ((pos - e.value).distance < handleRadius) return e.key;
    }
    if (rect.contains(pos)) return _DragHandle.move;
    return _DragHandle.none;
  }

  Rect _applyDelta(Rect rect, Offset delta, Size bounds) {
    switch (_active) {
      case _DragHandle.none:
        return rect;
      case _DragHandle.move:
        double left = rect.left + delta.dx;
        double top = rect.top + delta.dy;
        if (left < 0) left = 0;
        if (top < 0) top = 0;
        if (left + rect.width > bounds.width) {
          left = bounds.width - rect.width;
        }
        if (top + rect.height > bounds.height) {
          top = bounds.height - rect.height;
        }
        return Rect.fromLTWH(left, top, rect.width, rect.height);
      case _DragHandle.topLeft:
        double left = (rect.left + delta.dx).clamp(0.0, rect.right - 24);
        double top = (rect.top + delta.dy).clamp(0.0, rect.bottom - 24);
        return Rect.fromLTRB(left, top, rect.right, rect.bottom);
      case _DragHandle.topRight:
        double right =
        (rect.right + delta.dx).clamp(rect.left + 24, bounds.width);
        double top = (rect.top + delta.dy).clamp(0.0, rect.bottom - 24);
        return Rect.fromLTRB(rect.left, top, right, rect.bottom);
      case _DragHandle.bottomLeft:
        double left = (rect.left + delta.dx).clamp(0.0, rect.right - 24);
        double bottom =
        (rect.bottom + delta.dy).clamp(rect.top + 24, bounds.height);
        return Rect.fromLTRB(left, rect.top, rect.right, bottom);
      case _DragHandle.bottomRight:
        double right =
        (rect.right + delta.dx).clamp(rect.left + 24, bounds.width);
        double bottom =
        (rect.bottom + delta.dy).clamp(rect.top + 24, bounds.height);
        return Rect.fromLTRB(rect.left, rect.top, right, bottom);
    }
  }

  Rect _applyAspect(Rect rect, Size bounds) {
    final double? ratio = widget.aspectRatio;
    if (ratio == null) return rect;

    if (_active == _DragHandle.move) return rect;

    final Offset center = rect.center;
    double w = rect.width;
    double h = rect.height;

    if (w / h > ratio) {
      w = h * ratio;
    } else {
      h = w / ratio;
    }

    double left = center.dx - w / 2;
    double top = center.dy - h / 2;

    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + w > bounds.width) left = bounds.width - w;
    if (top + h > bounds.height) top = bounds.height - h;
    if (w > bounds.width) {
      w = bounds.width;
      h = w / ratio;
    }
    if (h > bounds.height) {
      h = bounds.height;
      w = h * ratio;
    }

    return Rect.fromLTWH(left, top, w, h);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size bounds = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final Rect pixelRect = Rect.fromLTWH(
          widget.cropRect.left * bounds.width,
          widget.cropRect.top * bounds.height,
          widget.cropRect.width * bounds.width,
          widget.cropRect.height * bounds.height,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (DragStartDetails d) {
            _startPos = d.localPosition;
            _startRect = pixelRect;
            _active = _hitTest(d.localPosition, pixelRect);
          },
          onPanUpdate: (DragUpdateDetails d) {
            if (_active == _DragHandle.none) return;
            final Offset delta = d.localPosition - _startPos;
            Rect next = _applyDelta(_startRect, delta, bounds);
            next = _applyAspect(next, bounds);
            next = Rect.fromLTRB(
              next.left.clamp(0.0, bounds.width),
              next.top.clamp(0.0, bounds.height),
              next.right.clamp(0.0, bounds.width),
              next.bottom.clamp(0.0, bounds.height),
            );
            widget.onChanged(
              Rect.fromLTWH(
                next.left / bounds.width,
                next.top / bounds.height,
                next.width / bounds.width,
                next.height / bounds.height,
              ),
            );
          },
          onPanEnd: (DragEndDetails d) {
            _active = _DragHandle.none;
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: RawImage(
                  image: widget.image,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _CropOverlayPainter(rect: pixelRect),
                ),
              ),
              Positioned(
                left: pixelRect.left - 10,
                top: pixelRect.top - 10,
                child: _handleDot(),
              ),
              Positioned(
                left: pixelRect.right - 10,
                top: pixelRect.top - 10,
                child: _handleDot(),
              ),
              Positioned(
                left: pixelRect.left - 10,
                top: pixelRect.bottom - 10,
                child: _handleDot(),
              ),
              Positioned(
                left: pixelRect.right - 10,
                top: pixelRect.bottom - 10,
                child: _handleDot(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _handleDot() {
    return IgnorePointer(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: kAccentA, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dimPaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final Path dimPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dimPath, dimPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 0.8;

    for (int i = 1; i <= 2; i++) {
      final double x = rect.left + rect.width * i / 3;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      final double y = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) => old.rect != rect;
}