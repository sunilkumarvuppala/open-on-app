import 'package:openon_app/core/models/models.dart';

/// Shared utility for mapping user JSON to User model
/// Prevents code duplication and ensures consistent mapping logic
class UserMapper {
  UserMapper._();

  /// Safely maps JSON to User model with null checks and type validation
  /// 
  /// Handles:
  /// - Null values gracefully
  /// - Type mismatches (non-String values)
  /// - Missing fields with fallback values
  /// - Backend field name variations (id vs user_id)
  static User fromJson(Map<String, dynamic> json) {
    // Backend returns 'user_id' (UUID) from UserProfileResponse, but may also have 'id'
    final idValue = json['user_id'] ?? json['id'];
    final fullNameValue = json['full_name'];
    final usernameValue = json['username'];
    final emailValue = json['email'];
    final avatarValue = json['avatar_url'] ?? json['avatar']; // Backend uses avatar_url
    
    // Convert UUID to string if needed
    String? userIdString;
    if (idValue != null) {
      if (idValue is String) {
        userIdString = idValue;
      } else {
        userIdString = idValue.toString();
      }
    }
    
    return User(
      id: userIdString ?? '',
      name: _safeString(fullNameValue) ?? _safeString(usernameValue) ?? '',
      email: _safeString(emailValue) ?? '',
      username: _safeString(usernameValue) ?? '',
      avatar: _safeString(avatarValue) ?? '',
    );
  }

  /// Safely converts a value to String, handling null and non-String types
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }
}

