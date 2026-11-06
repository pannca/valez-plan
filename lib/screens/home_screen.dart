import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../widgets/plan_card.dart';
import '../widgets/timeline_current_time.dart';
import '../widgets/timeline_gap_item.dart';
import '../widgets/day_selector_bar.dart';
import '../services/system_permission_service.dart';
import '../widgets/permission_warning_sheet.dart';
import 'add_plan_sheet.dart';
import 'routine_template_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  List<PlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPlansForDate(_selectedDate);

    // Cek izin sistem HP saat aplikasi terbuka, munculkan pop-up otomatis jika ada yang belum aktif
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await SystemPermissionService.instance.checkPermissions();
      if (status.hasAnyIssue && mounted) {
        PermissionWarningSheet.show(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemPermissionService.instance.checkPermissions();
      _loadPlansForDate(_selectedDate);
    }
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

  void _openEditPlanSheet(PlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E272E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddPlanSheet(
        initialDate: plan.scheduledTime,
        planToEdit: plan,
        onPlanAdded: () => _loadPlansForDate(_selectedDate),
      ),
    );
  }

  void _openTemplateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineTemplateSheet(
        targetDate: _selectedDate,
        hasExistingPlans: _plans.isNotEmpty,
        onTemplateApplied: () => _loadPlansForDate(_selectedDate),
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
          onEdit: () => _openEditPlanSheet(currentPlan),
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

                      // Baris Atas: Judul App & Action Buttons
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
                              Row(
                                children: [
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textMuted,
                                    ),
                                  ),
                                  if (!_isToday(_selectedDate)) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        final today = DateTime.now();
                                        setState(() => _selectedDate = today);
                                        _loadPlansForDate(today);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF388AF6)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Ke Hari Ini',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF388AF6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Tombol Template Rutinitas Cepat
                              InkWell(
                                onTap: _openTemplateSheet,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt_rounded,
                                          color: Color(0xFF388AF6), size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        'Template',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF388AF6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_plans.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    '$completedCount / ${_plans.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1DD1A1),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      // Banner Peringatan Izin Sistem HP jika ada yang belum aktif
                      ValueListenableBuilder<SystemPermissionStatus>(
                        valueListenable:
                            SystemPermissionService.instance.statusNotifier,
                        builder: (_, status, __) {
                          if (!status.hasAnyIssue) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9F43)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF9F43)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFFF9F43),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${status.issueCount} Izin HP Perlu Diaktifkan',
                                        style: TextStyle(
                                          color: textMain,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Agar alarm tidak terblokir saat HP sleep.',
                                        style: TextStyle(
                                            color: textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9F43),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () =>
                                      PermissionWarningSheet.show(context),
                                  child: const Text(
                                    'Atur',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
                          padding: const EdgeInsets.symmetric(vertical: 60),
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
                                const SizedBox(height: 18),
                                OutlinedButton.icon(
                                  onPressed: _openTemplateSheet,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF388AF6),
                                    side: const BorderSide(
                                        color: Color(0xFF388AF6), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.bolt_rounded, size: 18),
                                  label: const Text(
                                    'Pilih Template Rutinitas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
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
