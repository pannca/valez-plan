import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

enum _ConflictResolution {
  shift15,
  keepSame,
  editManual,
}

class AddPlanSheet extends StatefulWidget {
  final VoidCallback onPlanAdded;
  final DateTime? initialDate;
  final PlanModel? planToEdit;

  const AddPlanSheet({
    super.key,
    required this.onPlanAdded,
    this.initialDate,
    this.planToEdit,
  });

  @override
  State<AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<AddPlanSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _targetDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Kerja';
  String _repeatMode = 'none'; // 'none', 'daily', 'weekly'
  String _repeatDuration = 'forever'; // 'forever', '2_weeks', '1_month', '3_months'
  int _earlyReminderMinutes = 10; // 0 (tepat waktu), 5, 10, 15
  bool _isAlarmEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.planToEdit != null) {
      final p = widget.planToEdit!;
      _titleController.text = p.title;
      _notesController.text = p.notes;
      _targetDate = p.scheduledTime;
      _selectedTime = TimeOfDay(hour: p.scheduledTime.hour, minute: p.scheduledTime.minute);
      if (AppColors.categories.contains(p.category)) {
        _selectedCategory = p.category;
      } else {
        switch (p.category.toLowerCase()) {
          case 'belajar':
            _selectedCategory = 'Kerja';
            break;
          case 'istirahat':
            _selectedCategory = 'Kesehatan';
            break;
          default:
            _selectedCategory = 'Pribadi';
        }
      }
      _earlyReminderMinutes = p.earlyReminderMinutes;
      _isAlarmEnabled = p.isAlarmEnabled;

      // Inisialisasi mode pengulangan
      if (p.repeatType == 'none') {
        _repeatMode = 'none';
      } else if (p.repeatType == 'daily') {
        _repeatMode = 'daily';
      } else if (p.repeatType.startsWith('weekly:')) {
        _repeatMode = 'weekly';
      } else {
        // Fallback untuk repeatType lama (custom/weekdays/weekends)
        _repeatMode = 'weekly';
      }

      // Inisialisasi durasi pengulangan
      if (p.repeatUntil != null) {
        final days = p.repeatUntil!.difference(p.scheduledTime).inDays;
        if (days <= 16) {
          _repeatDuration = '2_weeks';
        } else if (days <= 35) {
          _repeatDuration = '1_month';
        } else {
          _repeatDuration = '3_months';
        }
      } else {
        _repeatDuration = 'forever';
      }
    } else {
      _targetDate = widget.initialDate ?? DateTime.now();
    }
  }

  String get _targetDayName {
    return AppStrings.dayFull(_targetDate.weekday);
  }

  String get _effectiveRepeatType {
    if (_repeatMode == 'none') return 'none';
    if (_repeatMode == 'daily') return 'daily';
    if (_repeatMode == 'weekly') return 'weekly:${_targetDate.weekday}';
    return 'none';
  }

  DateTime? _calculateRepeatUntil(DateTime start) {
    if (_repeatMode == 'none' || _repeatDuration == 'forever') {
      return null;
    }
    switch (_repeatDuration) {
      case '2_weeks':
        return start.add(const Duration(days: 14));
      case '1_month':
        return DateTime(start.year, start.month + 1, start.day, 23, 59, 59);
      case '3_months':
        return DateTime(start.year, start.month + 3, start.day, 23, 59, 59);
      default:
        return null;
    }
  }

  String _formatRepeatUntilDate() {
    final scheduledDateTime = DateTime(
      _targetDate.year,
      _targetDate.month,
      _targetDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final until = _calculateRepeatUntil(scheduledDateTime);
    if (until == null) return '';
    return DateFormat('d MMM yyyy', LanguageService.instance.effectiveLanguage)
        .format(until);
  }

  bool get _isTargetDateToday {
    final now = DateTime.now();
    return _targetDate.year == now.year &&
        _targetDate.month == now.month &&
        _targetDate.day == now.day;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accentDark,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: AppColors.inkDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.accentLight,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceLight,
                    onSurface: AppColors.inkLight,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accentDark,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: AppColors.inkDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.accentLight,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceLight,
                    onSurface: AppColors.inkLight,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _checkAndSavePlan() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    FocusScope.of(context).unfocus();

    // 1. Cek apakah ada jadwal lain di tanggal & jam:menit yang sama
    final existingPlans =
        await DatabaseService.instance.getPlansByDate(_targetDate);
    PlanModel? conflictingPlan;
    for (final p in existingPlans) {
      if (widget.planToEdit != null && p.id == widget.planToEdit!.id) {
        continue;
      }
      if (p.scheduledTime.hour == _selectedTime.hour &&
          p.scheduledTime.minute == _selectedTime.minute) {
        conflictingPlan = p;
        break;
      }
    }

    if (conflictingPlan != null && mounted) {
      final resolution = await _showConflictSheet(conflictingPlan);
      if (resolution == null) return;

      if (resolution == _ConflictResolution.shift15) {
        final currentDt = DateTime(
          _targetDate.year,
          _targetDate.month,
          _targetDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        final shiftedDt = currentDt.add(const Duration(minutes: 15));
        setState(() {
          _selectedTime =
              TimeOfDay(hour: shiftedDt.hour, minute: shiftedDt.minute);
          _targetDate = DateTime(shiftedDt.year, shiftedDt.month, shiftedDt.day);
        });
        await _executeSave(shiftedDt);
        return;
      } else if (resolution == _ConflictResolution.keepSame) {
        final scheduledDateTime = DateTime(
          _targetDate.year,
          _targetDate.month,
          _targetDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        await _executeSave(scheduledDateTime);
        return;
      } else if (resolution == _ConflictResolution.editManual) {
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 150));
          if (mounted) {
            _pickTime();
          }
        }
        return;
      }
    } else {
      final scheduledDateTime = DateTime(
        _targetDate.year,
        _targetDate.month,
        _targetDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      await _executeSave(scheduledDateTime);
    }
  }

  Future<_ConflictResolution?> _showConflictSheet(PlanModel conflictingPlan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = AppColors.surface(isDark);
    final cardBg = AppColors.surfaceSubtle(isDark);
    final borderColor = AppColors.border(isDark);
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final accentColor = AppColors.accent(isDark);
    const warningColor = AppColors.warning;

    final currentDt = DateTime(
      _targetDate.year,
      _targetDate.month,
      _targetDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final shiftedDt = currentDt.add(const Duration(minutes: 15));
    final shiftedStr =
        '${shiftedDt.hour.toString().padLeft(2, '0')}:${shiftedDt.minute.toString().padLeft(2, '0')}';
    final currentStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return showModalBottomSheet<_ConflictResolution>(
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

              // Header Peringatan
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.statusSoft(warningColor, isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.statusBorder(warningColor, isDark),
                      ),
                    ),
                    child: const Icon(
                      Icons.schedule_send_rounded,
                      color: warningColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.conflictTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.conflictSubtitle,
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

              // Kartu Jadwal Bentrok
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusSoft(warningColor, isDark),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: warningColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conflictingPlan.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                AppColors.categoryIcon(conflictingPlan.category),
                                size: 12,
                                color: textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                conflictingPlan.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // OPSI 1: Auto Geser (+15 Menit) - REKOMENDASI UTAMA
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pop(ctx, _ConflictResolution.shift15),
                  icon: const Icon(Icons.bolt_rounded, size: 20),
                  label: Text(
                    AppStrings.shift15(shiftedStr),
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

              // OPSI 2: Tetap Simpan di Jam yang Sama
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(ctx, _ConflictResolution.keepSame),
                  icon: Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: textMain,
                  ),
                  label: Text(
                    AppStrings.keepSameTime(currentStr),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // OPSI 3: Ubah Jam Manual
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, _ConflictResolution.editManual),
                style: TextButton.styleFrom(
                  foregroundColor: textMuted,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  AppStrings.changeTimeManually,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeSave(DateTime scheduledDateTime) async {
    final title = _titleController.text.trim();
    final repeatType = _effectiveRepeatType;
    final repeatUntil = _calculateRepeatUntil(scheduledDateTime);

    if (widget.planToEdit != null) {
      final updatedPlan = widget.planToEdit!.copyWith(
        title: title,
        notes: _notesController.text.trim(),
        scheduledTime: scheduledDateTime,
        isAlarmEnabled: _isAlarmEnabled,
        category: _selectedCategory,
        repeatType: repeatType,
        earlyReminderMinutes: _isAlarmEnabled ? _earlyReminderMinutes : 0,
        repeatUntil: repeatUntil,
        clearRepeatUntil: repeatUntil == null,
      );

      await DatabaseService.instance.updatePlan(updatedPlan);

      final planId = widget.planToEdit!.id!;
      await AlarmService.instance.cancelAlarm(planId);

      if (_isAlarmEnabled && scheduledDateTime.isAfter(DateTime.now())) {
        await AlarmService.instance.scheduleAlarm(
          id: planId,
          dateTime: scheduledDateTime,
          title: title,
          notes: _notesController.text.trim(),
          earlyReminderMinutes: _earlyReminderMinutes,
        );
      }
    } else {
      final newPlan = PlanModel(
        title: title,
        notes: _notesController.text.trim(),
        scheduledTime: scheduledDateTime,
        isAlarmEnabled: _isAlarmEnabled,
        category: _selectedCategory,
        repeatType: repeatType,
        earlyReminderMinutes: _isAlarmEnabled ? _earlyReminderMinutes : 0,
        repeatUntil: repeatUntil,
      );

      final id = await DatabaseService.instance.insertPlan(newPlan);

      if (_isAlarmEnabled && scheduledDateTime.isAfter(DateTime.now())) {
        await AlarmService.instance.scheduleAlarm(
          id: id,
          dateTime: scheduledDateTime,
          title: title,
          notes: _notesController.text.trim(),
          earlyReminderMinutes: _earlyReminderMinutes,
        );
      }
    }

    widget.onPlanAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = AppColors.surface(isDark);
    final cardBg = AppColors.surfaceSubtle(isDark);
    final borderColor = AppColors.border(isDark);
    final textMain = AppColors.ink(isDark);
    final textMuted = AppColors.muted(isDark);
    final accentColor = AppColors.accent(isDark);

    final now = DateTime.now();
    final isPast = _isTargetDateToday &&
        (_selectedTime.hour < now.hour ||
            (_selectedTime.hour == now.hour &&
                _selectedTime.minute <= now.minute));

    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 14),

            // Header Modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.planToEdit != null
                      ? AppStrings.editPlanHeader
                      : AppStrings.newPlanHeader,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardBg,
                    ),
                    child: Icon(Icons.close_rounded, color: textMuted, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // === BLOK 1: HERO NAMA KEGIATAN & CATATAN (Things 3 Style) ===
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    autofocus: widget.planToEdit == null,
                    style: TextStyle(
                      color: textMain,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.activityNameHint,
                      hintStyle: TextStyle(
                        color: textMuted.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 8),
                      border: InputBorder.none,
                    ),
                  ),
                  Divider(height: 12, thickness: 1, color: borderColor.withValues(alpha: 0.6)),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    minLines: 1,
                    style: TextStyle(color: textMain, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppStrings.notesHint,
                      hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.6)),
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 4),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // === BLOK 2: KARTU WAKTU & ALARM TERPADU (Grouped iOS Style) ===
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // Baris 1: Tanggal & Jam
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Tombol Tanggal
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _isTargetDateToday ? Icons.today_rounded : Icons.event_rounded,
                                    size: 18,
                                    color: _isTargetDateToday ? accentColor : textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isTargetDateToday
                                          ? '${AppStrings.today}, ${DateFormat('d MMM', LanguageService.instance.effectiveLanguage).format(_targetDate)}'
                                          : DateFormat('EEE, d MMM', LanguageService.instance.effectiveLanguage).format(_targetDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _isTargetDateToday ? accentColor : textMain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(height: 20, width: 1, color: borderColor),
                        const SizedBox(width: 12),
                        // Tombol Jam
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 16, color: accentColor),
                                const SizedBox(width: 6),
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Peringatan Jam Sudah Lewat
                  if (isPast)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      color: AppColors.statusSoft(AppColors.danger, isDark),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppStrings.pastTimeWarning,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Divider(height: 1, color: borderColor),

                  // Baris 2: Toggle Alarm
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.alarm_rounded,
                              size: 18,
                              color: _isAlarmEnabled ? accentColor : textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.isEn ? 'Alarm' : 'Alarm Dering',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textMain,
                              ),
                            ),
                          ],
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _isAlarmEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: AppColors.accentSoft(isDark),
                            onChanged: (val) => setState(() => _isAlarmEnabled = val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Baris 3: Pengingat Persiapan (Hanya muncul jika Alarm aktif)
                  if (_isAlarmEnabled) ...[
                    Divider(height: 1, color: borderColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, size: 14, color: textMuted),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.isEn ? 'Remind' : 'Ingatkan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                (0, AppStrings.onTime, 4),
                                (5, AppStrings.isEn ? '5 min' : '5 mnt', 3),
                                (10, AppStrings.isEn ? '10 min' : '10 mnt', 3),
                                (15, AppStrings.isEn ? '15 min' : '15 mnt', 3),
                              ].map((item) {
                                final isSelected = _earlyReminderMinutes == item.$1;
                                return Expanded(
                                  flex: item.$3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _earlyReminderMinutes = item.$1),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.accentSoft(isDark)
                                              : AppColors.surface(isDark),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected ? accentColor : borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          item.$2,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? accentColor : textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // === BLOK 3: KATEGORI (3 Kategori Universal: Kerja, Pribadi, Kesehatan) ===
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Text(
                AppStrings.category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
            ),
            Row(
              children: AppColors.categories.map((category) {
                final isSelected = _selectedCategory == category;
                final icon = AppColors.categoryIcon(category);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentSoft(isDark) : cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? accentColor : borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 14, color: isSelected ? accentColor : textMuted),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                AppStrings.categoryName(category),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? accentColor : textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // === BLOK 4: PENGULANGAN (Konsep 1: Smart Dynamic Repeat) ===
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Text(
                AppStrings.repetition,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
            ),
            Row(
              children: [
                ('none', AppStrings.once),
                ('daily', AppStrings.everyDay),
                ('weekly', AppStrings.everyDayName(_targetDayName)),
              ].map((item) {
                final isSelected = _repeatMode == item.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _repeatMode = item.$1;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentSoft(isDark) : cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? accentColor : borderColor,
                            width: 1,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.$2,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? accentColor : textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Batas Durasi Pengulangan (Muncul jika BUKAN 'Sekali')
            if (_repeatMode != 'none') ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.repeatDuration,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textMuted,
                      ),
                    ),
                    if (_repeatDuration != 'forever')
                      Text(
                        AppStrings.untilDate(_formatRepeatUntilDate()),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  ('forever', AppStrings.forever),
                  ('2_weeks', AppStrings.twoWeeks),
                  ('1_month', AppStrings.oneMonth),
                  ('3_months', AppStrings.threeMonths),
                ].map((dur) {
                  final isDurSelected = _repeatDuration == dur.$1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _repeatDuration = dur.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDurSelected ? AppColors.accentSoft(isDark) : cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDurSelected ? accentColor : borderColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            dur.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDurSelected ? accentColor : textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // === TOMBOL SIMPAN ===
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _checkAndSavePlan,
                child: Text(
                  AppStrings.save,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
