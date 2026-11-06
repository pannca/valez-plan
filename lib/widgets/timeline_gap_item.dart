import 'package:flutter/material.dart';

class TimelineGapItem extends StatelessWidget {
  final Duration duration;

  const TimelineGapItem({super.key, required this.duration});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    if (hours > 0 && mins > 0) {
      return '$hours jam $mins mnt waktu luang';
    } else if (hours > 0) {
      return '$hours jam waktu luang';
    } else {
      return '$mins mnt waktu luang';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 44),
          const SizedBox(width: 12),
          // Garis putus-putus kecil di tengah
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 2,
                height: 28,
                color: const Color(0xFF2D3436),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Pill Info Waktu Luang
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3436).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDuration(duration),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF808E9B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

