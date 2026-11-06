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

  // Mengelompokkan riwayat berdasarkan tanggal
  Map<String, List<PlanModel>> _groupPlansByDate(List<PlanModel> plans) {
    final Map<String, List<PlanModel>> grouped = {};
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    for (var plan in plans) {
      final pDate = DateTime(
        plan.scheduledTime.year,
        plan.scheduledTime.month,
        plan.scheduledTime.day,
      );

      String dateHeader;
      if (pDate.year == yesterday.year &&
          pDate.month == yesterday.month &&
          pDate.day == yesterday.day) {
        dateHeader = 'Kemarin, ${DateFormat('d MMMM yyyy').format(pDate)}';
      } else {
        dateHeader = DateFormat('EEEE, d MMMM yyyy').format(pDate);
      }

      grouped.putIfAbsent(dateHeader, () => []).add(plan);
    }
    return grouped;
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

                      // Judul Halaman
                      Text(
                        'Riwayat Kegiatan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Rekap aktivitas hari-hari sebelumnya',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
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
                                  'Jadwal kemarin atau minggu lalu akan otomatis masuk ke sini',
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
                              // Header Tanggal
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

                                return Container(
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
                                        width: 28,
                                        height: 28,
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
                                          size: 16,
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
                                    ],
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

