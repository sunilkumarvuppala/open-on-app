import '../models/models.dart';

/// Abstract repository for capsule operations
/// TODO: Implement concrete class with backend integration (Supabase, Firebase, etc.)
abstract class CapsuleRepository {
  /// Get all capsules for the current user (both sent and received)
  Future<List<Capsule>> getCapsules();

  /// Get capsules sent by current user
  Future<List<Capsule>> getSentCapsules();

  /// Get capsules received by current user
  Future<List<Capsule>> getReceivedCapsules();

  /// Get a specific capsule by ID
  Future<Capsule?> getCapsule(String id);

  /// Create a new capsule
  Future<Capsule> createCapsule({
    required String recipientId,
    required String recipientName,
    required String letterText,
    required DateTime unlockTime,
    required String label,
    String? photoPath,
  });

  /// Mark a capsule as opened
  Future<Capsule> markAsOpened(String capsuleId);

  /// Add a reaction to an opened capsule
  Future<Capsule> addReaction(String capsuleId, CapsuleReaction reaction);

  /// Delete a capsule (if not yet unlocked)
  Future<void> deleteCapsule(String capsuleId);
}

/// Abstract repository for recipient operations
/// TODO: Implement concrete class with backend integration
abstract class RecipientRepository {
  /// Get all recipients for the current user
  Future<List<Recipient>> getRecipients();

  /// Get a specific recipient by ID
  Future<Recipient?> getRecipient(String id);

  /// Create a new recipient
  Future<Recipient> createRecipient({
    required String name,
    String? relationship,
    String? avatarPath,
  });

  /// Update a recipient
  Future<Recipient> updateRecipient(Recipient recipient);

  /// Delete a recipient
  Future<void> deleteRecipient(String id);

  /// Search recipients by name
  Future<List<Recipient>> searchRecipients(String query);
}

/// Abstract repository for user/auth operations
/// TODO: Implement concrete class with backend authentication
abstract class UserRepository {
  /// Get the current authenticated user
  Future<AppUser?> getCurrentUser();

  /// Sign up with email and password
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  });

  /// Sign in with email and password
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  /// Sign out
  Future<void> signOut();

  /// Update user profile
  Future<AppUser> updateProfile({
    String? name,
    String? avatarPath,
  });

  /// Send password reset email
  Future<void> resetPassword(String email);

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}

/// Abstract repository for notifications
/// TODO: Implement with push notification service
abstract class NotificationRepository {
  /// Send notification when capsule is opened
  Future<void> notifyCapsuleOpened({
    required String senderId,
    required String capsuleId,
    required String recipientName,
  });

  /// Send notification when capsule is about to unlock
  Future<void> notifyUnlockingSoon({
    required String userId,
    required String capsuleId,
    required Duration timeRemaining,
  });

  /// Get user's notifications
  Future<List<AppNotification>> getNotifications();

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);
}

/// Notification model
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.data,
  });
}
