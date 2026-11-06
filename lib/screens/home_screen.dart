import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../widgets/plan_card.dart';
import '../widgets/timeline_current_time.dart';
import '../widgets/timeline_gap_item.dart';
import '../widgets/day_selector_bar.dart';
import 'add_plan_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  List<PlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlansForDate(_selectedDate);
  }

  Future<void> _loadPlansForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final plans = await DatabaseService.instance.getPlansByDate(date);
      if (mounted) {
        setState(() {
          _plans = plans;
        });
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleComplete(PlanModel plan, bool value) async {
    if (plan.id == null) return;
    await DatabaseService.instance.toggleComplete(plan.id!, value);
    _loadPlansForDate(_selectedDate);
  }

  Future<void> _deletePlan(PlanModel plan) async {
    if (plan.id == null) return;
    await DatabaseService.instance.deletePlan(plan.id!);
    if (plan.isAlarmEnabled) {
      await AlarmService.instance.cancelAlarm(plan.id!);
    }
    _loadPlansForDate(_selectedDate);
  }

  void _openAddPlanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E272E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddPlanSheet(
        initialDate: _selectedDate,
        onPlanAdded: () => _loadPlansForDate(_selectedDate),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<Widget> _buildTimelineWidgets() {
    final List<Widget> widgets = [];
    final now = DateTime.now();
    final isToday = _isToday(_selectedDate);
    bool insertedNowLine = false;

    for (int i = 0; i < _plans.length; i++) {
      final currentPlan = _plans[i];

      // Jika hari ini dan waktu sekarang berada sebelum jadwal ini, sisipkan garis SEKARANG
      if (isToday && !insertedNowLine && now.isBefore(currentPlan.scheduledTime)) {
        widgets.add(const TimelineCurrentTimeIndicator());
        insertedNowLine = true;
      }

      // Sisipkan info waktu luang (Gap) jika ada jarak >= 45 menit dari jadwal sebelumnya
      if (i > 0) {
        final prevPlan = _plans[i - 1];
        final gap = currentPlan.scheduledTime.difference(prevPlan.scheduledTime);
        if (gap.inMinutes >= 45) {
          widgets.add(TimelineGapItem(duration: gap));
        }
      }

      // Kartu Jadwal Timeline
      widgets.add(
        PlanCard(
          plan: currentPlan,
          isFirst: i == 0,
          isLast: i == _plans.length - 1,
          onToggleComplete: (val) => _toggleComplete(currentPlan, val),
          onDelete: () => _deletePlan(currentPlan),
        ),
      );
    }

    // Jika garis jam sekarang belum disisipkan (karena semua jadwal lebih awal dari sekarang)
    if (isToday && !insertedNowLine) {
      widgets.add(const TimelineCurrentTimeIndicator());
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _plans.where((p) => p.isCompleted).length;
    final dateStr = DateFormat('EEEE, d MMMM').format(_selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : const Color(0xFF2D3748);
    final textMuted = isDark ? const Color(0xFF808E9B) : const Color(0xFF718096);
    final cardBg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0);

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
                backgroundColor: cardBg,
                onRefresh: () => _loadPlansForDate(_selectedDate),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Baris Atas: Judul App & Counter Selesai
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timeline',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: textMain,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (_plans.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: borderColor,
                                ),
                              ),
                              child: Text(
                                '$completedCount / ${_plans.length} Selesai',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1DD1A1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Day Selector Bar (Pilihan Hari Horizontal)
                      DaySelectorBar(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) {
                          setState(() => _selectedDate = date);
                          _loadPlansForDate(date);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Konten Timeline
                      if (_plans.isEmpty)
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
                                    Icons.route_rounded,
                                    size: 48,
                                    color: isDark ? const Color(0xFF485460) : const Color(0xFFA0AEC0),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Timeline Masih Kosong',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Atur agenda hari ini untuk mulai merancang harimu',
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
                        ..._buildTimelineWidgets(),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF388AF6),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Jadwal Baru',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: _openAddPlanSheet,
      ),
    );
  }
}
