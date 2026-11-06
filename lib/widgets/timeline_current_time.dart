import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF5252),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Titik Merah Indikator Waktu
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF5252),
            ),
          ),
          const SizedBox(width: 6),

          // Garis Merah Penunjuk Jam Sekarang
          Expanded(
            child: Container(
              height: 1.5,
              color: const Color(0xFFFF5252),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SEKARANG',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Color(0xFFFF5252),
            ),
          ),
        ],
      ),
    );
  }
}

