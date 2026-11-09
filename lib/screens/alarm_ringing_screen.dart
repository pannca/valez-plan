import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alarm/alarm.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../theme/app_colors.dart';

class AlarmRingingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  PlanModel? _plan;
  bool _isProcessing = false;

  bool get _isEarlyReminder => widget.alarmSettings.id >= 100000;
  int get _realPlanId => _isEarlyReminder
      ? widget.alarmSettings.id - 100000
      : widget.alarmSettings.id;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadPlanDetails();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPlanDetails() async {
    try {
      final plan = await DatabaseService.instance.getPlanById(_realPlanId);
      if (mounted) {
        setState(() {
          _plan = plan;
        });
      }
    } catch (e) {
      debugPrint('Error loading plan in alarm screen: $e');
    }
  }

  // Opsi 1: Kerjakan (Matikan alarm + checklist selesai)
  Future<void> _handleCompleteNow() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await Alarm.stop(widget.alarmSettings.id);
      if (_isEarlyReminder) {
        await Alarm.stop(_realPlanId);
      }
      await DatabaseService.instance.toggleComplete(_realPlanId, true);

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Agenda selesai dan terceklis.',
                  style: TextStyle(color: AppColors.ink(isDark)),
                ),
              ],
            ),
            backgroundColor: AppColors.surface(isDark),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling complete now: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  // Opsi 2: Nanti Saja (+5 Menit) -> Snooze otomatis majukan jadwal +5 menit & alarm baru
  Future<void> _handleSnooze5Minutes() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // 1. Matikan dering alarm yang sedang aktif
      await Alarm.stop(widget.alarmSettings.id);

      // 2. Ambil data agenda dan tambahkan waktunya 5 menit ke depan
      final plan = _plan ?? await DatabaseService.instance.getPlanById(_realPlanId);
      final newTime = DateTime.now().add(const Duration(minutes: 5));

      if (plan != null) {
        final updatedPlan = plan.copyWith(scheduledTime: newTime);
        await DatabaseService.instance.updatePlan(updatedPlan);

        // 3. Jadwalkan ulang alarm 5 menit ke depan
        await AlarmService.instance.scheduleAlarm(
          id: plan.id!,
          dateTime: newTime,
          title: plan.title,
          notes: plan.notes,
          earlyReminderMinutes: 0, // Alarm tunda langsung tepat waktu
        );
      }

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        Navigator.pop(context);
        final nextTimeStr = DateFormat('HH:mm').format(newTime);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.alarm_add_rounded, color: AppColors.accent(isDark), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ditunda 5 menit (berikutnya $nextTimeStr)',
                    style: TextStyle(color: AppColors.ink(isDark)),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surface(isDark),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling snooze 5m: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  // Opsi 3: Hentikan Alarm
  Future<void> _handleStopAlarm() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, color: AppColors.muted(isDark), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Alarm dimatikan.',
                  style: TextStyle(color: AppColors.ink(isDark)),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface(isDark),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawTitle = _plan?.title ?? widget.alarmSettings.notificationSettings.title;
    final cleanTitle = rawTitle.replaceAll('⏰ ValezPlan: ', '').replaceAll('⏰ ', '');
    final notes = _plan?.notes ?? widget.alarmSettings.notificationSettings.body;
    final category = _plan?.category ?? 'Umum';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bg(isDark);
    final surface = AppColors.surface(isDark);
    final surfaceSubtle = AppColors.surfaceSubtle(isDark);
    final border = AppColors.border(isDark);
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final accentColor = AppColors.accent(isDark);
    final timeStr = _plan != null
        ? DateFormat('HH:mm').format(_plan!.scheduledTime)
        : DateFormat('HH:mm').format(DateTime.now());

    return PopScope(
      canPop: false, // Mencegah back gesture tanpa memilih aksi
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          const Spacer(flex: 1),

                          // Ripple & Pulsing Alarm Icon (Pusat Animasi Selaras)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              final scale = _pulseAnimation.value;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ripple wave
                                  Container(
                                    width: 104 * scale,
                                    height: 104 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accentColor.withValues(alpha: isDark ? 0.08 : 0.06),
                                    ),
                                  ),
                                  // Middle ripple wave
                                  Container(
                                    width: 84 * scale,
                                    height: 84 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: isDark ? 0.25 : 0.20),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  // Center icon container
                                  Container(
                                    width: 66,
                                    height: 66,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: surface,
                                      border: Border.all(
                                        color: AppColors.accentBorder(isDark),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isEarlyReminder
                                          ? Icons.hourglass_top_rounded
                                          : Icons.alarm_on_rounded,
                                      size: 32,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),

                          // Central Ambient Briefing Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: border,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Jam Jadwal
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                    color: textMain,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Kategori Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: surfaceSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        AppColors.categoryIcon(category),
                                        size: 13,
                                        color: AppColors.categoryTone(category, isDark),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: textMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),
                                Divider(
                                  color: border.withValues(alpha: 0.8),
                                  height: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 18),

                                // Judul Agenda
                                Text(
                                  cleanTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textMain,
                                    height: 1.3,
                                  ),
                                ),

                                // Catatan Agenda jika ada
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: surfaceSubtle.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: border.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.notes_rounded,
                                            size: 15,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            notes,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: textMuted,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const Spacer(flex: 2),

                          // === AKSI SAAT ALARM BERBUNYI ===
                          if (_isEarlyReminder) ...[
                            // Opsi untuk Pengingat Persiapan
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isProcessing ? null : _handleStopAlarm,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, size: 20, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Saya Siap (Matikan Pengingat)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            // 1. TOMBOL UTAMA: Kerjakan Sekarang (Full Width)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isProcessing ? null : _handleCompleteNow,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Kerjakan Sekarang',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. DUA TOMBOL SEKUNDER BERDAMPINGAN: Tunda 5m & Matikan
                            Row(
                              children: [
                                // Tombol Tunda 5 Menit
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: border, width: 1),
                                        backgroundColor: surface,
                                        foregroundColor: textMain,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _isProcessing ? null : _handleSnooze5Minutes,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.update_rounded, size: 18, color: accentColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Tunda 5m',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: textMain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Tombol Matikan Alarm
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppColors.danger.withValues(alpha: isDark ? 0.35 : 0.45),
                                          width: 1,
                                        ),
                                        backgroundColor: surface,
                                        foregroundColor: AppColors.danger,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _isProcessing ? null : _handleStopAlarm,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                                          SizedBox(width: 6),
                                          Text(
                                            'Matikan',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
