import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../theme/app_colors.dart';
import '../widgets/plan_card.dart';
import '../widgets/timeline_current_time.dart';
import '../widgets/timeline_gap_item.dart';
import '../widgets/day_selector_bar.dart';
import '../services/system_permission_service.dart';
import '../services/tolerance_service.dart';
import '../widgets/permission_warning_sheet.dart';
import 'add_plan_sheet.dart';

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
    ToleranceService.instance.toleranceMinutesNotifier.addListener(_onToleranceChanged);
    DatabaseService.plansUpdateNotifier.addListener(_onDatabasePlansUpdated);
    _loadPlansForDate(_selectedDate);

    // Cek izin sistem HP saat aplikasi terbuka, munculkan pop-up otomatis jika ada yang belum aktif
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await SystemPermissionService.instance.checkPermissions();
      if (status.hasAnyIssue && mounted) {
        PermissionWarningSheet.show(context);
      }
    });
  }

  void _onToleranceChanged() {
    if (mounted) setState(() {});
  }

  void _onDatabasePlansUpdated() {
    if (mounted) {
      _loadPlansForDate(_selectedDate);
    }
  }

  @override
  void dispose() {
    DatabaseService.plansUpdateNotifier.removeListener(_onDatabasePlansUpdated);
    ToleranceService.instance.toleranceMinutesNotifier.removeListener(_onToleranceChanged);
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
    if (value && ToleranceService.instance.isPlanExpired(plan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal telah terlewat dan terkunci.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal sudah selesai dan terkunci.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddPlanSheet(
        initialDate: _selectedDate,
        onPlanAdded: () => _loadPlansForDate(_selectedDate),
      ),
    );
  }

  void _openEditPlanSheet(PlanModel plan) {
    if (plan.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal sudah selesai dan tidak dapat diedit.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (ToleranceService.instance.isPlanExpired(plan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal telah terlewat dan tidak dapat diedit.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddPlanSheet(
        initialDate: plan.scheduledTime,
        planToEdit: plan,
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
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final cardBg = AppColors.surface(isDark);
    final borderColor = AppColors.border(isDark);
    final accentColor = AppColors.accent(isDark);

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
                onRefresh: () => _loadPlansForDate(_selectedDate),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),

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
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: textMain,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: borderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    completedCount == _plans.length
                                        ? Icons.check_circle_rounded
                                        : Icons.task_alt_rounded,
                                    size: 13,
                                    color: completedCount == _plans.length
                                        ? AppColors.success
                                        : accentColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$completedCount / ${_plans.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: textMain,
                                    ),
                                  ),
                                ],
                              ),
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
                              color: AppColors.statusSoft(AppColors.warning, isDark),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.statusBorder(AppColors.warning, isDark),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${status.issueCount} Izin Perlu Diaktifkan',
                                        style: TextStyle(
                                          color: textMain,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Agar alarm berdering saat HP terkunci.',
                                        style: TextStyle(
                                            color: textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () =>
                                      PermissionWarningSheet.show(context),
                                  child: const Text(
                                    'Atur',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
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
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Icon(
                                    Icons.route_rounded,
                                    size: 44,
                                    color: textMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum Ada Jadwal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ketuk + untuk membuat jadwal baru',
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
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Jadwal Baru',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
        onPressed: _openAddPlanSheet,
      ),
    );
  }
}
