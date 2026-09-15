import 'dart:ui';

enum SvgPathCommand {
  moveTo,
  lineTo,
  horizontalLineTo,
  verticalLineTo,
  cubicBezierCurveTo,
  smoothCubicBezierCurveTo,
  quadraticBezierCurveTo,
  smoothQuadraticBezierCurveTo,
  ellipticalArc,
  closePath,
}

extension SvgPathCommandX on SvgPathCommand {
  String get letter {
    switch (this) {
      case SvgPathCommand.moveTo:
        return 'M';
      case SvgPathCommand.lineTo:
        return 'L';
      case SvgPathCommand.horizontalLineTo:
        return 'H';
      case SvgPathCommand.verticalLineTo:
        return 'V';
      case SvgPathCommand.cubicBezierCurveTo:
        return 'C';
      case SvgPathCommand.smoothCubicBezierCurveTo:
        return 'S';
      case SvgPathCommand.quadraticBezierCurveTo:
        return 'Q';
      case SvgPathCommand.smoothQuadraticBezierCurveTo:
        return 'T';
      case SvgPathCommand.ellipticalArc:
        return 'A';
      case SvgPathCommand.closePath:
        return 'Z';
    }
  }

  int get argumentCount {
    switch (this) {
      case SvgPathCommand.moveTo:
        return 2;
      case SvgPathCommand.lineTo:
        return 2;
      case SvgPathCommand.horizontalLineTo:
        return 1;
      case SvgPathCommand.verticalLineTo:
        return 1;
      case SvgPathCommand.cubicBezierCurveTo:
        return 6;
      case SvgPathCommand.smoothCubicBezierCurveTo:
        return 4;
      case SvgPathCommand.quadraticBezierCurveTo:
        return 4;
      case SvgPathCommand.smoothQuadraticBezierCurveTo:
        return 2;
      case SvgPathCommand.ellipticalArc:
        return 7;
      case SvgPathCommand.closePath:
        return 0;
    }
  }
}

class SvgPathSegment {
  SvgPathSegment({
    required this.command,
    required this.args,
    required this.relative,
    this.startPoint,
    this.endPoint,
  });

  final SvgPathCommand command;
  final List<double> args;
  final bool relative;
  final Offset? startPoint;
  final Offset? endPoint;

  String get letter => relative ? command.letter.toLowerCase() : command.letter;

  String toPathString() {
    final StringBuffer b = StringBuffer(letter);
    for (final double a in args) {
      b.write(' ');
      b.write(_formatNumber(a));
    }
    return b.toString();
  }

  static String _formatNumber(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toString();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'cmd': letter,
    'args': args,
    if (startPoint != null) 'start': [startPoint!.dx, startPoint!.dy],
    if (endPoint != null) 'end': [endPoint!.dx, endPoint!.dy],
  };

  @override
  String toString() => toPathString();
}

class SvgPathData {
  SvgPathData(this.segments);

  final List<SvgPathSegment> segments;

  String get originalPath => segments.map((s) => s.toPathString()).join(' ');

  String get normalizedPath {
    final StringBuffer b = StringBuffer();
    for (final s in segments) {
      b.write(s.letter);
      for (final a in s.args) {
        b.write(_fmt(a));
      }
    }
    return b.toString();
  }

  String get spacedPath => segments.map((s) => s.toPathString()).join(' ');

  static String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toString();
  }

  double get approximateLength {
    double total = 0;
    for (final s in segments) {
      if (s.startPoint != null && s.endPoint != null) {
        total += (s.endPoint! - s.startPoint!).distance;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> toJson() =>
      segments.map((s) => s.toJson()).toList();

  bool get isEmpty => segments.isEmpty;
  bool get isNotEmpty => segments.isNotEmpty;

  SvgPathData clone() => SvgPathData(
    segments
        .map((s) => SvgPathSegment(
      command: s.command,
      args: List<double>.of(s.args),
      relative: s.relative,
      startPoint: s.startPoint,
      endPoint: s.endPoint,
    ))
        .toList(),
  );
}

class SvgPathOptions {
  const SvgPathOptions({
    this.strokeColor = const Color(0xFF7C4DFF),
    this.strokeWidth = 2.0,
    this.fillColor,
    this.showPoints = true,
    this.showStartPoint = true,
    this.showEndPoint = true,
    this.showCommandLabels = false,
    this.gridVisible = true,
    this.backgroundColor = const Color(0xFF0F0B24),
  });

  final Color strokeColor;
  final double strokeWidth;
  final Color? fillColor;
  final bool showPoints;
  final bool showStartPoint;
  final bool showEndPoint;
  final bool showCommandLabels;
  final bool gridVisible;
  final Color backgroundColor;

  SvgPathOptions copyWith({
    Color? strokeColor,
    double? strokeWidth,
    Color? fillColor,
    bool? showPoints,
    bool? showStartPoint,
    bool? showEndPoint,
    bool? showCommandLabels,
    bool? gridVisible,
    Color? backgroundColor,
  }) {
    return SvgPathOptions(
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fillColor: fillColor ?? this.fillColor,
      showPoints: showPoints ?? this.showPoints,
      showStartPoint: showStartPoint ?? this.showStartPoint,
      showEndPoint: showEndPoint ?? this.showEndPoint,
      showCommandLabels: showCommandLabels ?? this.showCommandLabels,
      gridVisible: gridVisible ?? this.gridVisible,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}