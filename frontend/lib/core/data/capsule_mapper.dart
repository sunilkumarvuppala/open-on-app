import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/utils/logger.dart';

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
        final recipientAvatarUrlValue = json['recipient_avatar_url'];
        final titleValue = json['title'];
        final bodyTextValue = json['body_text'];
        final bodyRichTextValue = json['body_rich_text'];
        final unlocksAtValue = json['unlocks_at'];
        final openedAtValue = json['opened_at'];
        final createdAtValue = json['created_at'];
        
        // Anonymous letter fields
        final isAnonymousValue = json['is_anonymous'];
        final revealDelaySecondsValue = json['reveal_delay_seconds'];
        final revealAtValue = json['reveal_at'];
        final senderRevealedAtValue = json['sender_revealed_at'];
        
        // Extract content from body_text or body_rich_text
        final content = _extractContent(bodyTextValue, bodyRichTextValue);
        
        // Parse dates safely
        final unlockAt = _parseDateTime(unlocksAtValue, fallbackDays: 1)!;
        final createdAt = _parseDateTime(createdAtValue, fallbackDays: 0)!;
        final openedAt = _parseDateTime(openedAtValue, nullable: true);
        final revealAt = _parseDateTime(revealAtValue, nullable: true);
        final senderRevealedAt = _parseDateTime(senderRevealedAtValue, nullable: true);
        
        // Parse anonymous fields
        final isAnonymous = isAnonymousValue is bool ? isAnonymousValue : (isAnonymousValue == true || isAnonymousValue == 'true');
        final revealDelaySeconds = revealDelaySecondsValue is int 
            ? revealDelaySecondsValue 
            : (revealDelaySecondsValue is String ? int.tryParse(revealDelaySecondsValue) : null);
        
        // Get sender name (respects anonymous status)
        // If anonymous and not revealed, show 'Anonymous'
        // Otherwise use actual sender name or fallback
        String senderName;
        if (isAnonymous && senderRevealedAt == null && revealAt != null) {
          final now = DateTime.now();
          if (revealAt.isAfter(now)) {
            // Not yet revealed
            senderName = 'Anonymous';
          } else {
            // Reveal time has passed, show actual name
            senderName = _safeString(senderNameValue) ?? 
                (_safeString(senderIdValue) != null ? 'Sender' : 'Anonymous');
          }
        } else if (isAnonymous && senderRevealedAt == null) {
          // Anonymous but no reveal time set yet (shouldn't happen, but handle gracefully)
          senderName = 'Anonymous';
        } else {
          // Not anonymous or already revealed
          senderName = _safeString(senderNameValue) ?? 
              (_safeString(senderIdValue) != null ? 'Sender' : 'Anonymous');
        }
        
        // Get recipient name (fallback to 'Recipient' if not provided)
        final recipientName = _safeString(recipientNameValue) ?? 'Recipient';
        
        // Log recipient avatar for debugging
        final recipientAvatarUrl = _safeString(recipientAvatarUrlValue);
        if (recipientAvatarUrl == null || recipientAvatarUrl.isEmpty) {
          // Log when avatar is missing to help debug
          // Note: This is a debug log, can be removed later
        }
        
        // Log opened_at for debugging opened status
        final capsuleId = _safeString(idValue) ?? '';
        if (openedAt != null) {
          Logger.debug('Capsule $capsuleId has openedAt: $openedAt');
        } else {
          Logger.debug('Capsule $capsuleId has no openedAt (status will be computed from unlockAt)');
        }
        
        return Capsule(
            id: capsuleId,
            senderId: _safeString(senderIdValue) ?? '',
            senderName: senderName,  // Use actual sender name from backend (or 'Anonymous')
            senderAvatarValue: _safeString(senderAvatarUrlValue),
            receiverId: _safeString(recipientIdValue) ?? '',
            receiverName: recipientName,  // Use actual recipient name from backend
            receiverAvatarValue: recipientAvatarUrl,
            label: _safeString(titleValue) ?? '',
            content: content,
            photoUrl: null, // Media URLs not in current schema
            unlockAt: unlockAt,
            createdAt: createdAt,
            openedAt: openedAt,
            isAnonymous: isAnonymous,
            revealDelaySeconds: revealDelaySeconds,
            revealAt: revealAt,
            senderRevealedAt: senderRevealedAt,
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

