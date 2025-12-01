import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

/// Mock implementation of CapsuleRepository for MVP
/// TODO: Replace with real backend implementation
class MockCapsuleRepository implements CapsuleRepository {
  static const String _capsulesKey = 'capsules';
  static const String _currentUserIdKey = 'current_user_id';
  final _uuid = const Uuid();

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey) ?? 'mock_user_1';
  }

  Future<List<Capsule>> _loadCapsules() async {
    final prefs = await SharedPreferences.getInstance();
    final capsulesJson = prefs.getString(_capsulesKey);
    if (capsulesJson == null) return [];
    
    final List<dynamic> decoded = json.decode(capsulesJson);
    return decoded.map((json) => Capsule.fromJson(json)).toList();
  }

  Future<void> _saveCapsules(List<Capsule> capsules) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(capsules.map((c) => c.toJson()).toList());
    await prefs.setString(_capsulesKey, encoded);
  }

  @override
  Future<List<Capsule>> getCapsules() async {
    return await _loadCapsules();
  }

  @override
  Future<List<Capsule>> getSentCapsules() async {
    final userId = await _getCurrentUserId();
    final all = await _loadCapsules();
    return all.where((c) => c.senderId == userId).toList();
  }

  @override
  Future<List<Capsule>> getReceivedCapsules() async {
    final userId = await _getCurrentUserId();
    final all = await _loadCapsules();
    return all.where((c) => c.recipientId == userId).toList();
  }

  @override
  Future<Capsule?> getCapsule(String id) async {
    final all = await _loadCapsules();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Capsule> createCapsule({
    required String recipientId,
    required String recipientName,
    required String letterText,
    required DateTime unlockTime,
    required String label,
    String? photoPath,
  }) async {
    final userId = await _getCurrentUserId();
    final capsule = Capsule(
      id: _uuid.v4(),
      senderId: userId,
      recipientId: recipientId,
      recipientName: recipientName,
      letterText: letterText,
      unlockTime: unlockTime,
      createdAt: DateTime.now(),
      label: label,
      localPhotoPath: photoPath,
    );

    final all = await _loadCapsules();
    all.add(capsule);
    await _saveCapsules(all);
    
    return capsule;
  }

  @override
  Future<Capsule> markAsOpened(String capsuleId) async {
    final all = await _loadCapsules();
    final index = all.indexWhere((c) => c.id == capsuleId);
    if (index == -1) throw Exception('Capsule not found');

    final updated = all[index].copyWith(openedAt: DateTime.now());
    all[index] = updated;
    await _saveCapsules(all);
    
    // TODO: Trigger notification to sender
    return updated;
  }

  @override
  Future<Capsule> addReaction(String capsuleId, CapsuleReaction reaction) async {
    final all = await _loadCapsules();
    final index = all.indexWhere((c) => c.id == capsuleId);
    if (index == -1) throw Exception('Capsule not found');

    final updated = all[index].copyWith(reaction: reaction);
    all[index] = updated;
    await _saveCapsules(all);
    
    // TODO: Notify sender of reaction
    return updated;
  }

  @override
  Future<void> deleteCapsule(String capsuleId) async {
    final all = await _loadCapsules();
    all.removeWhere((c) => c.id == capsuleId);
    await _saveCapsules(all);
  }
}

/// Mock implementation of RecipientRepository
class MockRecipientRepository implements RecipientRepository {
  static const String _recipientsKey = 'recipients';
  static const String _currentUserIdKey = 'current_user_id';
  final _uuid = const Uuid();

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey) ?? 'mock_user_1';
  }

  Future<List<Recipient>> _loadRecipients() async {
    final prefs = await SharedPreferences.getInstance();
    final recipientsJson = prefs.getString(_recipientsKey);
    if (recipientsJson == null) {
      // Return default recipients for demo
      return [
        Recipient(
          id: 'recipient_1',
          name: 'Priya',
          relationship: 'Partner',
        ),
        Recipient(
          id: 'recipient_2',
          name: 'Ananya',
          relationship: 'Daughter',
        ),
        Recipient(
          id: 'recipient_3',
          name: 'Mom',
          relationship: 'Mother',
        ),
      ];
    }
    
    final List<dynamic> decoded = json.decode(recipientsJson);
    return decoded.map((json) => Recipient.fromJson(json)).toList();
  }

  Future<void> _saveRecipients(List<Recipient> recipients) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(recipients.map((r) => r.toJson()).toList());
    await prefs.setString(_recipientsKey, encoded);
  }

  @override
  Future<List<Recipient>> getRecipients() async {
    return await _loadRecipients();
  }

  @override
  Future<Recipient?> getRecipient(String id) async {
    final all = await _loadRecipients();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Recipient> createRecipient({
    required String name,
    String? relationship,
    String? avatarPath,
  }) async {
    final recipient = Recipient(
      id: _uuid.v4(),
      name: name,
      relationship: relationship,
      localAvatarPath: avatarPath,
    );

    final all = await _loadRecipients();
    all.add(recipient);
    await _saveRecipients(all);
    
    return recipient;
  }

  @override
  Future<Recipient> updateRecipient(Recipient recipient) async {
    final all = await _loadRecipients();
    final index = all.indexWhere((r) => r.id == recipient.id);
    if (index == -1) throw Exception('Recipient not found');

    all[index] = recipient;
    await _saveRecipients(all);
    
    return recipient;
  }

  @override
  Future<void> deleteRecipient(String id) async {
    final all = await _loadRecipients();
    all.removeWhere((r) => r.id == id);
    await _saveRecipients(all);
  }

  @override
  Future<List<Recipient>> searchRecipients(String query) async {
    final all = await _loadRecipients();
    final lowerQuery = query.toLowerCase();
    return all.where((r) => 
      r.name.toLowerCase().contains(lowerQuery) ||
      (r.relationship?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }
}

/// Mock implementation of UserRepository
class MockUserRepository implements UserRepository {
  static const String _currentUserKey = 'current_user';
  static const String _currentUserIdKey = 'current_user_id';

  @override
  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson == null) return null;
    
    return AppUser.fromJson(json.decode(userJson));
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // TODO: Implement real authentication
    final user = AppUser(
      id: 'mock_user_1',
      email: email,
      name: name,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
    await prefs.setString(_currentUserIdKey, user.id);
    
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // TODO: Implement real authentication
    // For MVP, just create a mock user
    final user = AppUser(
      id: 'mock_user_1',
      email: email,
      name: 'Demo User',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
    await prefs.setString(_currentUserIdKey, user.id);
    
    return user;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_currentUserIdKey);
  }

  @override
  Future<AppUser> updateProfile({
    String? name,
    String? avatarPath,
  }) async {
    final current = await getCurrentUser();
    if (current == null) throw Exception('No user logged in');

    final updated = current.copyWith(
      name: name,
      localAvatarPath: avatarPath,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(updated.toJson()));
    
    return updated;
  }

  @override
  Future<void> resetPassword(String email) async {
    // TODO: Implement password reset
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }
}

/// Mock implementation of NotificationRepository
class MockNotificationRepository implements NotificationRepository {
  @override
  Future<void> notifyCapsuleOpened({
    required String senderId,
    required String capsuleId,
    required String recipientName,
  }) async {
    // TODO: Implement push notifications
    print('📬 Notification: Your letter to $recipientName was opened ♥');
  }

  @override
  Future<void> notifyUnlockingSoon({
    required String userId,
    required String capsuleId,
    required Duration timeRemaining,
  }) async {
    // TODO: Implement push notifications
    print('⏰ Notification: A letter unlocks soon!');
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    // TODO: Implement real notifications
    return [];
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // TODO: Implement
  }
}
