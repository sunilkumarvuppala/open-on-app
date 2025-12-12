import 'package:openon_app/core/models/models.dart';

/// Shared utility for mapping capsule JSON to Capsule model
/// Prevents code duplication and ensures consistent mapping logic
class CapsuleMapper {
  CapsuleMapper._();

  /// Safely maps JSON to Capsule model with null checks and type validation
  /// 
  /// Handles:
  /// - Null values gracefully
  /// - Type mismatches (non-String values)
  /// - Missing fields with fallback values
  /// - Date parsing with error handling
  /// - Backend field name variations
    static Capsule fromJson(Map<String, dynamic> json) {
        final idValue = json['id'];
        final senderIdValue = json['sender_id'];
        final senderNameValue = json['sender_name'];  // Backend now returns sender_name
        final senderAvatarUrlValue = json['sender_avatar_url'];
        final recipientIdValue = json['recipient_id'];
        final recipientNameValue = json['recipient_name'];  // Backend now returns recipient_name
        final titleValue = json['title'];
        final bodyTextValue = json['body_text'];
        final bodyRichTextValue = json['body_rich_text'];
        final unlocksAtValue = json['unlocks_at'];
        final openedAtValue = json['opened_at'];
        final createdAtValue = json['created_at'];
        
        // Extract content from body_text or body_rich_text
        final content = _extractContent(bodyTextValue, bodyRichTextValue);
        
        // Parse dates safely
        final unlockAt = _parseDateTime(unlocksAtValue, fallbackDays: 1)!;
        final createdAt = _parseDateTime(createdAtValue, fallbackDays: 0)!;
        final openedAt = _parseDateTime(openedAtValue, nullable: true);
        
        // Get sender name (fallback to 'Anonymous' or 'Sender' if not provided)
        final senderName = _safeString(senderNameValue) ?? 
            (_safeString(senderIdValue) != null ? 'Sender' : 'Anonymous');
        
        // Get recipient name (fallback to 'Recipient' if not provided)
        final recipientName = _safeString(recipientNameValue) ?? 'Recipient';
        
        return Capsule(
            id: _safeString(idValue) ?? '',
            senderId: _safeString(senderIdValue) ?? '',
            senderName: senderName,  // Use actual sender name from backend
            receiverId: _safeString(recipientIdValue) ?? '',
            receiverName: recipientName,  // Use actual recipient name from backend
            receiverAvatar: _safeString(senderAvatarUrlValue) ?? '',
            label: _safeString(titleValue) ?? '',
            content: content,
            photoUrl: null, // Media URLs not in current schema
            unlockAt: unlockAt,
            createdAt: createdAt,
            openedAt: openedAt,
        );
    }

  /// Extracts content from body_text or body_rich_text
  static String _extractContent(dynamic bodyText, dynamic bodyRichText) {
    if (bodyText != null && bodyText is String && bodyText.isNotEmpty) {
      return bodyText;
    }
    if (bodyRichText != null) {
      if (bodyRichText is String) {
        return bodyRichText;
      }
      if (bodyRichText is Map) {
        return bodyRichText.toString();
      }
    }
    return '';
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

  /// Safely converts a value to String, handling null and non-String types
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }
}

