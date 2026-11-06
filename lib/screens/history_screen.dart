import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PlanModel> _historyPlans = [];
  bool _isLoading = true;
  String _activeFilter = 'SEMUA'; // 'SEMUA', 'SELESAI', 'TERLEWAT'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final plans = await DatabaseService.instance.getHistoryPlans();
      if (mounted) {
        setState(() {
          _historyPlans = plans;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Palet Warna Profesional & Terarah (Tidak Terlalu Ramai)
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kerja':
        return const Color(0xFF388AF6); // Valez Blue
      case 'belajar':
        return const Color(0xFF818CF8); // Indigo Soft
      case 'ibadah':
        return const Color(0xFF1DD1A1); // Mint Clean
      case 'istirahat':
      case 'santai':
        return const Color(0xFFFF9F43); // Soft Amber
      default:
        return const Color(0xFF64748B); // Slate Neutral
    }
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // 1. Hitung Streak & Status Disiplin (Senin-Jumat Wajib, Sabtu-Minggu Weekend Recharge 🔋)
  ({int streak, bool isWeekendRecharge, bool isAtRiskToday, bool isCompletedToday}) _calculateStreakInfo() {
    if (_historyPlans.isEmpty) {
      final now = DateTime.now();
      return (
        streak: 0,
        isWeekendRecharge: _isWeekend(now),
        isAtRiskToday: !_isWeekend(now) && now.hour >= 17,
        isCompletedToday: false,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final completedDays = <DateTime>{};
    for (var plan in _historyPlans) {
      if (plan.isCompleted) {
        completedDays.add(DateTime(
          plan.scheduledTime.year,
          plan.scheduledTime.month,
          plan.scheduledTime.day,
        ));
      }
    }

    final isTodayWeekend = _isWeekend(today);
    final hasCompletedToday = completedDays.contains(today);
    final isAtRiskToday = !isTodayWeekend && !hasCompletedToday && now.hour >= 17;

    int streak = 0;
    DateTime checkDate = today;

    // Jika hari ini belum ada agenda selesai:
    // - Jika hari ini weekend: mulai cek dari hari kerja terakhir (Jumat)
    // - Jika hari ini hari kerja: karena hari ini masih berjalan, streak kemarin tetap dipertahankan sampai 23:59
    if (!hasCompletedToday) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    // Telusuri hari demi hari ke belakang
    for (int i = 0; i < 365; i++) {
      final isCheckWeekend = _isWeekend(checkDate);
      final hasCompleted = completedDays.contains(checkDate);

      if (hasCompleted) {
        streak++;
      } else if (isCheckWeekend) {
        // Akhir pekan (Sabtu/Minggu) tanpa kegiatan: AMAN (Weekend Recharge), lewati tanpa memutuskan streak
      } else {
        // Hari kerja (Senin-Jumat) tanpa kegiatan selesai: STREAK PUTUS!
        break;
      }

      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return (
      streak: streak,
      isWeekendRecharge: isTodayWeekend,
      isAtRiskToday: isAtRiskToday,
      isCompletedToday: hasCompletedToday,
    );
  }

  // 2. Data 7 Hari Terakhir untuk Mini Activity Bar Chart
  List<({String dayLabel, int completed, int total, bool isToday, bool isWeekend})> _getWeeklyData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<({String dayLabel, int completed, int total, bool isToday, bool isWeekend})> result = [];

    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayPlans = _historyPlans.where((p) {
        final pDate = DateTime(p.scheduledTime.year, p.scheduledTime.month, p.scheduledTime.day);
        return pDate.isAtSameMomentAs(date);
      }).toList();

      final completed = dayPlans.where((p) => p.isCompleted).length;
      final total = dayPlans.length;
      final dayLabel = dayNames[date.weekday % 7];
      final isWeekend = _isWeekend(date);

      result.add((
        dayLabel: dayLabel,
        completed: completed,
        total: total,
        isToday: i == 0,
        isWeekend: isWeekend,
      ));
    }

    return result;
  }

  // 3. Distribusi Kategori Agenda yang Selesai
  Map<String, double> _getCategoryDistribution() {
    final completedPlans = _historyPlans.where((p) => p.isCompleted).toList();
    if (completedPlans.isEmpty) return {};

    final Map<String, int> counts = {};
    for (var plan in completedPlans) {
      counts[plan.category] = (counts[plan.category] ?? 0) + 1;
    }

    final Map<String, double> distribution = {};
    counts.forEach((cat, count) {
      distribution[cat] = count / completedPlans.length;
    });

    return distribution;
  }

  // Mengelompokkan riwayat berdasarkan tanggal
  Map<String, List<PlanModel>> _groupPlansByDate(List<PlanModel> plans) {
    final Map<String, List<PlanModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    for (var plan in plans) {
      final pDate = DateTime(
        plan.scheduledTime.year,
        plan.scheduledTime.month,
        plan.scheduledTime.day,
      );

      String dateHeader;
      if (pDate.isAtSameMomentAs(today)) {
        dateHeader = 'Hari Ini, ${DateFormat('d MMMM yyyy').format(pDate)}';
      } else if (pDate.isAtSameMomentAs(yesterday)) {
        dateHeader = 'Kemarin, ${DateFormat('d MMMM yyyy').format(pDate)}';
      } else {
        dateHeader = DateFormat('EEEE, d MMMM yyyy').format(pDate);
      }

      grouped.putIfAbsent(dateHeader, () => []).add(plan);
    }
    return grouped;
  }

  // Dialog konfirmasi hapus 1 jadwal
  Future<bool> _confirmDeletePlan(PlanModel plan) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E272E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 22),
            const SizedBox(width: 8),
            Text(
              'Hapus dari Riwayat?',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2D3748),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Jadwal "${plan.title}" akan dihapus permanen dari riwayat kamu.',
          style: TextStyle(
            color: isDark ? const Color(0xFFBDC3C7) : const Color(0xFF718096),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? const Color(0xFF808E9B) : const Color(0xFF718096),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && plan.id != null) {
      await DatabaseService.instance.deletePlan(plan.id!);
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agenda telah dihapus dari riwayat.'),
            backgroundColor: Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    }
    return false;
  }

  // Opsi Kelola / Bersihkan Riwayat
  void _showClearHistoryOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final textMain = isDark ? Colors.white : const Color(0xFF2D3748);
    final textMuted = isDark ? const Color(0xFF808E9B) : const Color(0xFF718096);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF485460) : const Color(0xFFCBD5E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Kelola Riwayat Kegiatan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Data tersimpan permanen di HP kamu. Pilih jika ingin dibersihkan:',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DD1A1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF1DD1A1), size: 20),
                ),
                title: Text(
                  'Hapus Riwayat yang Selesai',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMain),
                ),
                subtitle: Text(
                  'Hanya membersihkan agenda yang sudah dicentang selesai',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _showFinalConfirmDialog(
                    title: 'Hapus Riwayat Selesai?',
                    message: 'Agenda yang telah selesai akan dibersihkan dari riwayat.',
                  );
                  if (ok) {
                    await DatabaseService.instance.deleteCompletedHistory();
                    _loadHistory();
                  }
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF5252), size: 20),
                ),
                title: const Text(
                  'Bersihkan Seluruh Riwayat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF5252)),
                ),
                subtitle: Text(
                  'Mengosongkan arsip riwayat masa lalu (jadwal masa depan tetap aman)',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _showFinalConfirmDialog(
                    title: 'Bersihkan Seluruh Riwayat?',
                    message: 'Apakah kamu yakin ingin mengosongkan riwayat kegiatan lampau?',
                  );
                  if (ok) {
                    await DatabaseService.instance.clearAllHistory();
                    _loadHistory();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showFinalConfirmDialog({required String title, required String message}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E272E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF2D3748),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? const Color(0xFFBDC3C7) : const Color(0xFF718096),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: isDark ? const Color(0xFF808E9B) : const Color(0xFF718096))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final textMuted = isDark ? const Color(0xFF808E9B) : const Color(0xFF718096);
    final textMain = isDark ? Colors.white : const Color(0xFF2D3748);
    final borderColor = isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0);

    final completedCount = _historyPlans.where((p) => p.isCompleted).length;
    final totalCount = _historyPlans.length;
    final completionRate =
        totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).toInt();

    final streakInfo = _calculateStreakInfo();
    final weeklyData = _getWeeklyData();
    final categoryDist = _getCategoryDistribution();

    List<PlanModel> filteredPlans;
    if (_activeFilter == 'SELESAI') {
      filteredPlans = _historyPlans.where((p) => p.isCompleted).toList();
    } else if (_activeFilter == 'TERLEWAT') {
      filteredPlans = _historyPlans.where((p) => !p.isCompleted).toList();
    } else {
      filteredPlans = _historyPlans;
    }

    final groupedPlans = _groupPlansByDate(filteredPlans);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF388AF6),
                  strokeWidth: 2,
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF388AF6),
                onRefresh: _loadHistory,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),

                      // Baris Header Judul & Tombol Kelola
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Performa & Riwayat',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: textMain,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Konsistensi disiplin & catatan agenda harian',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_historyPlans.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                                color: textMuted,
                                tooltip: 'Kelola / Bersihkan Riwayat',
                                onPressed: _showClearHistoryOptions,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // === KARTU 1: STREAK & KONSISTENSI (HERO METRIC) ===
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Badge Streak Dinamis (Baterai Recharge vs Api Beruntun)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: streakInfo.isWeekendRecharge
                                        ? const Color(0xFF00CEC9).withValues(alpha: 0.12)
                                        : (streakInfo.isAtRiskToday
                                            ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                                            : const Color(0xFFFF9F43).withValues(alpha: 0.12)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            streakInfo.isWeekendRecharge
                                                ? Icons.battery_charging_full_rounded
                                                : (streakInfo.isAtRiskToday
                                                    ? Icons.warning_amber_rounded
                                                    : Icons.local_fire_department_rounded),
                                            color: streakInfo.isWeekendRecharge
                                                ? const Color(0xFF00CEC9)
                                                : (streakInfo.isAtRiskToday
                                                    ? const Color(0xFFFF5252)
                                                    : const Color(0xFFFF9F43)),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${streakInfo.streak}',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: streakInfo.isWeekendRecharge
                                                  ? const Color(0xFF00CEC9)
                                                  : (streakInfo.isAtRiskToday
                                                      ? const Color(0xFFFF5252)
                                                      : const Color(0xFFFF9F43)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        streakInfo.isWeekendRecharge
                                            ? 'RECHARGE'
                                            : (streakInfo.isAtRiskToday ? 'TERANCAM' : 'HARI STREAK'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: streakInfo.isWeekendRecharge
                                              ? const Color(0xFF00CEC9)
                                              : (streakInfo.isAtRiskToday
                                                  ? const Color(0xFFFF5252)
                                                  : const Color(0xFFFF9F43)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Ringkasan Dua Metrik Utama
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildSimpleMetric(
                                        'SELESAI',
                                        '$completedCount / $totalCount',
                                        const Color(0xFF1DD1A1),
                                        textMuted,
                                      ),
                                      Container(
                                        height: 32,
                                        width: 1,
                                        color: borderColor,
                                      ),
                                      _buildSimpleMetric(
                                        'DISIPLIN',
                                        '$completionRate%',
                                        const Color(0xFF388AF6),
                                        textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Banner Penjelasan Aturan Weekday & Weekend Recharge
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF14171A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: streakInfo.isAtRiskToday
                                      ? const Color(0xFFFF5252).withValues(alpha: 0.3)
                                      : borderColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    streakInfo.isWeekendRecharge
                                        ? Icons.battery_charging_full_rounded
                                        : (streakInfo.isAtRiskToday
                                            ? Icons.alarm_rounded
                                            : Icons.check_circle_outline_rounded),
                                    size: 14,
                                    color: streakInfo.isWeekendRecharge
                                        ? const Color(0xFF00CEC9)
                                        : (streakInfo.isAtRiskToday
                                            ? const Color(0xFFFF5252)
                                            : const Color(0xFF1DD1A1)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      streakInfo.isWeekendRecharge
                                          ? 'Sabtu & Minggu waktu isi ulang baterai. Streak kamu aman tanpa ada kegiatan!'
                                          : (streakInfo.isCompletedToday
                                              ? 'Hebat! Api hari ini menyala. Streak berlanjut ke hari kerja berikutnya.'
                                              : (streakInfo.isAtRiskToday
                                                  ? '⚠️ Selesaikan minimal 1 kegiatan sebelum 00:00 agar api streak tidak padam!'
                                                  : 'Senin - Jumat wajib ada kegiatan selesai agar api tidak padam.')),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: streakInfo.isAtRiskToday
                                            ? const Color(0xFFFF5252)
                                            : textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // === KARTU 2: AKTIVITAS 7 HARI TERAKHIR (MINI BAR CHART) ===
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AKTIVITAS 7 HARI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                                Text(
                                  weeklyData.last.isToday
                                      ? 'Hari Ini: ${weeklyData.last.completed} Selesai'
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF388AF6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Bar Chart Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: weeklyData.map((d) {
                                return _buildDayBar(
                                  dayLabel: d.dayLabel,
                                  completed: d.completed,
                                  isToday: d.isToday,
                                  isWeekend: d.isWeekend,
                                  isDark: isDark,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // === KARTU 3: DISTRIBUSI FOKUS KATEGORI ===
                      if (categoryDist.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DISTRIBUSI FOKUS KEGIATAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Progress Bar Segmental Bersih
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: categoryDist.entries.map((e) {
                                      return Expanded(
                                        flex: (e.value * 100).toInt().clamp(1, 100),
                                        child: Container(
                                          color: _getCategoryColor(e.key),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Legend Kategori Minimalis
                              Wrap(
                                spacing: 14,
                                runSpacing: 6,
                                children: categoryDist.entries.map((e) {
                                  final pct = (e.value * 100).toInt();
                                  final col = _getCategoryColor(e.key);
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: col,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${e.key} $pct%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: textMain,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Filter Pills
                      Row(
                        children: [
                          _buildFilterChip('SEMUA', 'Semua ($totalCount)'),
                          const SizedBox(width: 8),
                          _buildFilterChip('SELESAI', 'Selesai ($completedCount)'),
                          const SizedBox(width: 8),
                          _buildFilterChip('TERLEWAT', 'Terlewat (${totalCount - completedCount})'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Daftar Riwayat Terkelompok
                      if (_historyPlans.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 44,
                                  color: textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum Ada Riwayat',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Agenda yang selesai langsung terekap di sini',
                                  style: TextStyle(fontSize: 12, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        ...groupedPlans.entries.map((entry) {
                          final dateTitle = entry.key;
                          final plansOnDate = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Tanggal
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8, top: 10),
                                child: Text(
                                  dateTitle.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),

                              // Item-item kegiatan pada tanggal tersebut
                              ...plansOnDate.map((plan) {
                                final timeStr = DateFormat('HH:mm').format(plan.scheduledTime);
                                final categoryColor = _getCategoryColor(plan.category);

                                return Dismissible(
                                  key: Key('hist_${plan.id}_${plan.scheduledTime.millisecondsSinceEpoch}'),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => _confirmDeletePlan(plan),
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5252).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        // Status Bulat Bersih & Interaktif (Bisa Dicentang Susulan)
                                        GestureDetector(
                                          onTap: () async {
                                            if (plan.id != null) {
                                              await DatabaseService.instance.toggleComplete(plan.id!, !plan.isCompleted);
                                              _loadHistory();
                                            }
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: plan.isCompleted
                                                  ? const Color(0xFF1DD1A1).withValues(alpha: 0.15)
                                                  : (isDark ? const Color(0xFF242C34) : const Color(0xFFF1F5F9)),
                                              border: Border.all(
                                                color: plan.isCompleted
                                                    ? const Color(0xFF1DD1A1)
                                                    : (isDark ? const Color(0xFF3A444C) : const Color(0xFFCBD5E0)),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              plan.isCompleted ? Icons.check_rounded : Icons.close_rounded,
                                              size: 14,
                                              color: plan.isCompleted
                                                  ? const Color(0xFF1DD1A1)
                                                  : textMuted,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Judul & Catatan
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                plan.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: plan.isCompleted ? textMain : textMuted,
                                                  decoration: plan.isCompleted
                                                      ? TextDecoration.none
                                                      : TextDecoration.lineThrough,
                                                  decorationColor: textMuted,
                                                ),
                                              ),
                                              if (plan.notes.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  plan.notes,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textMuted,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Waktu, Status Terlewat/Selesai & Kategori
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'monospace',
                                                color: textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!plan.isCompleted)
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: (isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0)),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'TERLEWAT',
                                                      style: TextStyle(
                                                        fontSize: 7,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFF808E9B),
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: categoryColor.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    plan.category.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w800,
                                                      color: categoryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),

                                        // Tombol Hapus Manual
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                          color: textMuted.withValues(alpha: 0.4),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Hapus Item',
                                          onPressed: () => _confirmDeletePlan(plan),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                        const SizedBox(height: 30),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Komponen Batang Harian Bar Chart
  Widget _buildDayBar({
    required String dayLabel,
    required int completed,
    required bool isToday,
    required bool isWeekend,
    required bool isDark,
  }) {
    final double maxBarHeight = 44.0;
    final double fillHeight = completed == 0
        ? 4.0
        : (completed / 5.0 * maxBarHeight).clamp(8.0, maxBarHeight);

    final isRecharging = isWeekend && completed == 0;

    final barColor = isToday
        ? const Color(0xFF388AF6) // Biru hari ini
        : (completed > 0
            ? const Color(0xFF1DD1A1) // Mint
            : (isRecharging
                ? const Color(0xFF00CEC9).withValues(alpha: 0.4) // Cyan battery recharge
                : (isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0))));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indikator atas batang (Angka selesai atau icon baterai recharge)
        SizedBox(
          height: 14,
          child: isRecharging
              ? const Icon(Icons.battery_charging_full_rounded, size: 13, color: Color(0xFF00CEC9))
              : Text(
                  completed > 0 ? '$completed' : '',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: barColor,
                  ),
                ),
        ),
        const SizedBox(height: 4),

        // Track Batang Vertikal
        Container(
          width: 18,
          height: maxBarHeight,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14171A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Container(
            width: 18,
            height: isRecharging ? 8.0 : fillHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Label Nama Hari
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday
                ? const Color(0xFF388AF6)
                : (isRecharging
                    ? const Color(0xFF00CEC9)
                    : (isDark ? const Color(0xFF808E9B) : const Color(0xFF718096))),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleMetric(String label, String value, Color color, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _activeFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF388AF6)
              : (isDark ? const Color(0xFF1E272E) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF388AF6)
                : (isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF808E9B) : const Color(0xFF718096)),
          ),
        ),
      ),
    );
  }
}
