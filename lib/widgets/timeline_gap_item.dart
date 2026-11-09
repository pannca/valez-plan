import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TimelineGapItem extends StatelessWidget {
  final Duration duration;

  const TimelineGapItem({super.key, required this.duration});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    if (hours > 0 && mins > 0) {
      return '$hours j $mins m jeda';
    } else if (hours > 0) {
      return '$hours jam jeda';
    } else {
      return '$mins mnt jeda';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = AppColors.border(isDark);
    final mutedColor = AppColors.muted(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 44),
          const SizedBox(width: 12),
          // Garis vertikal penghubung di tengah
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 2,
                height: 28,
                color: borderColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Pill Info Waktu Luang
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle(isDark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

