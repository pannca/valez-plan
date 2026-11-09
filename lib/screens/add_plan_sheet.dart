import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../theme/app_colors.dart';

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
  String _repeatType = 'none'; // 'none', 'daily', 'weekdays', 'weekends'
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
      _selectedCategory = p.category;
      _repeatType = p.repeatType;
      _earlyReminderMinutes = p.earlyReminderMinutes;
      _isAlarmEnabled = p.isAlarmEnabled;
    } else {
      _targetDate = widget.initialDate ?? DateTime.now();
    }
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

  Future<void> _savePlan() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final scheduledDateTime = DateTime(
      _targetDate.year,
      _targetDate.month,
      _targetDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (widget.planToEdit != null) {
      final updatedPlan = widget.planToEdit!.copyWith(
        title: title,
        notes: _notesController.text.trim(),
        scheduledTime: scheduledDateTime,
        isAlarmEnabled: _isAlarmEnabled,
        category: _selectedCategory,
        repeatType: _repeatType,
        earlyReminderMinutes: _isAlarmEnabled ? _earlyReminderMinutes : 0,
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
        repeatType: _repeatType,
        earlyReminderMinutes: _isAlarmEnabled ? _earlyReminderMinutes : 0,
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
                  widget.planToEdit != null ? 'Edit Jadwal' : 'Jadwal Baru',
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
                      hintText: 'Nama kegiatan',
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
                      hintText: 'Catatan (opsional)',
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
                                          ? 'Hari Ini, ${DateFormat('d MMM').format(_targetDate)}'
                                          : DateFormat('EEE, d MMM').format(_targetDate),
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
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 13, color: AppColors.danger),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Waktu sudah lewat hari ini. Alarm tidak aktif.',
                              style: TextStyle(
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
                              'Alarm Dering',
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
                            'Ingatkan',
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
                                (0, 'Tepat waktu', 4),
                                (5, '5 mnt', 3),
                                (10, '10 mnt', 3),
                                (15, '15 mnt', 3),
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

            // === BLOK 3: KATEGORI (Scroll Horizontal Ramping) ===
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Text(
                'KATEGORI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: AppColors.categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  final icon = AppColors.categoryIcon(category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentSoft(isDark) : cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? accentColor : borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: isSelected ? accentColor : textMuted),
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? accentColor : textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // === BLOK 4: PENGULANGAN (Segmented 1 Baris Penuh) ===
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Text(
                'PENGULANGAN',
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
                ('none', 'Sekali'),
                ('daily', 'Tiap Hari'),
                ('weekdays', 'Sen - Jum'),
                ('weekends', 'Sab - Min'),
              ].map((item) {
                final isSelected = _repeatType == item.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _repeatType = item.$1),
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
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 11,
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
                onPressed: _savePlan,
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
