import 'package:flutter/material.dart';

class StatusCountWidget extends StatelessWidget {
  final int holdCount;
  final int fireCount;

  const StatusCountWidget({
    super.key,
    required this.holdCount,
    required this.fireCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildStatusCount('Hold', holdCount, Colors.orange.shade600, Icons.pause_circle_outline),
          const SizedBox(height: 12),
          _buildStatusCount('Fire', fireCount, Colors.red.shade600, Icons.local_fire_department),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
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
      ),
    );
  }
}