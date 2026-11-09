import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class TimelineCurrentTimeIndicator extends StatefulWidget {
  const TimelineCurrentTimeIndicator({super.key});

  @override
  State<TimelineCurrentTimeIndicator> createState() =>
      _TimelineCurrentTimeIndicatorState();
}

class _TimelineCurrentTimeIndicatorState
    extends State<TimelineCurrentTimeIndicator> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(_now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppColors.accent(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Jam Sekarang di Kiri
          SizedBox(
            width: 44,
            child: Text(
              timeStr,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accentColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Titik Indikator Waktu
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 6),

          // Garis Penunjuk Jam Sekarang
          Expanded(
            child: Container(
              height: 1.5,
              color: accentColor.withValues(alpha: isDark ? 0.45 : 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SEKARANG',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
