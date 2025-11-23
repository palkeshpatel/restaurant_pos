import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/order_item.dart';

class StatusCountWidget extends StatefulWidget {
  final int holdCount;
  final int fireCount;
  final List<OrderItem>? holdItems;
  final List<OrderItem>? fireItems;
  final Function(OrderItem)? onItemMovedToFire;

  const StatusCountWidget({
    super.key,
    required this.holdCount,
    required this.fireCount,
    this.holdItems,
    this.fireItems,
    this.onItemMovedToFire,
  });

  @override
  State<StatusCountWidget> createState() => _StatusCountWidgetState();
}

class _StatusCountWidgetState extends State<StatusCountWidget>
    with SingleTickerProviderStateMixin {
  bool _showExplosion = false;
  late AnimationController _explosionController;
  late Animation<double> _explosionAnimation;

  @override
  void initState() {
    super.initState();
    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _explosionAnimation = CurvedAnimation(
      parent: _explosionController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _explosionController.dispose();
    super.dispose();
  }

  void _triggerExplosion() {
    setState(() {
      _showExplosion = true;
    });
    _explosionController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _showExplosion = false;
          });
          _explosionController.reset();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Order Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              _buildDraggableStatusCount(
                'Hold',
                widget.holdCount,
                Colors.orange.shade600,
                Icons.pause_circle_outline,
                widget.holdItems ?? [],
              ),
              const SizedBox(height: 12),
              _buildDropTargetStatusCount(
                'Fire',
                widget.fireCount,
                Colors.red.shade600,
                Icons.local_fire_department,
                widget.fireItems ?? [],
              ),
            ],
          ),
        ),
        if (_showExplosion)
          Positioned.fill(
            child: IgnorePointer(
              child: _buildExplosionAnimation(),
            ),
          ),
      ],
    );
  }

  Widget _buildDraggableStatusCount(
    String label,
    int count,
    Color color,
    IconData icon,
    List<OrderItem> items,
  ) {
    return DragTarget<OrderItem>(
      onAccept: (item) {
        // Item was dropped here, but we want to prevent dropping on Hold
        // This is just for visual feedback
      },
      onWillAccept: (data) => false, // Don't accept drops on Hold
      builder: (context, candidateData, rejectedData) {
        return _buildStatusCountCard(label, count, color, icon, items, isDraggable: true);
      },
    );
  }

  Widget _buildDropTargetStatusCount(
    String label,
    int count,
    Color color,
    IconData icon,
    List<OrderItem> items,
  ) {
    return DragTarget<OrderItem>(
      onAccept: (item) {
        _triggerExplosion();
        if (widget.onItemMovedToFire != null) {
          widget.onItemMovedToFire!(item);
        }
      },
      onWillAccept: (data) => true,
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: _buildStatusCountCard(
            label,
            count,
            color,
            icon,
            items,
            isDropTarget: true,
            isHighlighted: candidateData.isNotEmpty,
          ),
        );
      },
    );
  }

  Widget _buildStatusCountCard(
    String label,
    int count,
    Color color,
    IconData icon,
    List<OrderItem> items, {
    bool isDraggable = false,
    bool isDropTarget = false,
    bool isHighlighted = false,
  }) {
    return Card(
      elevation: isHighlighted ? 8 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? BorderSide(color: color, width: 3)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isHighlighted ? color.withOpacity(0.1) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isDraggable && items.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...items.take(3).map((item) => Draggable<OrderItem>(
                      data: item,
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restaurant_menu, size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 6),
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_handle, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                if (items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${items.length - 3} more',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplosionAnimation() {
    return AnimatedBuilder(
      animation: _explosionAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ExplosionPainter(_explosionAnimation.value),
          child: Container(),
        );
      },
    );
  }
}

class ExplosionPainter extends CustomPainter {
  final double progress;

  ExplosionPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.8;
    final radius = maxRadius * progress;

    // Draw multiple explosion particles
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Main explosion circle
    paint.color = Colors.red.withOpacity(0.3 * (1 - progress));
    canvas.drawCircle(center, radius, paint);

    // Explosion particles
    final particleCount = 12;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * 3.14159) / particleCount;
      final distance = radius * 0.7;
      final x = center.dx + distance * (1 + progress) * math.cos(angle);
      final y = center.dy + distance * (1 + progress) * math.sin(angle);

      paint.color = Colors.orange.withOpacity(0.8 * (1 - progress));
      canvas.drawCircle(Offset(x, y), 8 * (1 - progress), paint);
    }

    // Fire emoji effect
    if (progress > 0.3 && progress < 0.7) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '🔥',
          style: TextStyle(
            fontSize: 60 * progress,
            color: Colors.red,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(ExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}