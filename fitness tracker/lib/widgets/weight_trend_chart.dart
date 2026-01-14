import 'dart:math';
import 'package:flutter/material.dart';
import '../models/weight_entry.dart';

class WeightTrendChart extends StatelessWidget {
  final List<WeightEntry> entriesInKg; // sorted newest-first is OK
  final String unit; // 'kg' | 'lb'

  const WeightTrendChart({
    super.key,
    required this.entriesInKg,
    required this.unit,
  });

  double _kgToDisplay(double kg) => unit == 'lb' ? kg * 2.2046226218 : kg;
  String get _unitLabel => unit == 'lb' ? 'lb' : 'kg';

  @override
  Widget build(BuildContext context) {
    // last 30 days (inclusive)
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
    final points = entriesInKg
        .where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(start);
    })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // draw left->right

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CustomPaint(
        painter: _WeightTrendPainter(
          points: points,
          toDisplay: _kgToDisplay,
          unitLabel: _unitLabel,
          startDay: start,
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  final List<WeightEntry> points; // ascending by date
  final double Function(double kg) toDisplay;
  final String unitLabel;
  final DateTime startDay;

  _WeightTrendPainter({
    required this.points,
    required this.toDisplay,
    required this.unitLabel,
    required this.startDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintAxis = Paint()
      ..color = const Color(0xFFBBBBBB)
      ..strokeWidth = 1.0;
    final paintLine = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final paintFill = Paint()
      ..color = const Color(0x332196F3)
      ..style = PaintingStyle.fill;

    final padding = 28.0;
    final chart = Rect.fromLTWH(
      padding, padding / 2, size.width - padding * 1.5, size.height - padding * 1.7,
    );

    // Axes
    // y-axis left
    canvas.drawLine(Offset(chart.left, chart.top), Offset(chart.left, chart.bottom), paintAxis);
    // x-axis bottom
    canvas.drawLine(Offset(chart.left, chart.bottom), Offset(chart.right, chart.bottom), paintAxis);

    final tp = (String text, Offset at, {bool small = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: const Color(0xFF777777),
            fontSize: small ? 10 : 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at);
    };

    // Prepare series
    final days = 30;
    final xs = <double>[];
    final ys = <double>[];
    for (final e in points) {
      final dayIdx = DateTime(e.date.year, e.date.month, e.date.day)
          .difference(startDay)
          .inDays
          .clamp(0, days - 1);
      xs.add(dayIdx.toDouble());
      ys.add(toDisplay(e.weight));
    }

    if (xs.isEmpty) {
      tp('No data (30d)', Offset(chart.left, chart.top - 4));
      tp('0 $unitLabel', Offset(chart.left + 4, chart.top + 4));
      return;
    }

    final minY = ys.reduce(min);
    final maxY = ys.reduce(max);
    // add small padding
    final pad = (maxY - minY).abs() < 0.0001 ? max(1.0, maxY.abs() * 0.1) : (maxY - minY) * 0.1;
    final y0 = minY - pad;
    final y1 = maxY + pad;

    // y labels (min, mid, max)
    tp('${y1.toStringAsFixed(1)} $unitLabel', Offset(chart.right + 4, chart.top - 8), small: true);
    tp('${((y0 + y1) / 2).toStringAsFixed(1)} $unitLabel', Offset(chart.right + 4, chart.center.dy - 6), small: true);
    tp('${y0.toStringAsFixed(1)} $unitLabel', Offset(chart.right + 4, chart.bottom - 8), small: true);

    // x labels: start, mid, end
    tp('−29d', Offset(chart.left - 10, chart.bottom + 4), small: true);
    tp('−15d', Offset(chart.left + chart.width / 2 - 10, chart.bottom + 4), small: true);
    tp('Today', Offset(chart.right - 30, chart.bottom + 4), small: true);

    // Build path
    Path path = Path();
    for (var i = 0; i < xs.length; i++) {
      final xNorm = xs[i] / (days - 1);
      final yNorm = (ys[i] - y0) / (y1 - y0);
      final dx = chart.left + xNorm * chart.width;
      final dy = chart.bottom - yNorm * chart.height;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    // Fill area under line
    final fill = Path.from(path)
      ..lineTo(chart.left + (xs.last / (days - 1)) * chart.width, chart.bottom)
      ..lineTo(chart.left + (xs.first / (days - 1)) * chart.width, chart.bottom)
      ..close();
    canvas.drawPath(fill, paintFill);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter old) {
    return old.points != points || old.unitLabel != unitLabel || old.startDay != startDay;
  }
}
