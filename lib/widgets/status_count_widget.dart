import 'package:flutter/material.dart';

class StatusCountWidget extends StatelessWidget {
  final int holdCount;
  final int kitchenCount;
  final int servedCount;

  const StatusCountWidget({
    super.key,
    required this.holdCount,
    required this.kitchenCount,
    required this.servedCount,
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
          _buildStatusCount('Hold', holdCount, Colors.orange),
          const SizedBox(height: 12),
          _buildStatusCount('In Kitchen', kitchenCount, Colors.red),
          const SizedBox(height: 12),
          _buildStatusCount('Served', servedCount, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}