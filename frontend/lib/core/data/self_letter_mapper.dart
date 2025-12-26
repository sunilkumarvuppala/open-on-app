import 'package:openon_app/core/models/models.dart';

/// Shared utility for mapping self letter JSON to SelfLetter model
class SelfLetterMapper {
  SelfLetterMapper._();

  /// Safely maps JSON to SelfLetter model with null checks and type validation
  static SelfLetter fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final userIdValue = json['user_id'];
    final titleValue = json['title'];
    final contentValue = json['content'];
    final charCountValue = json['char_count'];
    final scheduledOpenAtValue = json['scheduled_open_at'];
    final openedAtValue = json['opened_at'];
    final moodValue = json['mood'];
    final lifeAreaValue = json['life_area'];
    final cityValue = json['city'];
    final reflectionAnswerValue = json['reflection_answer'];
    final reflectedAtValue = json['reflected_at'];
    final sealedValue = json['sealed'];
    final createdAtValue = json['created_at'];
    
    // Parse dates safely
    final scheduledOpenAt = _parseDateTime(scheduledOpenAtValue, fallbackDays: 1)!;
    final createdAt = _parseDateTime(createdAtValue, fallbackDays: 0)!;
    final openedAt = _parseDateTime(openedAtValue, nullable: true);
    final reflectedAt = _parseDateTime(reflectedAtValue, nullable: true);
    
    // Parse boolean
    final sealed = sealedValue is bool ? sealedValue : (sealedValue == true || sealedValue == 'true');
    
    // Parse integers
    final charCount = charCountValue is int 
        ? charCountValue 
        : (charCountValue is String ? int.tryParse(charCountValue) ?? 0 : 0);
    
    return SelfLetter(
      id: _safeString(idValue) ?? '',
      userId: _safeString(userIdValue) ?? '',
      title: _safeString(titleValue),
      content: _safeString(contentValue),
      charCount: charCount,
      scheduledOpenAt: scheduledOpenAt,
      openedAt: openedAt,
      mood: _safeString(moodValue),
      lifeArea: _safeString(lifeAreaValue),
      city: _safeString(cityValue),
      reflectionAnswer: _safeString(reflectionAnswerValue),
      reflectedAt: reflectedAt,
      sealed: sealed,
      createdAt: createdAt,
    );
  }
  
  /// Safely parses a datetime string with error handling
  static DateTime? _parseDateTime(
    dynamic value, {
    int fallbackDays = 0,
    bool nullable = false,
  }) {
    if (value == null) {
      if (nullable) return null;
      return DateTime.now().add(Duration(days: fallbackDays));
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        // Fall through to default
      }
    }
    
    if (nullable) return null;
    return DateTime.now().add(Duration(days: fallbackDays));
  }
  
  /// Safely converts value to string
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }
  
  /// Converts SelfLetter to JSON for API requests
  static Map<String, dynamic> toJson(SelfLetter letter) {
    return {
      'content': letter.content ?? '',
      'scheduled_open_at': letter.scheduledOpenAt.toUtc().toIso8601String(),
      if (letter.title != null) 'title': letter.title,
      if (letter.mood != null) 'mood': letter.mood,
      if (letter.lifeArea != null) 'life_area': letter.lifeArea,
      if (letter.city != null) 'city': letter.city,
    };
  }
}
