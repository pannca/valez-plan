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

  // Mengelompokkan riwayat berdasarkan tanggal (Hari Ini, Kemarin, dst)
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

  // Dialog konfirmasi hapus 1 jadwal dari riwayat
  Future<bool> _confirmDeletePlan(PlanModel plan) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E272E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 24),
            const SizedBox(width: 8),
            Text(
              'Hapus dari Riwayat?',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2D3748),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Jadwal "${plan.title}" akan dihapus permanen dari riwayat kamu.',
          style: TextStyle(
            color: isDark ? const Color(0xFFBDC3C7) : const Color(0xFF718096),
            fontSize: 14,
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
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800)),
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

  // Opsi Kelola / Bersihkan Riwayat (Hanya jika user memang mau menghapus)
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
                  width: 40,
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
              const SizedBox(height: 6),
              Text(
                'Riwayat kamu aman tersimpan permanen di HP. Pilih opsi jika ingin membersihkannya:',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 18),

              // Opsi 1: Bersihkan Riwayat Selesai
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DD1A1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF1DD1A1)),
                ),
                title: Text(
                  'Hapus Riwayat yang Sudah Selesai',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textMain),
                ),
                subtitle: Text(
                  'Hanya menghapus agenda dengan status checklist selesai',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _showFinalConfirmDialog(
                    title: 'Hapus Riwayat Selesai?',
                    message: 'Semua agenda riwayat yang telah selesai akan dibersihkan.',
                  );
                  if (ok) {
                    await DatabaseService.instance.deleteCompletedHistory();
                    _loadHistory();
                  }
                },
              ),
              const Divider(height: 20),

              // Opsi 2: Bersihkan Seluruh Riwayat
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF5252)),
                ),
                title: const Text(
                  'Bersihkan Seluruh Riwayat',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFF5252)),
                ),
                subtitle: Text(
                  'Menghapus semua arsip riwayat masa lalu secara permanen',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _showFinalConfirmDialog(
                    title: 'Bersihkan Seluruh Riwayat?',
                    message: 'Apakah kamu yakin ingin mengosongkan semua riwayat kegiatan? Agenda di timeline masa depan tidak akan terpengaruh.',
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
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? const Color(0xFFBDC3C7) : const Color(0xFF718096),
            fontSize: 14,
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

    final completedCount = _historyPlans.where((p) => p.isCompleted).length;
    final totalCount = _historyPlans.length;
    final completionRate =
        totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).toInt();

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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

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
                                  'Riwayat Kegiatan',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: textMain,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 13,
                                      color: Color(0xFF1DD1A1),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Tersimpan aman permanen di HP kamu',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_historyPlans.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0),
                                ),
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
                      const SizedBox(height: 18),

                      // Kartu Statistik Ringkasan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2D3436)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'TOTAL AGENDA',
                              totalCount.toString(),
                              const Color(0xFF388AF6),
                              textMuted,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: isDark
                                  ? const Color(0xFF2D3436)
                                  : const Color(0xFFE2E8F0),
                            ),
                            _buildStatItem(
                              'SELESAI',
                              completedCount.toString(),
                              const Color(0xFF1DD1A1),
                              textMuted,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: isDark
                                  ? const Color(0xFF2D3436)
                                  : const Color(0xFFE2E8F0),
                            ),
                            _buildStatItem(
                              'DISIPLIN',
                              '$completionRate%',
                              const Color(0xFFFF9F43),
                              textMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Filter Pills
                      Row(
                        children: [
                          _buildFilterChip('SEMUA', 'Semua ($totalCount)'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              'SELESAI', 'Selesai ($completedCount)'),
                          const SizedBox(width: 8),
                          _buildFilterChip('TERLEWAT',
                              'Terlewat (${totalCount - completedCount})'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Daftar Riwayat Terkelompok
                      if (_historyPlans.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cardBg,
                                  ),
                                  child: Icon(
                                    Icons.history_toggle_off_rounded,
                                    size: 48,
                                    color: textMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum Ada Riwayat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Jadwal yang sudah selesai atau terlewat akan langsung muncul di sini',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
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
                              // Header Tanggal (Hari Ini, Kemarin, dst)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, bottom: 8, top: 12),
                                child: Text(
                                  dateTitle.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),

                              // Item-item kegiatan pada tanggal tersebut
                              ...plansOnDate.map((plan) {
                                final timeStr = DateFormat('HH:mm')
                                    .format(plan.scheduledTime);
                                final categoryColor =
                                    _getCategoryColor(plan.category);

                                return Dismissible(
                                  key: Key('history_${plan.id}_${plan.scheduledTime.millisecondsSinceEpoch}'),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => _confirmDeletePlan(plan),
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5252).withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Hapus',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF2D3436)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Status Icon Bulat
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: plan.isCompleted
                                                ? const Color(0xFF1DD1A1)
                                                    .withValues(alpha: 0.15)
                                                : const Color(0xFFFF5252)
                                                    .withValues(alpha: 0.15),
                                          ),
                                          child: Icon(
                                            plan.isCompleted
                                                ? Icons.check_rounded
                                                : Icons.close_rounded,
                                            size: 18,
                                            color: plan.isCompleted
                                                ? const Color(0xFF1DD1A1)
                                                : const Color(0xFFFF5252),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Judul & Catatan
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                plan.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: plan.isCompleted
                                                      ? textMain
                                                      : textMuted,
                                                  decoration: plan.isCompleted
                                                      ? TextDecoration.none
                                                      : TextDecoration.lineThrough,
                                                ),
                                              ),
                                              if (plan.notes.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  plan.notes,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textMuted,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Waktu & Kategori
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'monospace',
                                                color: textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: categoryColor
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                plan.category.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: categoryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),

                                        // Tombol Hapus Manual
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
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
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, Color textMuted) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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
            letterSpacing: 0.8,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF388AF6)
              : isDark
                  ? const Color(0xFF1E272E)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF388AF6)
                : isDark
                    ? const Color(0xFF2D3436)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                    ? const Color(0xFF808E9B)
                    : const Color(0xFF718096),
          ),
        ),
      ),
    );
  }
}
