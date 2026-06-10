import 'dart:math' as math;

import 'package:flutter/material.dart';

class MiniTrendChart extends StatelessWidget {
  const MiniTrendChart({
    required this.values,
    required this.label,
    this.color,
    this.height = 96,
    super.key,
  });

  final List<double> values;
  final String label;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = values.isEmpty
        ? ''
        : '${values.reduce(math.min).round()}-${values.reduce(math.max).round()}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (range.isNotEmpty)
                  Text(
                    range,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  values: values,
                  color: color ?? theme.colorScheme.primary,
                  gridColor: theme.colorScheme.outlineVariant,
                  fillColor: (color ?? theme.colorScheme.primary).withValues(
                    alpha: .10,
                  ),
                ),
              ),
            ),
            if (values.length >= 2) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '14 天前',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '今天',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(10, 6, size.width - 20, size.height - 12);
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i += 1) {
      final y = chartRect.top + chartRect.height * i / 3;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    if (values.length < 2) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = math.max(1, maxValue - minValue);

    Offset pointAt(int index) {
      final x = chartRect.left + chartRect.width * index / (values.length - 1);
      final normalized = (values[index] - minValue) / span;
      final y = chartRect.bottom - normalized * chartRect.height;
      return Offset(x, y);
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i += 1) {
      final point = pointAt(i);
      line.lineTo(point.dx, point.dy);
    }

    final fill = Path.from(line)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < values.length; i += 1) {
      canvas.drawCircle(pointAt(i), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return values != oldDelegate.values ||
        color != oldDelegate.color ||
        gridColor != oldDelegate.gridColor ||
        fillColor != oldDelegate.fillColor;
  }
}
