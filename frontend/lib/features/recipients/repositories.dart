import 'package:openon_app/core/models/models.dart';

/// Repository interface for capsule operations
/// TODO: Replace with actual backend implementation (e.g., Supabase, Firebase)
abstract class CapsuleRepository {
  Future<List<Capsule>> getCapsules({required String userId, bool asSender = true});
  Future<Capsule> createCapsule(Capsule capsule);
  Future<Capsule> updateCapsule(Capsule capsule);
  Future<void> deleteCapsule(String capsuleId);
  Future<void> markAsOpened(String capsuleId);
  Future<void> addReaction(String capsuleId, String reaction);
}

/// Mock implementation for development
class MockCapsuleRepository implements CapsuleRepository {
  final List<Capsule> _capsules = [];
  
  MockCapsuleRepository() {
    _initializeMockData();
  }
  
  void _initializeMockData() {
    // Add some mock capsules for testing
    final now = DateTime.now();
    
    _capsules.addAll([
      Capsule(
        id: 'mock-1',
        senderId: 'current-user',
        senderName: 'You',
        receiverId: 'priya-123',
        receiverName: 'Priya',
        receiverAvatar: 'assets/images/avatar_priya.png',
        label: 'Open on your birthday 🎂',
        content: 'Happy birthday my love! I hope this year brings you everything you\'ve been dreaming of...',
        unlockAt: now.add(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Capsule(
        id: 'mock-2',
        senderId: 'current-user',
        senderName: 'You',
        receiverId: 'ananya-456',
        receiverName: 'Ananya',
        receiverAvatar: 'assets/images/avatar_ananya.png',
        label: 'For your graduation day',
        content: 'My dearest Ananya, watching you grow has been the greatest joy of my life...',
        unlockAt: now.add(const Duration(days: 45)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Capsule(
        id: 'mock-3',
        senderId: 'current-user',
        senderName: 'You',
        receiverId: 'raj-789',
        receiverName: 'Raj',
        receiverAvatar: 'assets/images/avatar_raj.png',
        label: 'Anniversary surprise',
        content: 'Remember our first date? You wore that blue shirt and I couldn\'t stop smiling...',
        unlockAt: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Capsule(
        id: 'mock-4',
        senderId: 'current-user',
        senderName: 'You',
        receiverId: 'mom-999',
        receiverName: 'Mom',
        receiverAvatar: 'assets/images/avatar_mom.png',
        label: 'Mother\'s Day letter',
        content: 'Mom, there aren\'t enough words to express how grateful I am for everything you\'ve done...',
        unlockAt: now.subtract(const Duration(days: 2)),
        openedAt: now.subtract(const Duration(days: 1)),
        reaction: '❤️',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ]);
  }
  
  @override
  Future<List<Capsule>> getCapsules({required String userId, bool asSender = true}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    if (asSender) {
      return _capsules.where((c) => c.senderId == userId).toList()
        ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    } else {
      return _capsules.where((c) => c.receiverId == userId).toList()
        ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
    }
  }
  
  @override
  Future<Capsule> createCapsule(Capsule capsule) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _capsules.add(capsule);
    return capsule;
  }
  
  @override
  Future<Capsule> updateCapsule(Capsule capsule) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _capsules.indexWhere((c) => c.id == capsule.id);
    if (index != -1) {
      _capsules[index] = capsule;
      return capsule;
    }
    throw Exception('Capsule not found');
  }
  
  @override
  Future<void> deleteCapsule(String capsuleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _capsules.removeWhere((c) => c.id == capsuleId);
  }
  
  @override
  Future<void> markAsOpened(String capsuleId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _capsules.indexWhere((c) => c.id == capsuleId);
    if (index != -1) {
      _capsules[index] = _capsules[index].copyWith(openedAt: DateTime.now());
      
      // TODO: Send notification to sender that capsule was opened
      _sendNotificationToSender(_capsules[index]);
    }
  }
  
  @override
  Future<void> addReaction(String capsuleId, String reaction) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _capsules.indexWhere((c) => c.id == capsuleId);
    if (index != -1) {
      _capsules[index] = _capsules[index].copyWith(reaction: reaction);
      
      // TODO: Send notification to sender about reaction
      _sendReactionNotification(_capsules[index], reaction);
    }
  }
  
  void _sendNotificationToSender(Capsule capsule) {
    // TODO: Implement push notification
    // This would call your backend API to trigger a push notification
    print('TODO: Send notification to ${capsule.senderId} that ${capsule.receiverName} opened their letter');
  }
  
  void _sendReactionNotification(Capsule capsule, String reaction) {
    // TODO: Implement push notification for reactions
    print('TODO: Send notification to ${capsule.senderId} that ${capsule.receiverName} reacted with $reaction');
  }
}

/// Repository interface for recipient operations
abstract class RecipientRepository {
  Future<List<Recipient>> getRecipients(String userId);
  Future<Recipient> createRecipient(Recipient recipient);
  Future<Recipient> updateRecipient(Recipient recipient);
  Future<void> deleteRecipient(String recipientId);
}

/// Mock implementation
class MockRecipientRepository implements RecipientRepository {
  final List<Recipient> _recipients = [];
  
  MockRecipientRepository() {
    _initializeMockData();
  }
  
  void _initializeMockData() {
    _recipients.addAll([
      Recipient(
        id: 'priya-123',
        userId: 'current-user',
        name: 'Priya',
        relationship: 'Partner',
        avatar: 'assets/images/avatar_priya.png',
      ),
      Recipient(
        id: 'ananya-456',
        userId: 'current-user',
        name: 'Ananya',
        relationship: 'Daughter',
        avatar: 'assets/images/avatar_ananya.png',
      ),
      Recipient(
        id: 'raj-789',
        userId: 'current-user',
        name: 'Raj',
        relationship: 'Best Friend',
        avatar: 'assets/images/avatar_raj.png',
      ),
      Recipient(
        id: 'mom-999',
        userId: 'current-user',
        name: 'Mom',
        relationship: 'Mother',
        avatar: 'assets/images/avatar_mom.png',
      ),
    ]);
  }
  
  @override
  Future<List<Recipient>> getRecipients(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _recipients.where((r) => r.userId == userId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  @override
  Future<Recipient> createRecipient(Recipient recipient) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _recipients.add(recipient);
    return recipient;
  }
  
  @override
  Future<Recipient> updateRecipient(Recipient recipient) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final index = _recipients.indexWhere((r) => r.id == recipient.id);
    if (index != -1) {
      _recipients[index] = recipient;
      return recipient;
    }
    throw Exception('Recipient not found');
  }
  
  @override
  Future<void> deleteRecipient(String recipientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _recipients.removeWhere((r) => r.id == recipientId);
  }
}

/// Repository interface for auth operations
abstract class AuthRepository {
  Future<User> signUp({required String email, required String password, required String name});
  Future<User> signIn({required String email, required String password});
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<User> updateProfile({String? name, String? avatar});
}

/// Mock implementation
class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  
  @override
  Future<User> signUp({required String email, required String password, required String name}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // TODO: Implement actual authentication
    _currentUser = User(
      id: 'current-user',
      name: name,
      email: email,
    );
    
    return _currentUser!;
  }
  
  @override
  Future<User> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // TODO: Implement actual authentication
    _currentUser = User(
      id: 'current-user',
      name: 'Sunil',
      email: email,
    );
    
    return _currentUser!;
  }
  
  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
  
  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }
  
  @override
  Future<User> updateProfile({String? name, String? avatar}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    
    _currentUser = _currentUser!.copyWith(
      name: name,
      avatar: avatar,
    );
    
    return _currentUser!;
  }
}
