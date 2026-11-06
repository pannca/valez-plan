class PlanModel {
  final int? id;
  final String title;
  final String notes;
  final DateTime scheduledTime;
  final bool isAlarmEnabled;
  final bool isCompleted;
  final String category;

  PlanModel({
    this.id,
    required this.title,
    this.notes = '',
    required this.scheduledTime,
    this.isAlarmEnabled = true,
    this.isCompleted = false,
    this.category = 'Umum',
  });

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
      category: (map['category'] as String?) ?? 'Umum',
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
  }) {
    return PlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
    );
  }
}

