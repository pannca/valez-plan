import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../models/routine_template.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';

class RoutineTemplateSheet extends StatefulWidget {
  final DateTime targetDate;
  final bool hasExistingPlans;
  final VoidCallback onTemplateApplied;

  const RoutineTemplateSheet({
    super.key,
    required this.targetDate,
    required this.hasExistingPlans,
    required this.onTemplateApplied,
  });

  @override
  State<RoutineTemplateSheet> createState() => _RoutineTemplateSheetState();
}

class _RoutineTemplateSheetState extends State<RoutineTemplateSheet> {
  final List<RoutineTemplate> _templates = RoutineTemplate.defaultTemplates;
  RoutineTemplate? _selectedTemplate;
  bool _isApplying = false;

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

  Future<void> _applyTemplate(RoutineTemplate template, {required bool replaceExisting}) async {
    setState(() => _isApplying = true);

    try {
      final date = widget.targetDate;

      // Jika user memilih ganti, hapus agenda hari ini terlebih dahulu
      if (replaceExisting) {
        final existing = await DatabaseService.instance.getPlansByDate(date);
        for (final p in existing) {
          if (p.id != null) {
            await DatabaseService.instance.deletePlan(p.id!);
            if (p.isAlarmEnabled) {
              await AlarmService.instance.cancelAlarm(p.id!);
            }
          }
        }
      }

      // Buat daftar PlanModel dari template
      final List<PlanModel> newPlans = [];
      for (final item in template.items) {
        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          item.hour,
          item.minute,
        );

        newPlans.add(
          PlanModel(
            title: item.title,
            notes: item.notes,
            scheduledTime: scheduledDateTime,
            isAlarmEnabled: item.isAlarmEnabled,
            category: item.category,
            repeatType: 'none',
          ),
        );
      }

      // Simpan ke SQLite
      final ids = await DatabaseService.instance.insertMultiplePlans(newPlans);

      // Pasang alarm jika hari ini dan waktunya belum terlewat
      final now = DateTime.now();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

      if (isToday) {
        for (int i = 0; i < newPlans.length; i++) {
          final plan = newPlans[i];
          final planId = ids[i];
          if (plan.isAlarmEnabled && plan.scheduledTime.isAfter(now)) {
            await AlarmService.instance.scheduleAlarm(
              id: planId,
              dateTime: plan.scheduledTime,
              title: plan.title,
              notes: plan.notes,
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onTemplateApplied();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E272E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                Icon(template.icon, color: template.accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Template "${template.title}" berhasil diterapkan!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error applying template: $e');
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  void _confirmAndApply(RoutineTemplate template) {
    if (!widget.hasExistingPlans) {
      _applyTemplate(template, replaceExisting: false);
      return;
    }

    // Dialog konfirmasi: Tambah atau Ganti
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E272E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Terapkan Template',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2D3748),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Timeline di tanggal ini sudah memiliki agenda. Bagaimana kamu ingin menerapkannya?',
            style: TextStyle(
              color: isDark ? const Color(0xFF808E9B) : const Color(0xFF718096),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _applyTemplate(template, replaceExisting: true);
              },
              child: const Text(
                'Ganti Semua',
                style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388AF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _applyTemplate(template, replaceExisting: false);
              },
              child: const Text('Gabungkan', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final cardBg = isDark ? const Color(0xFF14171A) : const Color(0xFFF7F9FC);
    final textMain = isDark ? Colors.white : const Color(0xFF2D3748);
    final textMuted = isDark ? const Color(0xFF808E9B) : const Color(0xFF718096);
    final borderColor = isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0);
    final dateFormatted = DateFormat('EEEE, d MMM').format(widget.targetDate);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Color(0xFF388AF6), size: 22),
                        const SizedBox(width: 6),
                        Text(
                          'Template Rutinitas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terapkan ke: $dateFormatted',
                      style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: textMuted, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Jika ada template yang sedang di-preview
          if (_selectedTemplate != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedTemplate!.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _selectedTemplate!.accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(_selectedTemplate!.icon, color: _selectedTemplate!.accentColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTemplate!.title,
                          style: TextStyle(
                            color: textMain,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_selectedTemplate!.items.length} kegiatan tersusun rapi',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedTemplate = null),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Ganti', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _selectedTemplate!.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _selectedTemplate!.items[index];
                  final catColor = _getCategoryColor(item.category);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.timeFormatted,
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: textMain,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (item.notes.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.notes,
                                  style: TextStyle(color: textMuted, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (item.isAlarmEnabled)
                          const Icon(Icons.alarm_rounded, size: 16, color: Color(0xFFFF9F43)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTemplate!.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isApplying ? null : () => _confirmAndApply(_selectedTemplate!),
                icon: _isApplying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isApplying ? 'Menerapkan...' : 'Terapkan Template Ini',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ] else ...[
            // Daftar pilihan template
            Expanded(
              child: ListView.separated(
                itemCount: _templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tmpl = _templates[index];

                  return InkWell(
                    onTap: () => setState(() => _selectedTemplate = tmpl),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: tmpl.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(tmpl.icon, color: tmpl.accentColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tmpl.title,
                                        style: TextStyle(
                                          color: textMain,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: tmpl.accentColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${tmpl.items.length} Jadwal',
                                        style: TextStyle(
                                          color: tmpl.accentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tmpl.subtitle,
                                  style: TextStyle(color: textMuted, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
