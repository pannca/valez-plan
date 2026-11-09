import 'package:flutter/foundation.dart';
import '../models/plan_model.dart';
import 'database_service.dart';

class ToleranceService {
  static final ToleranceService instance = ToleranceService._init();
  ToleranceService._init();

  static const int defaultToleranceMinutes = 60;

  // Nilai toleransi dalam menit: 30, 60, 120, atau -1 (akhir hari)
  final ValueNotifier<int> toleranceMinutesNotifier =
      ValueNotifier<int>(defaultToleranceMinutes);

  int get toleranceMinutes => toleranceMinutesNotifier.value;

  Future<void> init() async {
    try {
      final saved = await DatabaseService.instance.getSetting('tolerance_minutes');
      if (saved != null) {
        final parsed = int.tryParse(saved);
        if (parsed != null) {
          toleranceMinutesNotifier.value = parsed;
        }
      }
    } catch (e) {
      debugPrint('Error loading tolerance minutes: $e');
    }
  }

  Future<void> setTolerance(int minutes) async {
    toleranceMinutesNotifier.value = minutes;
    await DatabaseService.instance.setSetting('tolerance_minutes', minutes.toString());
  }

  /// Memeriksa apakah batas waktu jadwal + toleransi sudah lewat dari waktu sekarang.
  bool isPastToleranceDeadline(DateTime scheduledTime) {
    final now = DateTime.now();
    if (toleranceMinutesNotifier.value == -1) {
      // Toleransi akhir hari (sampai 23:59:59 hari jadwal tersebut)
      final endOfDay = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day, 23, 59, 59);
      return now.isAfter(endOfDay);
    }

    final deadline = scheduledTime.add(Duration(minutes: toleranceMinutesNotifier.value));
    return now.isAfter(deadline);
  }

  /// Memeriksa apakah suatu jadwal sudah terlewat batas toleransi (belum dikerjakan & lewat deadline)
  bool isPlanExpired(PlanModel plan) {
    if (plan.isCompleted) return false;
    return isPastToleranceDeadline(plan.scheduledTime);
  }
}
