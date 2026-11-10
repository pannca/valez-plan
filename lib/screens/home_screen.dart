import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../widgets/plan_card.dart';
import '../widgets/timeline_current_time.dart';
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
        SnackBar(
          content: Text(AppStrings.planOverdueLocked),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.planCompletedLocked),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    // Jika waktu jadwal belum tiba, minta konfirmasi via Bottom Sheet
    if (now.isBefore(plan.scheduledTime)) {
      final confirmed = await _showEarlyCompletionSheet(plan);
      if (confirmed != true) {
        return; // Dibatalkan pengguna
      }
    }

    await DatabaseService.instance.toggleComplete(plan.id!, value);
    if (plan.isAlarmEnabled) {
      await AlarmService.instance.cancelAlarm(plan.id!);
    }
    _loadPlansForDate(_selectedDate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.planMarkedComplete(plan.title)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showEarlyCompletionSheet(PlanModel plan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = AppColors.surface(isDark);
    final cardBg = AppColors.surfaceSubtle(isDark);
    final borderColor = AppColors.border(isDark);
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final accentColor = AppColors.accent(isDark);
    const warningColor = AppColors.warning;

    final now = DateTime.now();
    final diff = plan.scheduledTime.difference(now);
    String remainingText;
    if (diff.inDays > 0) {
      remainingText = AppStrings.daysLeft(diff.inDays);
    } else if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      remainingText = AppStrings.hoursLeft(diff.inHours, mins);
    } else if (diff.inMinutes > 0) {
      remainingText = AppStrings.minLeft(diff.inMinutes);
    } else {
      remainingText = AppStrings.shortly;
    }

    final scheduledTimeStr = DateFormat('HH:mm').format(plan.scheduledTime);
    final isPlanToday = plan.scheduledTime.year == now.year &&
        plan.scheduledTime.month == now.month &&
        plan.scheduledTime.day == now.day;
    final scheduledDateStr = isPlanToday
        ? AppStrings.today
        : DateFormat('EEE, d MMM', LanguageService.instance.effectiveLanguage)
            .format(plan.scheduledTime);

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
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
              const SizedBox(height: 16),

              // Header Peringatan / Konfirmasi
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentBorder(isDark),
                      ),
                    ),
                    child: Icon(
                      Icons.fast_forward_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.completeEarlyTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.completeEarlySubtitle(remainingText),
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detail Jadwal Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft(isDark),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$scheduledDateStr, $scheduledTimeStr',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          AppColors.categoryIcon(plan.category),
                          size: 13,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.categoryName(plan.category).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plan.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Info Box Disiplin & Alarm
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.statusSoft(warningColor, isDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.statusBorder(warningColor, isDark),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: warningColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.isAlarmEnabled
                            ? AppStrings.completeEarlyNoticeAlarm
                            : AppStrings.completeEarlyNoticeNoAlarm,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Konfirmasi Selesaikan
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    AppStrings.yesCompleteNow,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Batal
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.cancel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
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
        SnackBar(
          content: Text(AppStrings.isEn
              ? 'This plan is completed and cannot be edited.'
              : 'Jadwal sudah selesai dan tidak dapat diedit.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (ToleranceService.instance.isPlanExpired(plan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isEn
              ? 'This plan is overdue and cannot be edited.'
              : 'Jadwal telah terlewat dan tidak dapat diedit.'),
          duration: const Duration(seconds: 2),
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
    final dateStr = DateFormat(
            'EEEE, d MMMM', LanguageService.instance.effectiveLanguage)
        .format(_selectedDate);
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
                                  AppStrings.noPlansYet,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.noPlansSubtitle,
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
        label: Text(
          AppStrings.newPlan,
          style: const TextStyle(
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
