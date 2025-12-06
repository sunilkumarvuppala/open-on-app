import 'package:openon_app/core/models/models.dart';

/// Shared utility for mapping recipient JSON to Recipient model
/// Prevents code duplication and ensures consistent mapping logic
class RecipientMapper {
  RecipientMapper._();

  /// Safely maps JSON to Recipient model with null checks and type validation
  /// 
  /// Handles:
  /// - Null values gracefully
  /// - Type mismatches (non-String values)
  /// - Missing fields with fallback values
  /// - Backend field name variations (owner_id, avatar_url)
  static Recipient fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final ownerIdValue = json['owner_id'];
    final nameValue = json['name'];
    final relationshipValue = json['relationship'];
    final avatarUrlValue = json['avatar_url'];
    
    // Use avatar_url if available, otherwise empty string
    final avatar = _safeString(avatarUrlValue) ?? '';
    
    // Relationship defaults to 'friend' if not provided
    final relationship = (_safeString(relationshipValue)?.isNotEmpty == true)
        ? _safeString(relationshipValue)!
        : 'friend';
    
    return Recipient(
      id: _safeString(idValue) ?? '',
      userId: _safeString(ownerIdValue) ?? '',
      name: _safeString(nameValue) ?? '',
      relationship: relationship,
      avatar: avatar,
      linkedUserId: null, // Not in current Supabase schema
    );
  }

  /// Safely converts a value to String, handling null and non-String types
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }
}

