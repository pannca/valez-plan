import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alarm/alarm.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';

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
  bool _isLoadingPlan = true;
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

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.1).animate(
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
          _isLoadingPlan = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading plan in alarm screen: $e');
      if (mounted) {
        setState(() => _isLoadingPlan = false);
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kerja':
        return const Color(0xFF388AF6);
      case 'belajar':
        return const Color(0xFFA259FF);
      case 'ibadah':
        return const Color(0xFF1DD1A1);
      case 'istirahat':
        return const Color(0xFFFF9F43);
      case 'santai':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFF54A0FF);
    }
  }

  // Opsi 1: Kerjakan (Matikan alarm + checklist selesai)
  Future<void> _handleCompleteNow() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await Alarm.stop(widget.alarmSettings.id);
      await DatabaseService.instance.toggleComplete(_realPlanId, true);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Bagus sekali! Agenda telah diselesaikan.'),
              ],
            ),
            backgroundColor: Color(0xFF1DD1A1),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
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
        Navigator.pop(context);
        final nextTimeStr = DateFormat('HH:mm').format(newTime);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.alarm_add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Jadwal ditunda +5 menit (Alarm berikutnya: $nextTimeStr)'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF388AF6),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Alarm dihentikan. Masuk ke Riwayat (Terlewat), masih bisa kamu centang di Timeline hari ini.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF242C34),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _plan?.title ?? widget.alarmSettings.notificationSettings.title;
    final notes = _plan?.notes ?? widget.alarmSettings.notificationSettings.body;
    final category = _plan?.category ?? 'Umum';
    final categoryColor = _getCategoryColor(category);
    final accentColor = _isEarlyReminder ? const Color(0xFF388AF6) : const Color(0xFFFF9F43);
    final timeStr = _plan != null
        ? DateFormat('HH:mm').format(_plan!.scheduledTime)
        : DateFormat('HH:mm').format(DateTime.now());

    return PopScope(
      canPop: false, // Mencegah back gesture tanpa memilih aksi
      child: Scaffold(
        backgroundColor: const Color(0xFF0F141C),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Icon Alarm dengan Efek Animasi Gelombang Berdenyut
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isEarlyReminder
                          ? Icons.hourglass_top_rounded
                          : Icons.alarm_on_rounded,
                      size: 64,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Badge Pengingat Persiapan vs Alarm Utama
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isEarlyReminder
                        ? '⏳ PENGINGAT PERSIAPAN (10 MENIT LAGI)'
                        : '⏰ WAKTUNYA MEMULAI JADWAL!',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Jam Jadwal
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),

                // Judul Agenda
                Text(
                  title.replaceAll('⏰ ValezPlan: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                // Kategori Tag
                if (_plan != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],

                // Catatan Agenda jika ada
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E272E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2D3436)),
                    ),
                    child: Text(
                      notes,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFBDC3C7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const Spacer(flex: 2),

                // === TIGA OPSI UTAMA SAAT ALARM BERBUNYI ===
                if (_isEarlyReminder) ...[
                  // Opsi untuk Pengingat Persiapan
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388AF6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _handleStopAlarm,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Siap, Saya Bersiap-siap!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ] else ...[
                  // 1. TOMBOL KERJAKAN
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DD1A1), // Emerald Green
                        foregroundColor: const Color(0xFF0F141C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handleCompleteNow,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 22, color: Color(0xFF0F141C)),
                          SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kerjakan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F141C),
                                ),
                              ),
                              Text(
                                'Tandai selesai & matikan alarm',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF145A32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. TOMBOL NANTI SAJA (+5 MENIT)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388AF6), // Valez Blue
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handleSnooze5Minutes,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.update_rounded, size: 22, color: Colors.white),
                          SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nanti Saja (+5 Menit)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Tunda jadwal 5 menit ke depan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFDFE6E9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. TOMBOL HENTIKAN ALARM
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2D3436), width: 1.5),
                        backgroundColor: const Color(0xFF1E272E),
                        foregroundColor: const Color(0xFFFF5252),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _handleStopAlarm,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_circle_outlined, size: 18, color: Color(0xFFFF5252)),
                          SizedBox(width: 8),
                          Text(
                            'Hentikan Alarm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF5252),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
