import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';
import 'painter.dart';
import 'parser.dart';

String _tr(BuildContext context, String key, String fallback) {
  try {
    final String value = context.t(key);
    if (value.isEmpty || value == key) return fallback;
    return value;
  } catch (_) {
    return fallback;
  }
}

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _warning = Color(0xFFFFC24B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class SvgPathViewer extends StatefulWidget {
  const SvgPathViewer({super.key});

  @override
  State<SvgPathViewer> createState() => _SvgPathViewerState();
}

class _SvgPathViewerState extends State<SvgPathViewer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final TextEditingController _input = TextEditingController();
  final GlobalKey _canvasKey = GlobalKey();

  SvgPathData? _data;
  String? _errorKey;
  String? _errorDetail;

  SvgPathOptions _opts = const SvgPathOptions();
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  int? _selectedSegment;
  int? _draggingSegment;

  Timer? _debounce;
  bool _showHandles = false;

  double _length = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _input.text = 'M 50 50 C 150 0, 250 100, 350 50 S 450 100, 500 50 L 500 150 Z';
    _parse(_input.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _input.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _parse(value));
  }

  void _parse(String input) {
    final String text = input.trim();
    if (text.isEmpty) {
      setState(() {
        _data = null;
        _errorKey = null;
        _errorDetail = null;
        _length = 0;
        _selectedSegment = null;
      });
      return;
    }

    try {
      final SvgPathData data = SvgPathParser.parse(text);
      final double len = SvgPathRenderer.computeLength(data);
      setState(() {
        _data = data;
        _length = len;
        _errorKey = null;
        _errorDetail = null;
        if (_selectedSegment != null &&
            _selectedSegment! >= data.segments.length) {
          _selectedSegment = null;
        }
      });
    } on SvgParseException catch (e) {
      setState(() {
        _data = null;
        _length = 0;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _data = null;
        _length = 0;
        _errorKey = SvgPathErrors.invalidCommand;
        _errorDetail = e.toString();
      });
    }
  }

  void _refreshAfterEdit() {
    final SvgPathData? d = _data;
    if (d == null) return;
    final double len = SvgPathRenderer.computeLength(d);
    setState(() {
      _length = len;
      _input.text = d.spacedPath;
    });
  }

  void _resetView() {
    setState(() {
      _zoom = 1.0;
      _pan = Offset.zero;
    });
  }

  void _zoomIn() => setState(() => _zoom = (_zoom * 1.25).clamp(0.1, 20.0));
  void _zoomOut() => setState(() => _zoom = (_zoom / 1.25).clamp(0.1, 20.0));

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.8),
        content: Text(label),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Node drag
  // -----------------------------------------------------------------

  Size _canvasSize() {
    final RenderBox? box =
    _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size ?? Size.zero;
  }

  Offset _screenToPath(Offset screen) {
    final SvgPathData? d = _data;
    if (d == null) return Offset.zero;
    final Rect bounds = SvgPathRenderer.computeBounds(d);
    final Offset center = bounds.center;
    final Size size = _canvasSize();
    return Offset(
      (screen.dx - size.width / 2 - _pan.dx) / _zoom + center.dx,
      (screen.dy - size.height / 2 - _pan.dy) / _zoom + center.dy,
    );
  }

  int? _hitTest(Offset screen) {
    final SvgPathData? d = _data;
    if (d == null) return null;
    final Offset p = _screenToPath(screen);
    final double threshold = 12.0 / _zoom;
    double best = threshold;
    int? bestIdx;
    for (int i = 0; i < d.segments.length; i++) {
      final Offset? end = d.segments[i].endPoint;
      if (end == null) continue;
      final double dist = (end - p).distance;
      if (dist < best) {
        best = dist;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  void _onPanStart(DragStartDetails details) {
    final int? idx = _hitTest(details.localPosition);
    if (idx == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSegment = idx;
      _draggingSegment = idx;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final int? idx = _draggingSegment;
    final SvgPathData? d = _data;
    if (idx == null || d == null) return;
    final Offset pathPos = _screenToPath(details.localPosition);
    _moveSegmentEndpoint(d, idx, pathPos);
    _refreshAfterEdit();
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _draggingSegment = null);
  }

  void _moveSegmentEndpoint(SvgPathData data, int index, Offset newEnd) {
    final SvgPathSegment seg = data.segments[index];
    final Offset start = seg.startPoint ?? Offset.zero;
    final bool rel = seg.relative;
    final double x = rel ? newEnd.dx - start.dx : newEnd.dx;
    final double y = rel ? newEnd.dy - start.dy : newEnd.dy;

    switch (seg.command) {
      case SvgPathCommand.moveTo:
      case SvgPathCommand.lineTo:
        seg.args[0] = x;
        seg.args[1] = y;
        break;
      case SvgPathCommand.horizontalLineTo:
        seg.args[0] = x;
        break;
      case SvgPathCommand.verticalLineTo:
        seg.args[0] = y;
        break;
      case SvgPathCommand.cubicBezierCurveTo:
        seg.args[4] = x;
        seg.args[5] = y;
        break;
      case SvgPathCommand.smoothCubicBezierCurveTo:
        seg.args[2] = x;
        seg.args[3] = y;
        break;
      case SvgPathCommand.quadraticBezierCurveTo:
        seg.args[2] = x;
        seg.args[3] = y;
        break;
      case SvgPathCommand.smoothQuadraticBezierCurveTo:
        seg.args[0] = x;
        seg.args[1] = y;
        break;
      case SvgPathCommand.ellipticalArc:
        seg.args[5] = x;
        seg.args[6] = y;
        break;
      case SvgPathCommand.closePath:
        return;
    }

    _recomputeEndpointsFrom(index);
  }

  void _recomputeEndpointsFrom(int startIndex) {
    final SvgPathData? d = _data;
    if (d == null) return;
    Offset current = startIndex == 0
        ? Offset.zero
        : (d.segments[startIndex - 1].endPoint ?? Offset.zero);
    Offset subpath = Offset.zero;

    for (int i = 0; i < d.segments.length; i++) {
      final SvgPathSegment seg = d.segments[i];
      final Offset start = current;
      Offset end = start;

      switch (seg.command) {
        case SvgPathCommand.moveTo:
        case SvgPathCommand.lineTo:
          end = seg.relative
              ? Offset(start.dx + seg.args[0], start.dy + seg.args[1])
              : Offset(seg.args[0], seg.args[1]);
          if (seg.command == SvgPathCommand.moveTo) subpath = end;
          break;
        case SvgPathCommand.horizontalLineTo:
          end = Offset(
            seg.relative ? start.dx + seg.args[0] : seg.args[0],
            start.dy,
          );
          break;
        case SvgPathCommand.verticalLineTo:
          end = Offset(
            start.dx,
            seg.relative ? start.dy + seg.args[0] : seg.args[0],
          );
          break;
        case SvgPathCommand.cubicBezierCurveTo:
          end = seg.relative
              ? Offset(start.dx + seg.args[4], start.dy + seg.args[5])
              : Offset(seg.args[4], seg.args[5]);
          break;
        case SvgPathCommand.smoothCubicBezierCurveTo:
          end = seg.relative
              ? Offset(start.dx + seg.args[2], start.dy + seg.args[3])
              : Offset(seg.args[2], seg.args[3]);
          break;
        case SvgPathCommand.quadraticBezierCurveTo:
          end = seg.relative
              ? Offset(start.dx + seg.args[2], start.dy + seg.args[3])
              : Offset(seg.args[2], seg.args[3]);
          break;
        case SvgPathCommand.smoothQuadraticBezierCurveTo:
          end = seg.relative
              ? Offset(start.dx + seg.args[0], start.dy + seg.args[1])
              : Offset(seg.args[0], seg.args[1]);
          break;
        case SvgPathCommand.ellipticalArc:
          end = seg.relative
              ? Offset(start.dx + seg.args[5], start.dy + seg.args[6])
              : Offset(seg.args[5], seg.args[6]);
          break;
        case SvgPathCommand.closePath:
          end = subpath;
          break;
      }

      d.segments[i] = SvgPathSegment(
        command: seg.command,
        args: seg.args,
        relative: seg.relative,
        startPoint: start,
        endPoint: end,
      );
      current = end;
    }
  }

  // -----------------------------------------------------------------
  // Segment editing
  // -----------------------------------------------------------------

  void _deleteSegment(int index) {
    final SvgPathData? d = _data;
    if (d == null) return;
    if (d.segments.length <= 1) return;
    HapticFeedback.mediumImpact();
    setState(() {
      d.segments.removeAt(index);
      _recomputeEndpointsFrom(0);
      _refreshAfterEdit();
      _selectedSegment = null;
    });
  }

  void _duplicateSegment(int index) {
    final SvgPathData? d = _data;
    if (d == null) return;
    final SvgPathSegment s = d.segments[index];
    HapticFeedback.selectionClick();
    setState(() {
      d.segments.insert(
        index + 1,
        SvgPathSegment(
          command: s.command,
          args: List<double>.of(s.args),
          relative: s.relative,
        ),
      );
      _recomputeEndpointsFrom(0);
      _refreshAfterEdit();
    });
  }

  void _moveSegment(int from, int to) {
    final SvgPathData? d = _data;
    if (d == null) return;
    if (to < 0 || to >= d.segments.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      final SvgPathSegment s = d.segments.removeAt(from);
      d.segments.insert(to, s);
      _recomputeEndpointsFrom(0);
      _refreshAfterEdit();
    });
  }

  void _updateArg(int segIndex, int argIndex, double value) {
    final SvgPathData? d = _data;
    if (d == null) return;
    setState(() {
      d.segments[segIndex].args[argIndex] = value;
      _recomputeEndpointsFrom(segIndex);
      _refreshAfterEdit();
    });
  }

  void _changeCommand(int segIndex, SvgPathCommand newCmd, bool relative) {
    final SvgPathData? d = _data;
    if (d == null) return;
    final SvgPathSegment old = d.segments[segIndex];
    final int needed = newCmd.argumentCount;
    final List<double> newArgs = List<double>.of(old.args);
    while (newArgs.length < needed) {
      newArgs.add(0);
    }
    while (newArgs.length > needed) {
      newArgs.removeLast();
    }
    setState(() {
      d.segments[segIndex] = SvgPathSegment(
        command: newCmd,
        args: newArgs,
        relative: relative,
        startPoint: old.startPoint,
      );
      _recomputeEndpointsFrom(segIndex);
      _refreshAfterEdit();
    });
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('svgpath_title')),
        bottom: _buildTabBar(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blob(260, _accentB)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    _buildViewerTab(),
                    _buildSegmentsTab(),
                    _buildExportTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _GlassCard(
          padding: const EdgeInsets.all(4),
          radius: 16,
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: <Color>[_accentA, _accentB],
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
            tabs: <Widget>[
              Tab(text: _tr(context, 'svgpath_tab_viewer', 'Viewer')),
              Tab(text: _tr(context, 'svgpath_tab_segments', 'Segments')),
              Tab(text: _tr(context, 'svgpath_tab_export', 'Export')),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Viewer tab
  // -----------------------------------------------------------------

  Widget _buildViewerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildInputCard(),
          const SizedBox(height: 14),
          _buildCanvasCard(),
          const SizedBox(height: 14),
          _buildAppearanceCard(),
          const SizedBox(height: 14),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.code_rounded,
                  _tr(context, 'svgpath_input', 'SVG path data'),
                ),
              ),
              _glassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: _tr(context, 'svgpath_paste', 'Paste'),
                onTap: () async {
                  final ClipboardData? c =
                  await Clipboard.getData(Clipboard.kTextPlain);
                  if (c == null || c.text == null) return;
                  _input.text = c.text!;
                  _parse(c.text!);
                },
              ),
              const SizedBox(width: 6),
              _glassIconButton(
                icon: Icons.close_rounded,
                tooltip: _tr(context, 'svgpath_clear', 'Clear'),
                onTap: () {
                  _input.clear();
                  _parse('');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _input,
            onChanged: _onInputChanged,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'M 10 10 L 90 10 L 90 90 L 10 90 Z',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.28),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accentB, width: 1.4),
              ),
            ),
          ),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 10),
            _errorBox(_errorKey!, _errorDetail),
          ],
        ],
      ),
    );
  }

  Widget _buildCanvasCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.preview_rounded,
                  _tr(context, 'svgpath_preview', 'Preview'),
                ),
              ),
              _zoomBadge(),
              const SizedBox(width: 6),
              _glassIconButton(
                icon: Icons.zoom_out_rounded,
                tooltip: _tr(context, 'svgpath_zoom_out', 'Zoom out'),
                onTap: _zoomOut,
              ),
              const SizedBox(width: 4),
              _glassIconButton(
                icon: Icons.zoom_in_rounded,
                tooltip: _tr(context, 'svgpath_zoom_in', 'Zoom in'),
                onTap: _zoomIn,
              ),
              const SizedBox(width: 4),
              _glassIconButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: _tr(context, 'svgpath_reset_view', 'Reset view'),
                onTap: _resetView,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              return Container(
                key: _canvasKey,
                height: 320,
                decoration: BoxDecoration(
                  color: _opts.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _data == null
                      ? Center(
                    child: Text(
                      _errorKey != null
                          ? _tr(context, 'svgpath_preview_error',
                          'Fix the path to preview')
                          : _tr(context, 'svgpath_preview_empty',
                          'Enter a path to preview'),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  )
                      : GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTapDown: (TapDownDetails d) {
                      final int? idx = _hitTest(d.localPosition);
                      setState(() => _selectedSegment = idx);
                    },
                    child: CustomPaint(
                      painter: SvgPathPainter(
                        data: _data!,
                        options: _opts,
                        zoom: _zoom,
                        pan: _pan,
                        highlightSegment: _selectedSegment,
                        showHandles: _showHandles,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            _tr(
              context,
              'svgpath_drag_hint',
              'Tip: tap a node to select it, then drag to move it.',
            ),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _accentB.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${(_zoom * 100).round()}%',
        style: const TextStyle(
          color: _accentB,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.palette_outlined,
            _tr(context, 'svgpath_appearance', 'Appearance'),
          ),
          const SizedBox(height: 10),
          _colorRow(
            label: _tr(context, 'svgpath_stroke_color', 'Stroke color'),
            color: _opts.strokeColor,
            onChanged: (Color? c) => setState(() {
              if (c != null) _opts = _opts.copyWith(strokeColor: c);
            }),
          ),
          _colorRow(
            label: _tr(context, 'svgpath_fill_color', 'Fill color'),
            color: _opts.fillColor,
            allowNone: true,
            onChanged: (Color? c) => setState(() {
              _opts = _opts.copyWith(fillColor: c);
            }),
          ),
          _colorRow(
            label: _tr(context, 'svgpath_fill_color', 'Fill color'),
            color: _opts.fillColor,
            allowNone: true,
            onChanged: (Color? c) => setState(() {
              _opts = _opts.copyWith(fillColor: c);
            }),
          ),
          const SizedBox(height: 6),
          _sliderRow(
            label: _tr(context, 'svgpath_stroke_width', 'Stroke width'),
            value: _opts.strokeWidth,
            min: 0.5,
            max: 10,
            suffix: 'px',
            onChanged: (double v) => setState(() {
              _opts = _opts.copyWith(strokeWidth: v);
            }),
          ),
          const Divider(color: Colors.white24, height: 20),
          _switchRow(
            label: _tr(context, 'svgpath_show_grid', 'Show grid'),
            value: _opts.gridVisible,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(gridVisible: v);
            }),
          ),
          _switchRow(
            label: _tr(context, 'svgpath_show_nodes', 'Show nodes'),
            value: _opts.showPoints,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(showPoints: v);
            }),
          ),
          _switchRow(
            label: _tr(context, 'svgpath_show_handles', 'Show bezier handles'),
            value: _showHandles,
            onChanged: (bool v) => setState(() => _showHandles = v),
          ),
          _switchRow(
            label: _tr(context, 'svgpath_show_labels', 'Show command labels'),
            value: _opts.showCommandLabels,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(showCommandLabels: v);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final SvgPathData? d = _data;
    if (d == null) return const SizedBox.shrink();
    final Rect bounds = SvgPathRenderer.computeBounds(d);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.info_outline_rounded,
            _tr(context, 'svgpath_info', 'Info'),
          ),
          const SizedBox(height: 8),
          _infoRow(
            _tr(context, 'svgpath_info_segments', 'Segments'),
            '${d.segments.length}',
          ),
          _infoRow(
            _tr(context, 'svgpath_info_length', 'Length'),
            '${_length.toStringAsFixed(2)} px',
          ),
          _infoRow(
            _tr(context, 'svgpath_info_width', 'Width'),
            '${bounds.width.toStringAsFixed(2)} px',
          ),
          _infoRow(
            _tr(context, 'svgpath_info_height', 'Height'),
            '${bounds.height.toStringAsFixed(2)} px',
          ),
          _infoRow(
            _tr(context, 'svgpath_info_position', 'Position'),
            '(${bounds.left.toStringAsFixed(1)}, ${bounds.top.toStringAsFixed(1)})',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _accentB,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Segments tab
  // -----------------------------------------------------------------

  Widget _buildSegmentsTab() {
    final SvgPathData? d = _data;
    if (d == null) {
      return Center(
        child: Text(
          _tr(context, 'svgpath_segments_empty', 'Parse a valid path first'),
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionTitle(
                  Icons.list_alt_rounded,
                  _tr(context, 'svgpath_segment_list', 'Segments'),
                ),
                const SizedBox(height: 4),
                Text(
                  '${d.segments.length} ${_tr(context, 'svgpath_segments', 'segments')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < d.segments.length; i++) ...<Widget>[
            _buildSegmentCard(i, d.segments[i]),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentCard(int index, SvgPathSegment seg) {
    final bool selected = _selectedSegment == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedSegment = index),
      child: _GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: seg.relative
                          ? <Color>[_accentB, _accentA]
                          : <Color>[_accentA, _accentB],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(color: _warning, width: 2)
                        : null,
                  ),
                  child: Text(
                    seg.letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${_tr(context, 'svgpath_seg_label', 'Command')} #${index + 1}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        seg.relative
                            ? _tr(context, 'svgpath_relative', 'relative')
                            : _tr(context, 'svgpath_absolute', 'absolute'),
                        style: TextStyle(
                          color: seg.relative ? _accentB : _accentA,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                _miniIconButton(
                  icon: Icons.arrow_upward_rounded,
                  tooltip: _tr(context, 'svgpath_move_up', 'Move up'),
                  onTap: index == 0 ? null : () => _moveSegment(index, index - 1),
                ),
                _miniIconButton(
                  icon: Icons.arrow_downward_rounded,
                  tooltip: _tr(context, 'svgpath_move_down', 'Move down'),
                  onTap: index == _data!.segments.length - 1
                      ? null
                      : () => _moveSegment(index, index + 1),
                ),
                _miniIconButton(
                  icon: Icons.copy_rounded,
                  tooltip: _tr(context, 'svgpath_duplicate', 'Duplicate'),
                  onTap: () => _duplicateSegment(index),
                ),
                _miniIconButton(
                  icon: Icons.close_rounded,
                  tooltip: _tr(context, 'svgpath_delete', 'Delete'),
                  onTap: _data!.segments.length <= 1
                      ? null
                      : () => _deleteSegment(index),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _commandPicker(seg, index),
            const SizedBox(height: 10),
            if (seg.command == SvgPathCommand.closePath)
              const Text(
                '—',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              )
            else
              _argsGrid(seg, index),
          ],
        ),
      ),
    );
  }

  Widget _commandPicker(SvgPathSegment seg, int segIndex) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: SvgPathCommand.values.map((SvgPathCommand cmd) {
        final bool selected = seg.command == cmd;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _changeCommand(segIndex, cmd, seg.relative);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? _accentA.withOpacity(0.4)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected
                    ? _accentA
                    : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Text(
              cmd.letter,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _argsGrid(SvgPathSegment seg, int segIndex) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List<Widget>.generate(seg.args.length, (int i) {
        return SizedBox(
          width: 78,
          child: TextFormField(
            initialValue: _fmtNum(seg.args[i]),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              isDense: true,
              labelText: _argLabel(seg.command, i),
              labelStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _accentB, width: 1.2),
              ),
            ),
            onFieldSubmitted: (String v) {
              final double? d = double.tryParse(v.trim());
              if (d == null) return;
              _updateArg(segIndex, i, d);
            },
          ),
        );
      }),
    );
  }

  String _argLabel(SvgPathCommand cmd, int i) {
    switch (cmd) {
      case SvgPathCommand.moveTo:
      case SvgPathCommand.lineTo:
        return i == 0 ? 'x' : 'y';
      case SvgPathCommand.horizontalLineTo:
        return 'x';
      case SvgPathCommand.verticalLineTo:
        return 'y';
      case SvgPathCommand.cubicBezierCurveTo:
        return <String>['x1', 'y1', 'x2', 'y2', 'x', 'y'][i];
      case SvgPathCommand.smoothCubicBezierCurveTo:
        return <String>['x2', 'y2', 'x', 'y'][i];
      case SvgPathCommand.quadraticBezierCurveTo:
        return <String>['x1', 'y1', 'x', 'y'][i];
      case SvgPathCommand.smoothQuadraticBezierCurveTo:
        return i == 0 ? 'x' : 'y';
      case SvgPathCommand.ellipticalArc:
        return <String>['rx', 'ry', 'rot', 'large', 'sweep', 'x', 'y'][i];
      case SvgPathCommand.closePath:
        return '';
    }
  }

  // -----------------------------------------------------------------
  // Export tab
  // -----------------------------------------------------------------

  Widget _buildExportTab() {
    final SvgPathData? d = _data;
    if (d == null) {
      return Center(
        child: Text(
          _tr(context, 'svgpath_export_empty', 'Parse a valid path first'),
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final String normalized = d.normalizedPath;
    final String spaced = d.spacedPath;
    final String json = const JsonEncoder.withIndent('  ').convert(d.toJson());
    final Rect bounds = SvgPathRenderer.computeBounds(d);
    final String svg = _buildSvgString(d, bounds);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _exportBlock(
            title: _tr(context, 'svgpath_export_normalized', 'Normalized path'),
            icon: Icons.compress_rounded,
            text: normalized,
          ),
          const SizedBox(height: 14),
          _exportBlock(
            title: _tr(context, 'svgpath_export_spaced', 'Spaced path'),
            icon: Icons.code_rounded,
            text: spaced,
          ),
          const SizedBox(height: 14),
          _exportBlock(
            title: _tr(context, 'svgpath_export_json', 'Segments JSON'),
            icon: Icons.data_object_rounded,
            text: json,
          ),
          const SizedBox(height: 14),
          _exportBlock(
            title: _tr(context, 'svgpath_export_svg', 'Full SVG'),
            icon: Icons.image_outlined,
            text: svg,
          ),
          const SizedBox(height: 14),
          _exportBlock(
            title: _tr(context, 'svgpath_export_length', 'Total length'),
            icon: Icons.straighten_rounded,
            text: '${_length.toStringAsFixed(4)} px',
          ),
        ],
      ),
    );
  }

  String _buildSvgString(SvgPathData data, Rect bounds) {
    final double pad = 10;
    final double w = (bounds.width + pad * 2).clamp(1, double.infinity);
    final double h = (bounds.height + pad * 2).clamp(1, double.infinity);
    final String d = data.spacedPath;
    final String fill = _opts.fillColor == null
        ? 'none'
        : _hex(_opts.fillColor!);
    final String stroke = _hex(_opts.strokeColor);

    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="${_fmtNum(bounds.left - pad)} ${_fmtNum(bounds.top - pad)} '
        '${_fmtNum(w)} ${_fmtNum(h)}" '
        'width="${_fmtNum(w)}" height="${_fmtNum(h)}">\n'
        '  <path d="$d"\n'
        '        fill="$fill"\n'
        '        stroke="$stroke"\n'
        '        stroke-width="${_fmtNum(_opts.strokeWidth)}" '
        'stroke-linejoin="round" stroke-linecap="round" />\n'
        '</svg>';
  }

  String _hex(Color c) {
    final int a = (c.a * 255).round();
    final int r = (c.r * 255).round();
    final int g = (c.g * 255).round();
    final int b = (c.b * 255).round();
    if (a == 255) {
      return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}';
    }
    return '#${a.toRadixString(16).padLeft(2, '0')}'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  Widget _exportBlock({
    required String title,
    required IconData icon,
    required String text,
  }) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _sectionTitle(icon, title)),
              _glassIconButton(
                icon: Icons.copy_rounded,
                tooltip: _tr(context, 'svgpath_copy', 'Copy'),
                onTap: () => _copy(
                  text,
                  _tr(context, 'svgpath_copied', 'Copied'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Shared widgets
  // -----------------------------------------------------------------

  Widget _sectionTitle(IconData icon, String text) {
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

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    String? suffix,
    required ValueChanged<double> onChanged,
  }) {
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
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}${suffix ?? ''}',
                  style: const TextStyle(
                    color: _accentB,
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
              activeTrackColor: _accentA,
              inactiveTrackColor: Colors.white24,
              thumbColor: _accentB,
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) * 10).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorRow({
    required String label,
    required Color? color,
    required ValueChanged<Color?> onChanged,
    bool allowNone = false,
  }) {
    const List<Color> palette = <Color>[
      Color(0xFF7C4DFF),
      Color(0xFF00E5FF),
      Color(0xFFFF5C5C),
      Color(0xFF4BD68B),
      Color(0xFFFFC24B),
      Color(0xFFEC4899),
      Color(0xFFFFFFFF),
      Color(0xFF1B1035),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              if (color != null)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (allowNone)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(null);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color == null
                          ? _accentB.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color == null
                            ? _accentB
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              for (final Color c in palette)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(c);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color == c ? _accentB : Colors.white24,
                        width: color == c ? 2 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String key, String? detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.error_outline, size: 16, color: _danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _tr(context, key, key),
                  style: const TextStyle(
                    color: Color(0xFFFF8A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              detail,
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

  Widget _miniIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? Colors.white24 : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
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

  static String _fmtNum(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
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