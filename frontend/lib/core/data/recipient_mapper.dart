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
  /// - UUID conversion (UUIDs can come as strings or UUID objects)
  static Recipient fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final ownerIdValue = json['owner_id'];
    final nameValue = json['name'];
    final usernameValue = json['username'];
    final avatarUrlValue = json['avatar_url'];
    
    // Convert UUID to string (handles both string and UUID types)
    final id = _convertToString(idValue);
    if (id == null || id.isEmpty) {
      throw Exception('Recipient ID is required but was null or empty');
    }
    
    final userId = _convertToString(ownerIdValue);
    if (userId == null || userId.isEmpty) {
      throw Exception('Recipient owner_id is required but was null or empty');
    }
    
    // Name is required
    final name = _safeString(nameValue);
    if (name == null || name.isEmpty) {
      throw Exception('Recipient name is required but was null or empty');
    }
    
          // Use avatar_url if available, otherwise empty string
          final avatar = _safeString(avatarUrlValue) ?? '';
          
          // Email is optional but important for inbox matching
          final email = _safeString(json['email']);
          
          // Username is optional (@username for display)
          final username = _safeString(usernameValue);
          
          // Get linked_user_id if present (for connections)
          final linkedUserIdValue = json['linked_user_id'];
          final linkedUserId = _convertToString(linkedUserIdValue);
          
          return Recipient(
            id: id,
            userId: userId,
            name: name,
            username: username,
            avatar: avatar,
            linkedUserId: linkedUserId,
            email: email, // Include email from backend
          );
  }
  
  /// Convert a value to string, handling UUID objects and other types
  static String? _convertToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    // Handle UUID objects (they have toString() method)
    return value.toString();
  }

  /// Safely converts a value to String, handling null and non-String types
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }
}

