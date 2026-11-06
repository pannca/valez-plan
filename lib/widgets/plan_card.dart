import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';

class PlanCard extends StatelessWidget {
  final PlanModel plan;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback onDelete;
  final bool isFirst;
  final bool isLast;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onToggleComplete,
    required this.onDelete,
    this.isFirst = false,
    this.isLast = false,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kerja':
        return const Color(0xFF388AF6); // Structured Blue
      case 'belajar':
        return const Color(0xFFA259FF); // Structured Purple
      case 'ibadah':
        return const Color(0xFF1DD1A1); // Structured Mint
      case 'istirahat':
        return const Color(0xFFFF9F43); // Structured Orange
      case 'santai':
        return const Color(0xFFFF5252); // Structured Red
      default:
        return const Color(0xFF54A0FF);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(plan.scheduledTime);
    final categoryColor = _getCategoryColor(plan.category);
    final categoryIcon = _getCategoryIcon(plan.category);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? (plan.isCompleted
            ? const Color(0xFF14171A).withValues(alpha: 0.7)
            : const Color(0xFF1E272E))
        : (plan.isCompleted
            ? const Color(0xFFF1F2F6)
            : Colors.white);
    final borderColor = isDark
        ? (plan.isCompleted
            ? Colors.white.withValues(alpha: 0.04)
            : categoryColor.withValues(alpha: 0.25))
        : (plan.isCompleted
            ? const Color(0xFFE2E8F0)
            : categoryColor.withValues(alpha: 0.35));
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
          color: Colors.red.shade900.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 26),
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

                  // Node Tombol Ceklis / Ikon Kategori
                  GestureDetector(
                    onTap: () => onToggleComplete(!plan.isCompleted),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: plan.isCompleted
                            ? const Color(0xFF1DD1A1)
                            : nodeBg,
                        border: Border.all(
                          color: plan.isCompleted
                              ? const Color(0xFF1DD1A1)
                              : categoryColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        plan.isCompleted ? Icons.check_rounded : categoryIcon,
                        size: 16,
                        color: plan.isCompleted
                            ? Colors.black
                            : categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Kolom 3: Kartu Agenda ala Structured
            Expanded(
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
                    // Baris Atas: Judul & Alarm Pill
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
                        if (plan.isAlarmEnabled)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9F43)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.alarm_rounded,
                                      size: 12,
                                      color: Color(0xFFFF9F43),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF9F43),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (plan.earlyReminderMinutes > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF388AF6)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.hourglass_top_rounded,
                                        size: 10,
                                        color: Color(0xFF388AF6),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '-${plan.earlyReminderMinutes}m',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF388AF6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),

                    // Catatan
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

                    // Badge Kategori Minimalis & Repeat Pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        if (plan.repeatType != 'none') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF388AF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.repeat_rounded,
                                  size: 10,
                                  color: Color(0xFF388AF6),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  plan.repeatType == 'daily'
                                      ? 'Tiap Hari'
                                      : (plan.repeatType == 'weekdays'
                                          ? 'Sen-Jum'
                                          : 'Sab-Min'),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF388AF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
