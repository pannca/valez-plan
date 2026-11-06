import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';

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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kerja':
        return Icons.business_center_rounded;
      case 'belajar':
        return Icons.auto_stories_rounded;
      case 'ibadah':
        return Icons.spa_rounded;
      case 'istirahat':
        return Icons.local_cafe_rounded;
      case 'santai':
        return Icons.sports_esports_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  String _getTimeRemainingText(DateTime scheduledTime) {
    final now = DateTime.now();
    final diff = scheduledTime.difference(now);

    if (diff.isNegative) {
      if (diff.inMinutes.abs() < 2) return 'Sekarang';
      if (diff.inMinutes.abs() < 60) return 'Lewat ${diff.inMinutes.abs()}m';
      return 'Terlewat';
    }

    if (diff.inSeconds <= 60) {
      return '1m lagi';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lagi';
    } else if (diff.inHours < 24 && scheduledTime.day == now.day) {
      return '${diff.inHours}j ${diff.inMinutes % 60}m lagi';
    } else {
      final daysDiff = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (daysDiff == 1) return 'Besok';
      return '$daysDiff hari lagi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(plan.scheduledTime);
    final categoryIcon = _getCategoryIcon(plan.category);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? (plan.isCompleted
            ? const Color(0xFF14171A).withValues(alpha: 0.6)
            : const Color(0xFF1E272E))
        : (plan.isCompleted
            ? const Color(0xFFF8FAFC)
            : Colors.white);

    // Border netral profesional yang tenang dan konsisten
    final borderColor = isDark
        ? const Color(0xFF2D3436)
        : const Color(0xFFE2E8F0);

    final textMain = isDark
        ? (plan.isCompleted ? const Color(0xFF636E72) : Colors.white)
        : (plan.isCompleted ? const Color(0xFFA0AEC0) : const Color(0xFF2D3748));
    final textNotes = isDark
        ? (plan.isCompleted ? const Color(0xFF485460) : const Color(0xFF808E9B))
        : (plan.isCompleted ? const Color(0xFFA0AEC0) : const Color(0xFF718096));
    final timeColor = plan.isCompleted
        ? (isDark ? const Color(0xFF636E72) : const Color(0xFFA0AEC0))
        : (isDark ? const Color(0xFFDFE6E9) : const Color(0xFF2D3748));
    final spineLineColor = isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0);
    final nodeBg = isDark ? const Color(0xFF1E272E) : Colors.white;

    return Dismissible(
      key: Key('plan_${plan.id}_${plan.isCompleted}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(left: 60, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFFF5252), size: 24),
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
                        width: 2,
                        color: spineLineColor,
                      ),
                    ),
                  ),

                  // Node Tombol Ceklis
                  GestureDetector(
                    onTap: () => onToggleComplete(!plan.isCompleted),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: plan.isCompleted
                            ? const Color(0xFF388AF6)
                            : nodeBg,
                        border: Border.all(
                          color: plan.isCompleted
                              ? const Color(0xFF388AF6)
                              : (isDark ? const Color(0xFF3A444C) : const Color(0xFFCBD5E0)),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        plan.isCompleted ? Icons.check_rounded : categoryIcon,
                        size: 15,
                        color: plan.isCompleted
                            ? Colors.white
                            : (isDark ? const Color(0xFF808E9B) : const Color(0xFF718096)),
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
                onTap: onEdit,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Atas: Judul & Kapsul Alarm Minimalis
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
                                decorationColor: isDark ? const Color(0xFF636E72) : const Color(0xFFA0AEC0),
                                decorationThickness: 1.5,
                              ),
                            ),
                          ),
                          // Kapsul Alarm Monokrom Sleek (Satu kapsul untuk jam & countdown)
                          if (plan.isAlarmEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF242C34) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2D3436) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.alarm_rounded,
                                    size: 11,
                                    color: textNotes,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : const Color(0xFF2D3748),
                                    ),
                                  ),
                                  if (!plan.isCompleted) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textNotes,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getTimeRemainingText(plan.scheduledTime),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF388AF6),
                                      ),
                                    ),
                                  ],
                                  if (plan.earlyReminderMinutes > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textNotes,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '-${plan.earlyReminderMinutes}m',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: textNotes,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Catatan Tambahan jika ada
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

                      const SizedBox(height: 8),

                      // Baris Bawah: Kategori & Repeat Ringkas Bersih
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF388AF6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            plan.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: textNotes,
                            ),
                          ),
                          if (plan.repeatType != 'none') ...[
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(fontSize: 10, color: textNotes)),
                            const SizedBox(width: 8),
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
                          if (onEdit != null)
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: textNotes.withValues(alpha: 0.5),
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
