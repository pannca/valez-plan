import 'package:flutter/material.dart';
import '../services/system_permission_service.dart';

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? borderColor : const Color(0xFFFF9F43).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGranted
                  ? const Color(0xFF1DD1A1).withValues(alpha: 0.15)
                  : const Color(0xFFFF9F43).withValues(alpha: 0.15),
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : icon,
              color: isGranted ? const Color(0xFF1DD1A1) : const Color(0xFFFF9F43),
              size: 22,
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
                        color: isGranted
                            ? const Color(0xFF1DD1A1).withValues(alpha: 0.15)
                            : const Color(0xFFFF9F43).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGranted ? 'AKTIF' : 'BELUM AKTIF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isGranted
                              ? const Color(0xFF1DD1A1)
                              : const Color(0xFFFF9F43),
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
                        backgroundColor: const Color(0xFF388AF6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onRequest,
                      child: const Text(
                        'Aktifkan Izin',
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
    final bg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF14171A) : const Color(0xFFF7F9FC);
    final textMain = isDark ? Colors.white : const Color(0xFF2D3748);
    final textMuted = isDark ? const Color(0xFF808E9B) : const Color(0xFF718096);
    final borderColor = isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0);

    return ValueListenableBuilder<SystemPermissionStatus>(
      valueListenable: SystemPermissionService.instance.statusNotifier,
      builder: (context, status, _) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: const Color(0xFFFF9F43).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Color(0xFFFF9F43),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optimalkan Pengaturan HP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                        Text(
                          'Agar alarm tidak terblokir saat HP terkunci',
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
                      title: 'Izin Notifikasi',
                      description:
                          'Wajib agar layar alarm weker dan pengingat waktu persiapan bisa muncul di layar HP.',
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
                      title: 'Izin Alarm Presisi (Exact)',
                      description:
                          'Memastikan alarm berdering tepat di detik dan menit yang ditentukan tanpa ditunda Android.',
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
                      title: 'Bebaskan dari Penghemat Baterai',
                      description:
                          'Mencegah sistem Android mematikan proses ValezPlan saat HP sedang sleep/layar mati.',
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
                        color: const Color(0xFF388AF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF388AF6).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFF388AF6),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips Khusus Xiaomi / Redmi / MIUI:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Di menu Pengaturan Aplikasi HP kamu, pastikan:\n'
                                  '• Aktifkan opsi "Mulai Otomatis" (Autostart)\n'
                                  '• Penghemat baterai: pilih "Tidak Ada Pembatasan"',
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
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388AF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () =>
                      SystemPermissionService.instance.openAppSettingsPage(),
                  icon: const Icon(Icons.settings_rounded, size: 20),
                  label: const Text(
                    'Buka Pengaturan Aplikasi HP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    status.hasAnyIssue ? 'Tutup Sementara' : 'Selesai, Semua Izin Siap!',
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
