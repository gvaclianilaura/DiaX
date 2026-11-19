class CalendarEvent {
  final int? id;
  final int userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? createdAt;

  CalendarEvent({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.createdAt,
  });

  // Превращаем в JSON для отправки POST-запроса на бэкенд
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description ?? '',
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }

  // Создаем объект из ответа сервера (GET)
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      createdAt: json['created_at'],
    );
  }
}