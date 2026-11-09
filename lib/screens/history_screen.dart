import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';

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
    DatabaseService.plansUpdateNotifier.addListener(_onDatabasePlansUpdated);
    _loadHistory();
  }

  void _onDatabasePlansUpdated() {
    if (mounted) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    DatabaseService.plansUpdateNotifier.removeListener(_onDatabasePlansUpdated);
    super.dispose();
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

  // 1. Data 7 Hari Terakhir untuk Mini Activity Bar Chart
  List<({String dayLabel, int completed, int total, bool isToday})> _getWeeklyData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<({String dayLabel, int completed, int total, bool isToday})> result = [];

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

      result.add((
        dayLabel: dayLabel,
        completed: completed,
        total: total,
        isToday: i == 0,
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
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
            const SizedBox(width: 8),
            Text(
              'Hapus Riwayat?',
              style: TextStyle(
                color: AppColors.ink(isDark),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus "${plan.title}" dari riwayat?',
          style: TextStyle(
            color: AppColors.muted(isDark),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: AppColors.muted(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          SnackBar(
            content: Text(
              'Agenda telah dihapus dari riwayat.',
              style: TextStyle(color: AppColors.ink(isDark)),
            ),
            backgroundColor: AppColors.surface(isDark),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
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
    final cardBg = AppColors.surface(isDark);
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final borderColor = AppColors.border(isDark);
    final accentColor = AppColors.accent(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Kelola Riwayat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.cleaning_services_rounded, color: accentColor, size: 20),
                ),
                title: Text(
                  'Hapus Riwayat Selesai',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMain),
                ),
                subtitle: Text(
                  'Bersihkan agenda yang telah selesai',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _showFinalConfirmDialog(
                    title: 'Hapus Riwayat Selesai?',
                    message: 'Agenda selesai akan dibersihkan dari riwayat.',
                  );
                  if (ok) {
                    await DatabaseService.instance.deleteCompletedHistory();
                    _loadHistory();
                  }
                },
              ),
              Divider(height: 16, color: borderColor),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusSoft(AppColors.danger, isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 20),
                ),
                title: const Text(
                  'Hapus Semua Riwayat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
                subtitle: Text(
                  'Jadwal masa depan tetap aman',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _showFinalConfirmDialog(
                    title: 'Hapus Semua Riwayat?',
                    message: 'Semua riwayat lampau akan dihapus permanen.',
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
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.ink(isDark),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.muted(isDark),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: AppColors.muted(isDark))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final cardBg = AppColors.surface(isDark);
    final textMuted = AppColors.muted(isDark);
    final textMain = AppColors.ink(isDark);
    final borderColor = AppColors.border(isDark);
    final accentColor = AppColors.accent(isDark);

    final completedCount = _historyPlans.where((p) => p.isCompleted).length;
    final totalCount = _historyPlans.length;
    final missedCount = totalCount - completedCount;
    final completionRate =
        totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).toInt();

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
            ? Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                  strokeWidth: 2,
                ),
              )
            : RefreshIndicator(
                color: accentColor,
                backgroundColor: cardBg,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Riwayat',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textMain,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (_historyPlans.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                                color: textMuted,
                                tooltip: 'Kelola Riwayat',
                                onPressed: _showClearHistoryOptions,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // === KARTU 1: RINGKASAN METRIK PERFORMA ===
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSimpleMetric(
                              'SELESAI',
                              '$completedCount / $totalCount',
                              textMain,
                              textMuted,
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: borderColor,
                            ),
                            _buildSimpleMetric(
                              'TERLEWAT',
                              '$missedCount',
                              missedCount > 0 ? AppColors.danger : textMuted,
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
                              accentColor,
                              textMuted,
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
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(height: 2),
                                    Text(
                                      'Minimal 3 aktivitas agar bar penuh',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textMuted.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  weeklyData.last.isToday
                                      ? 'Hari Ini: ${weeklyData.last.completed}'
                                      : '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
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
                                  isDark: isDark,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // === KARTU 3: DISTRIBUSI FOKUS KATEGORI (SKALA TONAL COBALT-SLATE) ===
                      if (categoryDist.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KATEGORI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Progress Bar Segmental Bersih (Skala Tonal Cobalt & Slate)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: categoryDist.entries.map((e) {
                                      return Expanded(
                                        flex: (e.value * 100).toInt().clamp(1, 100),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 1.5),
                                          color: AppColors.categoryTone(e.key, isDark),
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
                                  final col = AppColors.categoryTone(e.key, isDark);
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
                          _buildFilterChip('TERLEWAT', 'Terlewat ($missedCount)'),
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
                                  'Aktivitas yang selesai akan muncul di sini',
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

                                return Dismissible(
                                  key: Key('hist_${plan.id}_${plan.scheduledTime.millisecondsSinceEpoch}'),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => _confirmDeletePlan(plan),
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusSoft(AppColors.danger, isDark),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.statusBorder(AppColors.danger, isDark),
                                      ),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded,
                                        color: AppColors.danger, size: 22),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        // Status Bulat Riwayat (Centang untuk Selesai, Silang untuk Terlewat)
                                        GestureDetector(
                                          onTap: () {
                                            if (plan.isCompleted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Jadwal sudah selesai dan tercatat di riwayat.'),
                                                  duration: Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Jadwal telah terlewat dan terkunci.'),
                                                  duration: Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: plan.isCompleted
                                                  ? accentColor
                                                  : AppColors.surfaceSubtle(isDark),
                                              border: Border.all(
                                                color: plan.isCompleted
                                                    ? accentColor
                                                    : borderColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              plan.isCompleted ? Icons.check_rounded : Icons.close_rounded,
                                              size: 14,
                                              color: plan.isCompleted
                                                  ? Colors.white
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

                                        // Waktu, Status Terlewat/Selesai & Kategori Monokrom
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
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surfaceSubtle(isDark),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: borderColor),
                                                    ),
                                                    child: Text(
                                                      'TERLEWAT',
                                                      style: TextStyle(
                                                        fontSize: 7,
                                                        fontWeight: FontWeight.w800,
                                                        color: textMuted,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceSubtle(isDark),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: borderColor),
                                                  ),
                                                  child: Text(
                                                    plan.category.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w800,
                                                      color: textMuted,
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
                                          color: textMuted.withValues(alpha: 0.5),
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
    required bool isDark,
  }) {
    const double maxBarHeight = 44.0;
    const double targetFullActivities = 3.0;
    final double fillHeight = completed == 0
        ? 4.0
        : (completed / targetFullActivities * maxBarHeight).clamp(8.0, maxBarHeight);

    final accentColor = AppColors.accent(isDark);

    final barColor = isToday
        ? accentColor
        : (completed > 0
            ? accentColor.withValues(alpha: 0.65)
            : AppColors.border(isDark));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indikator atas batang (Angka selesai)
        SizedBox(
          height: 14,
          child: Text(
            completed > 0 ? '$completed' : '',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isToday ? accentColor : AppColors.ink(isDark),
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
            color: AppColors.bg(isDark),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Container(
            width: 18,
            height: fillHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(5),
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
            color: isToday ? accentColor : AppColors.muted(isDark),
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
            fontWeight: FontWeight.w800,
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
    final accentColor = AppColors.accent(isDark);

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border(isDark),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.muted(isDark),
          ),
        ),
      ),
    );
  }
}
