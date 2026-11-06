import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySelectorBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DaySelectorBar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? const Color(0xFF1E272E) : Colors.white;
    final unselectedBorder = isDark ? Colors.transparent : const Color(0xFFE2E8F0);
    final unselectedNumColor = isDark ? Colors.white : const Color(0xFF2D3748);

    // Tampilkan 7 hari: 2 hari kemarin, hari ini, dan 4 hari ke depan
    final days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - 2 + i);
    });

    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          final isToday = day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;

          final dayName = DateFormat('EEE').format(day).toUpperCase();
          final dayNum = day.day.toString();

          return GestureDetector(
            onTap: () => onDateSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF388AF6)
                    : unselectedBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF388AF6)
                      : isToday
                          ? const Color(0xFF388AF6).withValues(alpha: 0.5)
                          : unselectedBorder,
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF808E9B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : unselectedNumColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

