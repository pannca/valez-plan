import 'package:flutter/material.dart';
import '../services/system_permission_service.dart';
import '../theme/app_colors.dart';

class PermissionWarningSheet extends StatefulWidget {
  const PermissionWarningSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PermissionWarningSheet(),
    );
  }

  @override
  State<PermissionWarningSheet> createState() => _PermissionWarningSheetState();
}

class _PermissionWarningSheetState extends State<PermissionWarningSheet>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemPermissionService.instance.checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh status ketika kembali dari pengaturan HP
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemPermissionService.instance.checkPermissions();
    }
  }

  Widget _buildPermissionItem({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
    required Color cardBg,
    required Color borderColor,
    required Color textMain,
    required Color textMuted,
  }) {
    final statusColor = isGranted ? AppColors.success : AppColors.warning;
    final accentColor = AppColors.accent(isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? borderColor
              : AppColors.statusBorder(AppColors.warning, isDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.statusSoft(statusColor, isDark),
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : icon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.statusSoft(statusColor, isDark),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted ? 'AKTIF' : 'BELUM AKTIF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: textMuted, height: 1.3),
                ),
                if (!isGranted) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onRequest,
                      child: const Text(
                        'Aktifkan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.surface(isDark);
    final cardBg = AppColors.bg(isDark);
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final borderColor = AppColors.border(isDark);
    final accentColor = AppColors.accent(isDark);

    return ValueListenableBuilder<SystemPermissionStatus>(
      valueListenable: SystemPermissionService.instance.statusNotifier,
      builder: (context, status, _) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusSoft(AppColors.warning, isDark),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Izin Sistem',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                        Text(
                          'Diperlukan agar alarm berdering saat layar mati',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: textMuted, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Daftar Izin
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      context: context,
                      isDark: isDark,
                      title: 'Notifikasi',
                      description:
                          'Menampilkan alarm dan pengingat di layar HP.',
                      icon: Icons.notifications_active_rounded,
                      isGranted: status.isNotificationGranted,
                      onRequest: () =>
                          SystemPermissionService.instance.requestNotification(),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textMain: textMain,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 10),
                    _buildPermissionItem(
                      context: context,
                      isDark: isDark,
                      title: 'Alarm Presisi',
                      description:
                          'Memastikan alarm berdering tepat waktu tanpa delay.',
                      icon: Icons.alarm_rounded,
                      isGranted: status.isExactAlarmGranted,
                      onRequest: () =>
                          SystemPermissionService.instance.requestExactAlarm(),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textMain: textMain,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 10),
                    _buildPermissionItem(
                      context: context,
                      isDark: isDark,
                      title: 'Optimasi Baterai',
                      description:
                          'Mencegah sistem mematikan alarm saat HP sleep.',
                      icon: Icons.battery_charging_full_rounded,
                      isGranted: status.isBatteryOptimizationIgnored,
                      onRequest: () => SystemPermissionService.instance
                          .requestIgnoreBatteryOptimization(),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textMain: textMain,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 14),

                    // Tips Khusus Xiaomi / MIUI
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentBorder(isDark),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengguna MIUI / HyperOS:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Aktifkan opsi "Mulai Otomatis"\n• Hemat baterai: pilih "Tidak Ada Pembatasan"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Tombol Buka Pengaturan HP Lengkap
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      SystemPermissionService.instance.openAppSettingsPage(),
                  icon: const Icon(Icons.settings_rounded, size: 20),
                  label: const Text(
                    'Buka Pengaturan HP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    status.hasAnyIssue ? 'Tutup' : 'Selesai',
                    style: TextStyle(
                      color: textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

