import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';

class AddPlanSheet extends StatefulWidget {
  final VoidCallback onPlanAdded;
  final DateTime? initialDate;

  const AddPlanSheet({
    super.key,
    required this.onPlanAdded,
    this.initialDate,
  });

  @override
  State<AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<AddPlanSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Kerja';
  String _repeatType = 'none'; // 'none', 'daily', 'weekdays', 'weekends'
  bool _isAlarmEnabled = true;

  final Map<String, ({Color color, IconData icon})> _categoryConfig = {
    'Kerja': (color: const Color(0xFF388AF6), icon: Icons.business_center_rounded),
    'Belajar': (color: const Color(0xFFA259FF), icon: Icons.auto_stories_rounded),
    'Ibadah': (color: const Color(0xFF1DD1A1), icon: Icons.spa_rounded),
    'Istirahat': (color: const Color(0xFFFF9F43), icon: Icons.local_cafe_rounded),
    'Santai': (color: const Color(0xFFFF5252), icon: Icons.sports_esports_rounded),
    'Umum': (color: const Color(0xFF54A0FF), icon: Icons.task_alt_rounded),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF388AF6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E272E),
              onSurface: Colors.white,
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

    final targetDate = widget.initialDate ?? DateTime.now();
    final scheduledDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newPlan = PlanModel(
      title: title,
      notes: _notesController.text.trim(),
      scheduledTime: scheduledDateTime,
      isAlarmEnabled: _isAlarmEnabled,
      category: _selectedCategory,
      repeatType: _repeatType,
    );

    final id = await DatabaseService.instance.insertPlan(newPlan);

    if (_isAlarmEnabled && scheduledDateTime.isAfter(DateTime.now())) {
      await AlarmService.instance.scheduleAlarm(
        id: id,
        dateTime: scheduledDateTime,
        title: title,
        notes: _notesController.text.trim(),
      );
    }

    widget.onPlanAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = _categoryConfig[_selectedCategory]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2D3436) : const Color(0xFFF1F2F6);
    final textMain = isDark ? Colors.white : const Color(0xFF2D3748);
    final textMuted = isDark ? const Color(0xFF808E9B) : const Color(0xFF718096);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Baris Handle Atas
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

            // Header Modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Agenda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded,
                      color: textMuted, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input Judul
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                    color: textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Nama kegiatan...',
                  hintStyle: TextStyle(color: textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Baris Waktu & Alarm
            Row(
              children: [
                // Tombol Pilih Jam
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: Color(0xFF388AF6), size: 20),
                              const SizedBox(width: 8),
                              Text('Waktu',
                                  style: TextStyle(
                                      color: textMain,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Color(0xFF388AF6),
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Toggle Alarm
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm_rounded,
                        color: _isAlarmEnabled
                            ? const Color(0xFFFF9F43)
                            : textMuted,
                        size: 20,
                      ),
                      Switch(
                        value: _isAlarmEnabled,
                        activeThumbColor: const Color(0xFFFF9F43),
                        activeTrackColor:
                            const Color(0xFFFF9F43).withValues(alpha: 0.3),
                        onChanged: (val) =>
                            setState(() => _isAlarmEnabled = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kategori Chips dengan Ikon
            Text(
              'KATEGORI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryConfig.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                final color = entry.value.color;
                final icon = entry.value.icon;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.2)
                          : inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: isSelected ? color : textMuted),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? color : textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Ulangi Jadwal (Rutinitas)
            Text(
              'ULANGI JADWAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('none', 'Sekali', Icons.event_available_rounded),
                ('daily', 'Tiap Hari', Icons.repeat_rounded),
                ('weekdays', 'Sen - Jum', Icons.calendar_view_week_rounded),
                ('weekends', 'Sab - Min', Icons.weekend_rounded),
              ].map((item) {
                final isSelected = _repeatType == item.$1;
                return GestureDetector(
                  onTap: () => setState(() => _repeatType = item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF388AF6).withValues(alpha: 0.2)
                          : inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF388AF6) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$3,
                          size: 15,
                          color: isSelected ? const Color(0xFF388AF6) : textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF388AF6) : textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Input Catatan
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                minLines: 1,
                style: TextStyle(color: textMain, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Catatan tambahan...',
                  hintStyle: TextStyle(color: textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeConfig.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _savePlan,
                child: const Text(
                  'Simpan Agenda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
