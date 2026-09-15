import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'models.dart';

class SvgPathRenderer {
  SvgPathRenderer._();

  static Path toFlutterPath(SvgPathData data) {
    final Path path = Path();
    Offset current = Offset.zero;
    Offset subpathStart = Offset.zero;
    for (final SvgPathSegment seg in data.segments) {
      switch (seg.command) {
        case SvgPathCommand.moveTo:
          final Offset p = seg.endPoint ?? current;
          path.moveTo(p.dx, p.dy);
          current = p;
          subpathStart = p;
          break;

        case SvgPathCommand.lineTo:
          final Offset p = seg.endPoint ?? current;
          path.lineTo(p.dx, p.dy);
          current = p;
          break;

        case SvgPathCommand.horizontalLineTo:
        case SvgPathCommand.verticalLineTo:
          final Offset p = seg.endPoint ?? current;
          path.lineTo(p.dx, p.dy);
          current = p;
          break;

        case SvgPathCommand.cubicBezierCurveTo:
          final Offset c1 = _ctrl(seg.args, 0, seg, current);
          final Offset c2 = _ctrl(seg.args, 2, seg, current);
          final Offset end = seg.endPoint ?? current;
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          current = end;
          break;

        case SvgPathCommand.smoothCubicBezierCurveTo:
          final Offset c2 = _ctrl(seg.args, 0, seg, current);
          final Offset end = seg.endPoint ?? current;
          final Offset c1 = _reflectCubicControl(data, seg, current);
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          current = end;
          break;

        case SvgPathCommand.quadraticBezierCurveTo:
          final Offset c = _ctrl(seg.args, 0, seg, current);
          final Offset end = seg.endPoint ?? current;
          path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
          current = end;
          break;

        case SvgPathCommand.smoothQuadraticBezierCurveTo:
          final Offset end = seg.endPoint ?? current;
          final Offset c = _reflectQuadControl(data, seg, current);
          path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
          current = end;
          break;

        case SvgPathCommand.ellipticalArc:
          final Offset end = seg.endPoint ?? current;
          _appendArc(path, current, end, seg);
          current = end;
          break;

        case SvgPathCommand.closePath:
          path.close();
          current = subpathStart;
          break;
      }
    }
    return path;
  }

  static Offset _ctrl(List<double> args, int i, SvgPathSegment seg, Offset current) {
    final double x = args[i];
    final double y = args[i + 1];
    if (seg.relative) return Offset(current.dx + x, current.dy + y);
    return Offset(x, y);
  }

  static Offset _reflectCubicControl(
      SvgPathData data,
      SvgPathSegment seg,
      Offset current,
      ) {
    final int idx = data.segments.indexOf(seg);
    if (idx <= 0) return current;
    final SvgPathSegment prev = data.segments[idx - 1];
    if (prev.command != SvgPathCommand.cubicBezierCurveTo &&
        prev.command != SvgPathCommand.smoothCubicBezierCurveTo) {
      return current;
    }
    final Offset c2 = _absoluteSecondCubicControl(prev, data, idx - 1);
    return Offset(current.dx * 2 - c2.dx, current.dy * 2 - c2.dy);
  }

  static Offset _absoluteSecondCubicControl(
      SvgPathSegment seg,
      SvgPathData data,
      int idx,
      ) {
    final Offset start = seg.startPoint ?? Offset.zero;
    if (seg.command == SvgPathCommand.cubicBezierCurveTo) {
      final double x = seg.args[2];
      final double y = seg.args[3];
      if (seg.relative) return Offset(start.dx + x, start.dy + y);
      return Offset(x, y);
    }
    final double x = seg.args[0];
    final double y = seg.args[1];
    if (seg.relative) return Offset(start.dx + x, start.dy + y);
    return Offset(x, y);
  }

  static Offset _reflectQuadControl(
      SvgPathData data,
      SvgPathSegment seg,
      Offset current,
      ) {
    final int idx = data.segments.indexOf(seg);
    if (idx <= 0) return current;
    final SvgPathSegment prev = data.segments[idx - 1];
    if (prev.command != SvgPathCommand.quadraticBezierCurveTo &&
        prev.command != SvgPathCommand.smoothQuadraticBezierCurveTo) {
      return current;
    }
    final Offset start = prev.startPoint ?? Offset.zero;
    double cx;
    double cy;
    if (prev.command == SvgPathCommand.quadraticBezierCurveTo) {
      cx = prev.args[0];
      cy = prev.args[1];
      if (prev.relative) {
        cx += start.dx;
        cy += start.dy;
      }
    } else {
      cx = prev.args[0];
      cy = prev.args[1];
      if (prev.relative) {
        cx += start.dx;
        cy += start.dy;
      }
    }
    return Offset(current.dx * 2 - cx, current.dy * 2 - cy);
  }

  static void _appendArc(
      Path path,
      Offset start,
      Offset end,
      SvgPathSegment seg,
      ) {
    final double rx = seg.args[0].abs();
    final double ry = seg.args[1].abs();
    final double rotationDeg = seg.args[2];
    final bool largeArc = seg.args[3] != 0;
    final bool sweep = seg.args[4] != 0;

    if (rx == 0 || ry == 0 || start == end) {
      path.lineTo(end.dx, end.dy);
      return;
    }

    final double phi = rotationDeg * math.pi / 180.0;
    final double cosPhi = math.cos(phi);
    final double sinPhi = math.sin(phi);

    final double dx2 = (start.dx - end.dx) / 2.0;
    final double dy2 = (start.dy - end.dy) / 2.0;

    final double x1p = cosPhi * dx2 + sinPhi * dy2;
    final double y1p = -sinPhi * dx2 + cosPhi * dy2;

    double rxSq = rx * rx;
    double rySq = ry * ry;
    final double x1pSq = x1p * x1p;
    final double y1pSq = y1p * y1p;

    double radiiCheck = x1pSq / rxSq + y1pSq / rySq;
    double rx2 = rx;
    double ry2 = ry;
    if (radiiCheck > 1) {
      final double scale = math.sqrt(radiiCheck);
      rx2 = rx * scale;
      ry2 = ry * scale;
      rxSq = rx2 * rx2;
      rySq = ry2 * ry2;
    }

    double numerator = rxSq * rySq - rxSq * y1pSq - rySq * x1pSq;
    if (numerator < 0) numerator = 0;
    final double denominator = rxSq * y1pSq + rySq * x1pSq;
    final int sign = largeArc != sweep ? 1 : -1;
    final double coef =
        sign * math.sqrt(denominator == 0 ? 0 : numerator / denominator);

    final double cxp = coef * rx2 * y1p / ry2;
    final double cyp = -coef * ry2 * x1p / rx2;

    final double cx =
        cosPhi * cxp - sinPhi * cyp + (start.dx + end.dx) / 2.0;
    final double cy =
        sinPhi * cxp + cosPhi * cyp + (start.dy + end.dy) / 2.0;

    double ux = (x1p - cxp) / rx2;
    double uy = (y1p - cyp) / ry2;
    double vx = (-x1p - cxp) / rx2;
    double vy = (-y1p - cyp) / ry2;

    double theta1 = _vectorAngle(1, 0, ux, uy);
    double deltaTheta = _vectorAngle(ux, uy, vx, vy);

    if (!sweep && deltaTheta > 0) deltaTheta -= 2 * math.pi;
    if (sweep && deltaTheta < 0) deltaTheta += 2 * math.pi;

    _arcToCubics(
      path,
      cx,
      cy,
      rx2,
      ry2,
      phi,
      theta1,
      deltaTheta,
    );
  }

  static double _vectorAngle(
      double ux,
      double uy,
      double vx,
      double vy,
      ) {
    final double dot = ux * vx + uy * vy;
    final double len = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
    if (len == 0) return 0;
    double a = math.acos((dot / len).clamp(-1.0, 1.0));
    if (ux * vy - uy * vx < 0) a = -a;
    return a;
  }

  static void _arcToCubics(
      Path path,
      double cx,
      double cy,
      double rx,
      double ry,
      double phi,
      double theta1,
      double deltaTheta,
      ) {
    final int segments = (deltaTheta.abs() / (math.pi / 2)).ceil().clamp(1, 8);
    final double delta = deltaTheta / segments;

    double t1 = theta1;

    for (int i = 0; i < segments; i++) {
      final double t2 = t1 + delta;
      _arcSegmentToCubic(path, cx, cy, rx, ry, phi, t1, t2);
      t1 = t2;
    }
  }

  static void _arcSegmentToCubic(
      Path path,
      double cx,
      double cy,
      double rx,
      double ry,
      double phi,
      double t1,
      double t2,
      ) {
    final double alpha = math.sin(t2 - t1) *
        (math.sqrt(4 + 3 * math.pow(math.tan((t2 - t1) / 2), 2)) - 1) /
        3;

    final double cosPhi = math.cos(phi);
    final double sinPhi = math.sin(phi);

    final double x1 = math.cos(t1);
    final double y1 = math.sin(t1);
    final double x2 = math.cos(t2);
    final double y2 = math.sin(t2);

    final double p1x = cosPhi * rx * x1 - sinPhi * ry * y1 + cx;
    final double p1y = sinPhi * rx * x1 + cosPhi * ry * y1 + cy;

    final double p2x = cosPhi * rx * x2 - sinPhi * ry * y2 + cx;
    final double p2y = sinPhi * rx * x2 + cosPhi * ry * y2 + cy;

    final double dx1 = -rx * x1;
    final double dy1 = ry * math.cos(t1);
    final double dx2 = -rx * x2;
    final double dy2 = ry * math.cos(t2);

    final double c1x = p1x + alpha * (cosPhi * dx1 - sinPhi * dy1);
    final double c1y = p1y + alpha * (sinPhi * dx1 + cosPhi * dy1);
    final double c2x = p2x - alpha * (cosPhi * dx2 - sinPhi * dy2);
    final double c2y = p2y - alpha * (sinPhi * dx2 + cosPhi * dy2);

    path.cubicTo(c1x, c1y, c2x, c2y, p2x, p2y);
  }

  static double computeLength(SvgPathData data) {
    final Path path = toFlutterPath(data);
    double total = 0;
    for (final ui.PathMetric m in path.computeMetrics()) {
      total += m.length;
    }
    return total;
  }

  static Rect computeBounds(SvgPathData data) {
    if (data.isEmpty) return Rect.zero;
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    void consider(Offset p) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }

    for (final seg in data.segments) {
      if (seg.startPoint != null) consider(seg.startPoint!);
      if (seg.endPoint != null) consider(seg.endPoint!);
    }

    if (minX == double.infinity) return Rect.zero;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class SvgPathPainter extends CustomPainter {
  SvgPathPainter({
    required this.data,
    required this.options,
    required this.zoom,
    required this.pan,
    this.highlightSegment,
    this.showNodes = true,
    this.showHandles = false,
  });

  final SvgPathData data;
  final SvgPathOptions options;
  final double zoom;
  final Offset pan;
  final int? highlightSegment;
  final bool showNodes;
  final bool showHandles;

  @override
  void paint(Canvas canvas, Size size) {
    if (options.gridVisible) _drawGrid(canvas, size);

    final Rect bounds = SvgPathRenderer.computeBounds(data);
    final Offset center = bounds.center;
    canvas.save();
    canvas.translate(size.width / 2 + pan.dx, size.height / 2 + pan.dy);
    canvas.scale(zoom);
    canvas.translate(-center.dx, -center.dy);

    final Path path = SvgPathRenderer.toFlutterPath(data);

    if (options.fillColor != null) {
      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = options.fillColor!;
      canvas.drawPath(path, fillPaint);
    }

    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = options.strokeColor
      ..strokeWidth = options.strokeWidth / zoom;
    canvas.drawPath(path, strokePaint);

    if (highlightSegment != null &&
        highlightSegment! >= 0 &&
        highlightSegment! < data.segments.length) {
      final SvgPathSegment seg = data.segments[highlightSegment!];
      if (seg.startPoint != null && seg.endPoint != null) {
        final Paint hl = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFC24B)
          ..strokeWidth = (options.strokeWidth + 2) / zoom;
        canvas.drawLine(seg.startPoint!, seg.endPoint!, hl);
      }
    }

    if (showHandles) _drawBezierHandles(canvas);

    if (showNodes && options.showPoints) _drawNodes(canvas);

    canvas.restore();

    if (options.showCommandLabels) _drawLabels(canvas, size, center);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    final Paint axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;

    const double step = 20;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axisPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axisPaint,
    );
  }

  void _drawNodes(Canvas canvas) {
    final double r = 3.0 / zoom;
    final Paint nodeFill = Paint()..color = const Color(0xFF00E5FF);
    final Paint nodeStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / zoom
      ..color = Colors.white;

    for (int i = 0; i < data.segments.length; i++) {
      final SvgPathSegment seg = data.segments[i];
      final Offset? p = seg.endPoint;
      if (p == null) continue;

      final bool isStart = i == 0;
      final bool isEnd = i == data.segments.length - 1;

      Color color = const Color(0xFF00E5FF);
      if (isStart && options.showStartPoint) {
        color = const Color(0xFF4BD68B);
      } else if (isEnd && options.showEndPoint) {
        color = const Color(0xFFFF5C5C);
      }

      nodeFill.color = color;
      canvas.drawCircle(p, r * 2, nodeFill);
      canvas.drawCircle(p, r * 2, nodeStroke);
    }
  }

  void _drawBezierHandles(Canvas canvas) {
    final Paint handleLine = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1 / zoom;
    final Paint handlePoint = Paint()..color = const Color(0xFFFFC24B);

    for (final seg in data.segments) {
      if (seg.startPoint == null || seg.endPoint == null) continue;

      List<Offset> controls = <Offset>[];

      if (seg.command == SvgPathCommand.cubicBezierCurveTo) {
        controls = <Offset>[
          _absCtrl(seg.args, 0, seg.relative, seg.startPoint!),
          _absCtrl(seg.args, 2, seg.relative, seg.startPoint!),
        ];
      } else if (seg.command == SvgPathCommand.quadraticBezierCurveTo) {
        controls = <Offset>[
          _absCtrl(seg.args, 0, seg.relative, seg.startPoint!),
        ];
      }

      for (final c in controls) {
        canvas.drawLine(seg.startPoint!, c, handleLine);
        canvas.drawLine(c, seg.endPoint!, handleLine);
        canvas.drawCircle(c, 2.5 / zoom, handlePoint);
      }
    }
  }

  Offset _absCtrl(List<double> args, int i, bool relative, Offset start) {
    final double x = args[i];
    final double y = args[i + 1];
    if (relative) return Offset(start.dx + x, start.dy + y);
    return Offset(x, y);
  }

  void _drawLabels(Canvas canvas, Size size, Offset center) {
    for (final seg in data.segments) {
      if (seg.endPoint == null) continue;

      final Offset screen = Offset(
        (seg.endPoint!.dx - center.dx) * zoom + size.width / 2 + pan.dx,
        (seg.endPoint!.dy - center.dy) * zoom + size.height / 2 + pan.dy,
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: seg.letter,
          style: const TextStyle(
            color: Color(0xFFFFC24B),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, screen + const Offset(6, -14));
    }
  }

  @override
  bool shouldRepaint(covariant SvgPathPainter old) {
    return old.data != data ||
        old.options != options ||
        old.zoom != zoom ||
        old.pan != pan ||
        old.highlightSegment != highlightSegment ||
        old.showNodes != showNodes ||
        old.showHandles != showHandles;
  }
}