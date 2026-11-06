import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class SystemPermissionStatus {
  final bool isNotificationGranted;
  final bool isExactAlarmGranted;
  final bool isBatteryOptimizationIgnored;

  const SystemPermissionStatus({
    this.isNotificationGranted = true,
    this.isExactAlarmGranted = true,
    this.isBatteryOptimizationIgnored = true,
  });

  bool get hasAnyIssue =>
      !isNotificationGranted ||
      !isExactAlarmGranted ||
      !isBatteryOptimizationIgnored;

  int get issueCount {
    int count = 0;
    if (!isNotificationGranted) count++;
    if (!isExactAlarmGranted) count++;
    if (!isBatteryOptimizationIgnored) count++;
    return count;
  }
}

class SystemPermissionService {
  static final SystemPermissionService instance =
      SystemPermissionService._init();
  SystemPermissionService._init();

  final ValueNotifier<SystemPermissionStatus> statusNotifier =
      ValueNotifier<SystemPermissionStatus>(const SystemPermissionStatus());

  SystemPermissionStatus get currentStatus => statusNotifier.value;

  // Cek seluruh status izin sistem HP
  Future<SystemPermissionStatus> checkPermissions() async {
    if (kIsWeb) {
      statusNotifier.value = const SystemPermissionStatus();
      return statusNotifier.value;
    }

    try {
      final notifStatus = await Permission.notification.status;
      final isNotificationGranted = notifStatus.isGranted;

      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      final isExactAlarmGranted = exactAlarmStatus.isGranted;

      final batteryStatus =
          await Permission.ignoreBatteryOptimizations.status;
      final isBatteryOptimizationIgnored = batteryStatus.isGranted;

      final newStatus = SystemPermissionStatus(
        isNotificationGranted: isNotificationGranted,
        isExactAlarmGranted: isExactAlarmGranted,
        isBatteryOptimizationIgnored: isBatteryOptimizationIgnored,
      );

      statusNotifier.value = newStatus;
      return newStatus;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return statusNotifier.value;
    }
  }

  // Minta izin Notifikasi
  Future<bool> requestNotification() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.request();
    await checkPermissions();
    return status.isGranted;
  }

  // Minta izin Alarm Presisi (Android 12+)
  Future<bool> requestExactAlarm() async {
    if (kIsWeb) return true;
    final status = await Permission.scheduleExactAlarm.request();
    await checkPermissions();
    return status.isGranted;
  }

  // Minta pengecualian Penghemat Baterai (Doze / Battery Optimization)
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (kIsWeb) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    await checkPermissions();
    return status.isGranted;
  }

  // Buka halaman Pengaturan Aplikasi di Sistem HP
  Future<bool> openAppSettingsPage() async {
    if (kIsWeb) return true;
    final res = await openAppSettings();
    await checkPermissions();
    return res;
  }
}
