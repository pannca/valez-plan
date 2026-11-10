class PlanModel {
  final int? id;
  final String title;
  final String notes;
  final DateTime scheduledTime;
  final bool isAlarmEnabled;
  final bool isCompleted;
  final String category;
  final String repeatType; // 'none', 'daily', 'weekly:1', 'custom:1,4', 'weekdays', 'weekends'
  final int earlyReminderMinutes; // 0 (tepat waktu), 5, 10, 15
  final DateTime? repeatUntil; // Tanggal akhir masa berlaku pengulangan (null = selamanya)

  PlanModel({
    this.id,
    required this.title,
    this.notes = '',
    required this.scheduledTime,
    this.isAlarmEnabled = true,
    this.isCompleted = false,
    this.category = 'Kerja',
    this.repeatType = 'none',
    this.earlyReminderMinutes = 0,
    this.repeatUntil,
  });

  String get repeatLabel {
    if (repeatType == 'daily') return 'Tiap Hari';
    if (repeatType == 'weekdays') return 'Sen-Jum';
    if (repeatType == 'weekends') return 'Sab-Min';
    if (repeatType.startsWith('weekly:')) {
      const dayNames = {
        1: 'Senin',
        2: 'Selasa',
        3: 'Rabu',
        4: 'Kamis',
        5: 'Jumat',
        6: 'Sabtu',
        7: 'Minggu',
      };
      final day = int.tryParse(repeatType.split(':')[1]);
      return 'Tiap ${dayNames[day] ?? 'Minggu'}';
    }
    if (repeatType.startsWith('custom:')) {
      const dayNames = {
        1: 'Sen',
        2: 'Sel',
        3: 'Rab',
        4: 'Kam',
        5: 'Jum',
        6: 'Sab',
        7: 'Min',
      };
      final days = repeatType
          .split(':')[1]
          .split(',')
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .map((d) => dayNames[d] ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
      return days.isEmpty ? 'Kustom' : days;
    }
    return '';
  }

  // Konversi ke Map untuk disimpan di database SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'scheduled_time': scheduledTime.toIso8601String(),
      'is_alarm_enabled': isAlarmEnabled ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'category': category,
      'repeat_type': repeatType,
      'early_reminder_minutes': earlyReminderMinutes,
      'repeat_until': repeatUntil?.toIso8601String(),
    };
  }

  // Konversi dari data SQLite ke object PlanModel
  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      notes: (map['notes'] as String?) ?? '',
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      isAlarmEnabled: (map['is_alarm_enabled'] as int) == 1,
      isCompleted: (map['is_completed'] as int) == 1,
      category: (map['category'] as String?) ?? 'Kerja',
      repeatType: (map['repeat_type'] as String?) ?? 'none',
      earlyReminderMinutes: (map['early_reminder_minutes'] as int?) ?? 0,
      repeatUntil: map['repeat_until'] != null
          ? DateTime.tryParse(map['repeat_until'] as String)
          : null,
    );
  }

  PlanModel copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? scheduledTime,
    bool? isAlarmEnabled,
    bool? isCompleted,
    String? category,
    String? repeatType,
    int? earlyReminderMinutes,
    DateTime? repeatUntil,
    bool clearRepeatUntil = false,
  }) {
    return PlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      repeatType: repeatType ?? this.repeatType,
      earlyReminderMinutes: earlyReminderMinutes ?? this.earlyReminderMinutes,
      repeatUntil: clearRepeatUntil ? null : (repeatUntil ?? this.repeatUntil),
    );
  }
}
