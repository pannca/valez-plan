import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../services/tolerance_service.dart';
import '../theme/app_colors.dart';

class PlanCard extends StatelessWidget {
  final PlanModel plan;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final bool isFirst;
  final bool isLast;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onToggleComplete,
    required this.onDelete,
    this.onEdit,
    this.isFirst = false,
    this.isLast = false,
  });

  String _getTimeRemainingText(DateTime scheduledTime) {
    final now = DateTime.now();
    final diff = scheduledTime.difference(now);

    if (diff.isNegative) {
      if (diff.inMinutes.abs() < 2) return 'Sekarang';
      final isExpired = ToleranceService.instance.isPastToleranceDeadline(scheduledTime);
      if (isExpired) return 'Terlewat';
      if (diff.inMinutes.abs() < 60) return '${diff.inMinutes.abs()}m lalu';
      final h = diff.inMinutes.abs() ~/ 60;
      return '${h}j lalu';
    }

    if (diff.inSeconds <= 60) {
      return '1m lagi';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lagi';
    } else if (diff.inHours < 24 && scheduledTime.day == now.day) {
      return '${diff.inHours}j lagi';
    } else {
      final daysDiff = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (daysDiff == 1) return 'Besok';
      return '$daysDiff hr lagi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(plan.scheduledTime);
    final categoryIcon = AppColors.categoryIcon(plan.category);
    final isExpired = ToleranceService.instance.isPlanExpired(plan);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppColors.accent(isDark);
    final cardBg = plan.isCompleted
        ? AppColors.bg(isDark)
        : (isExpired
            ? AppColors.surfaceSubtle(isDark).withValues(alpha: 0.4)
            : AppColors.surface(isDark));

    final borderColor = AppColors.border(isDark);

    final textMain = plan.isCompleted
        ? AppColors.faint(isDark)
        : (isExpired ? AppColors.muted(isDark) : AppColors.ink(isDark));
    final textNotes = plan.isCompleted || isExpired
        ? AppColors.faint(isDark)
        : AppColors.muted(isDark);
    final timeColor = plan.isCompleted || isExpired
        ? AppColors.faint(isDark)
        : AppColors.ink(isDark);
    final spineLineColor = AppColors.border(isDark);
    final nodeBg = isExpired
        ? AppColors.surfaceSubtle(isDark)
        : AppColors.surface(isDark);

    return Dismissible(
      key: Key('plan_${plan.id}_${plan.isCompleted}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(left: 60, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.statusSoft(AppColors.danger, isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.statusBorder(AppColors.danger, isDark),
          ),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kolom 1: Jam Waktu di Sisi Kiri
            SizedBox(
              width: 44,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  timeStr,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: timeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Kolom 2: Garis Timeline Vertikal & Node Ikon
            SizedBox(
              width: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Garis Penghubung Vertikal
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 1.5,
                        color: spineLineColor,
                      ),
                    ),
                  ),

                  // Node Tombol Ceklis
                  GestureDetector(
                    onTap: () {
                      if (isExpired) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Jadwal telah terlewat dan terkunci.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (plan.isCompleted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Jadwal sudah selesai dan terkunci.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      onToggleComplete(true);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: plan.isCompleted
                            ? accentColor
                            : (isExpired ? AppColors.surfaceSubtle(isDark) : nodeBg),
                        border: Border.all(
                          color: plan.isCompleted
                              ? accentColor
                              : (isExpired ? AppColors.border(isDark) : borderColor),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        plan.isCompleted ? Icons.check_rounded : categoryIcon,
                        size: 15,
                        color: plan.isCompleted
                            ? Colors.white
                            : (isExpired ? AppColors.faint(isDark) : AppColors.muted(isDark)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Kolom 3: Kartu Agenda Minimalis Profesional
            Expanded(
              child: InkWell(
                onTap: () {
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
                  if (isExpired) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jadwal telah terlewat dan tidak dapat diedit.'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  onEdit?.call();
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris 1: Judul Agenda & Status Tag Sederhana (Hanya saat Selesai/Terlewat)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              plan.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textMain,
                                decoration: plan.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: AppColors.faint(isDark),
                                decorationThickness: 1.5,
                              ),
                            ),
                          ),
                          if (isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.statusSoft(AppColors.danger, isDark),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.statusBorder(AppColors.danger, isDark),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'TERLEWAT',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.danger,
                                ),
                              ),
                            )
                          else if (plan.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.statusSoft(AppColors.success, isDark),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.statusBorder(AppColors.success, isDark),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'SELESAI',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Baris 2: Catatan Tambahan (jika ada)
                      if (plan.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          plan.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: textNotes,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Baris 3: Meta Terpadu (Waktu Alarm, Hitung Mundur, Kategori, & Aksi Edit)
                      Row(
                        children: [
                          if (plan.isAlarmEnabled) ...[
                            Icon(
                              Icons.alarm_rounded,
                              size: 12,
                              color: textNotes,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: textNotes,
                            ),
                          ),
                          if (!plan.isCompleted && !isExpired) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(fontSize: 10, color: textNotes)),
                            const SizedBox(width: 6),
                            Text(
                              _getTimeRemainingText(plan.scheduledTime),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(fontSize: 10, color: textNotes)),
                          const SizedBox(width: 6),
                          Text(
                            plan.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: textNotes,
                            ),
                          ),
                          if (plan.repeatType != 'none') ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(fontSize: 10, color: textNotes)),
                            const SizedBox(width: 6),
                            Text(
                              plan.repeatType == 'daily'
                                  ? 'Tiap Hari'
                                  : (plan.repeatType == 'weekdays' ? 'Sen-Jum' : 'Sab-Min'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: textNotes,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (onEdit != null && !isExpired && !plan.isCompleted)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textNotes.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 13,
                                  color: textNotes.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
