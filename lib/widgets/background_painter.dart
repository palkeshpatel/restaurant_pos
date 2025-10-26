import 'package:flutter/material.dart';
import 'dart:math';

class RestaurantBackgroundPainter extends CustomPainter {
  final bool showPattern;
  final double opacity;

  RestaurantBackgroundPainter({
    this.showPattern = true,
    this.opacity = 0.05,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showPattern) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final circlePaint = Paint()
      ..color = const Color(0xFF4fc3f7).withOpacity(opacity * 2)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Fixed seed for consistent pattern

    // Draw geometric grid pattern
    const double spacing = 80;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Draw connecting lines
        if (x + spacing < size.width + spacing) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + spacing, y),
            paint,
          );
        }
        if (y + spacing < size.height + spacing) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, y + spacing),
            paint,
          );
        }

        // Draw decorative circles at intersections
        if (random.nextDouble() > 0.7) {
          canvas.drawCircle(Offset(x, y), 2 + random.nextDouble() * 3, circlePaint);
        }
      }
    }

    // Draw floating food icons pattern
    final foodIcons = ['🍽️', '🍳', '🍴', '🥄', '🍾', '☕'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final icon = foodIcons[random.nextInt(foodIcons.length)];

      textPainter.text = TextSpan(
        text: icon,
        style: TextStyle(
          fontSize: 16 + random.nextDouble() * 8,
          color: const Color(0xFF4fc3f7).withOpacity(opacity * 3),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class KitchenBackgroundPainter extends CustomPainter {
  final bool showPattern;
  final double opacity;

  KitchenBackgroundPainter({
    this.showPattern = true,
    this.opacity = 0.03,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showPattern) return;

    final paint = Paint()
      ..color = Colors.orange.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final flamePaint = Paint()
      ..color = const Color(0xFFFF6B35).withOpacity(opacity * 2)
      ..style = PaintingStyle.fill;

    // Draw kitchen-themed grid
    const double spacing = 60;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Draw flame-like patterns
        final path = Path();
        path.moveTo(x, y + 20);
        path.quadraticBezierTo(x - 10, y, x, y - 15);
        path.quadraticBezierTo(x + 10, y, x, y + 20);
        canvas.drawPath(path, flamePaint);

        // Draw connecting lines
        if (x + spacing < size.width + spacing) {
          canvas.drawLine(Offset(x, y), Offset(x + spacing, y), paint);
        }
        if (y + spacing < size.height + spacing) {
          canvas.drawLine(Offset(x, y), Offset(x, y + spacing), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TableBackgroundPainter extends CustomPainter {
  final bool showPattern;
  final double opacity;

  TableBackgroundPainter({
    this.showPattern = true,
    this.opacity = 0.04,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showPattern) return;

    final paint = Paint()
      ..color = Colors.green.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final tablePaint = Paint()
      ..color = const Color(0xFF48BB78).withOpacity(opacity * 2)
      ..style = PaintingStyle.fill;

    // Draw table-like circular patterns
    const double spacing = 70;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Draw table circles
        canvas.drawCircle(Offset(x, y), 15, paint);
        canvas.drawCircle(Offset(x, y), 8, tablePaint);

        // Draw chair positions
        const chairPositions = [
          [-20, -20], [20, -20], [-20, 20], [20, 20]
        ];

        for (final pos in chairPositions) {
          canvas.drawCircle(
            Offset(x + pos[0], y + pos[1]),
            4,
            tablePaint,
          );
        }

        // Draw connecting lines between tables
        if (x + spacing < size.width + spacing) {
          canvas.drawLine(Offset(x, y), Offset(x + spacing, y), paint);
        }
        if (y + spacing < size.height + spacing) {
          canvas.drawLine(Offset(x, y), Offset(x, y + spacing), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
