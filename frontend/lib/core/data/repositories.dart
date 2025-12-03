import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';

/// Repository interface for capsule operations
/// 
/// This is a mock implementation for development.
/// Replace with actual backend implementation (e.g., Supabase, Firebase) when ready.
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
      // Sent capsules (as sender)
      Capsule(
        id: 'mock-1',
        senderId: AppConstants.mockUserId,
        senderName: 'You',
        receiverId: AppConstants.mockPriyaId,
        receiverName: 'Priya',
        receiverAvatar: AppConstants.avatarPriya,
        label: 'Open on your birthday 🎂',
        content: 'Happy birthday my love! I hope this year brings you everything you\'ve been dreaming of...',
        unlockAt: now.add(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Capsule(
        id: 'mock-2',
        senderId: AppConstants.mockUserId,
        senderName: 'You',
        receiverId: AppConstants.mockAnanyaId,
        receiverName: 'Ananya',
        receiverAvatar: AppConstants.avatarAnanya,
        label: 'For your graduation day',
        content: 'My dearest Ananya, watching you grow has been the greatest joy of my life...',
        unlockAt: now.add(const Duration(days: 45)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Capsule(
        id: 'mock-3',
        senderId: AppConstants.mockUserId,
        senderName: 'You',
        receiverId: AppConstants.mockRajId,
        receiverName: 'Raj',
        receiverAvatar: AppConstants.avatarRaj,
        label: 'Anniversary surprise',
        content: 'Remember our first date? You wore that blue shirt and I couldn\'t stop smiling...',
        unlockAt: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Capsule(
        id: 'mock-4',
        senderId: AppConstants.mockUserId,
        senderName: 'You',
        receiverId: AppConstants.mockMomId,
        receiverName: 'Mom',
        receiverAvatar: AppConstants.avatarMom,
        label: 'Mother\'s Day letter',
        content: 'Mom, there aren\'t enough words to express how grateful I am for everything you\'ve done...',
        unlockAt: now.subtract(const Duration(days: 2)),
        openedAt: now.subtract(const Duration(days: 1)),
        reaction: '❤️',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      // Incoming capsules (as receiver)
      Capsule(
        id: 'incoming-1',
        senderId: AppConstants.mockPriyaId,
        senderName: 'Priya',
        receiverId: AppConstants.mockUserId,
        receiverName: 'You',
        receiverAvatar: '',
        label: 'Open on your birthday 🎂',
        content: 'Happy birthday! I wanted to send you something special...',
        unlockAt: now.add(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Capsule(
        id: 'incoming-2',
        senderId: AppConstants.mockAnanyaId,
        senderName: 'Ananya',
        receiverId: AppConstants.mockUserId,
        receiverName: 'You',
        receiverAvatar: '',
        label: 'For when you need encouragement',
        content: 'You\'ve always been there for me. Here\'s something for when you need a boost...',
        unlockAt: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Capsule(
        id: 'incoming-3',
        senderId: AppConstants.mockMomId,
        senderName: 'Mom',
        receiverId: AppConstants.mockUserId,
        receiverName: 'You',
        receiverAvatar: '',
        label: 'A letter from your mom',
        content: 'My dear child, I wanted to tell you how proud I am of you...',
        unlockAt: now.subtract(const Duration(days: 1)),
        openedAt: now.subtract(const Duration(hours: 12)),
        reaction: '😊',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ]);
  }
  
  @override
  Future<List<Capsule>> getCapsules({required String userId, bool asSender = true}) async {
    try {
      if (userId.isEmpty) {
        throw const ValidationException('User ID cannot be empty');
      }

      await Future.delayed(AppConstants.networkDelaySimulation);

      final filteredCapsules = asSender
          ? _capsules.where((c) => c.senderId == userId).toList()
          : _capsules.where((c) => c.receiverId == userId).toList();

      filteredCapsules.sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
      return filteredCapsules;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get capsules',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException(
        'Failed to retrieve capsules: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<Capsule> createCapsule(Capsule capsule) async {
    try {
      Validation.validateContent(capsule.content);
      if (capsule.label.isNotEmpty) {
        Validation.validateLabel(capsule.label);
      }
      Validation.validateUnlockDate(capsule.unlockAt);
      Validation.validateRecipientName(capsule.receiverName);

      await Future.delayed(AppConstants.createCapsuleDelay);
      _capsules.add(capsule);
      Logger.info('Capsule created: ${capsule.id}');
      return capsule;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to create capsule',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to create capsule: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<Capsule> updateCapsule(Capsule capsule) async {
    try {
      Validation.validateContent(capsule.content);
      if (capsule.label.isNotEmpty) {
        Validation.validateLabel(capsule.label);
      }

      await Future.delayed(AppConstants.updateDelay);

      final index = _capsules.indexWhere((c) => c.id == capsule.id);
      if (index == -1) {
        throw NotFoundException('Capsule not found: ${capsule.id}');
      }

      _capsules[index] = capsule;
      Logger.info('Capsule updated: ${capsule.id}');
      return capsule;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to update capsule',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to update capsule: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> deleteCapsule(String capsuleId) async {
    try {
      if (capsuleId.isEmpty) {
        throw const ValidationException('Capsule ID cannot be empty');
      }

      await Future.delayed(AppConstants.deleteDelay);

      final initialCount = _capsules.length;
      _capsules.removeWhere((c) => c.id == capsuleId);
      if (_capsules.length == initialCount) {
        throw NotFoundException('Capsule not found: $capsuleId');
      }

      Logger.info('Capsule deleted: $capsuleId');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to delete capsule',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to delete capsule: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> markAsOpened(String capsuleId) async {
    try {
      if (capsuleId.isEmpty) {
        throw const ValidationException('Capsule ID cannot be empty');
      }

      await Future.delayed(AppConstants.updateDelay);

      final index = _capsules.indexWhere((c) => c.id == capsuleId);
      if (index == -1) {
        throw NotFoundException('Capsule not found: $capsuleId');
      }

      _capsules[index] = _capsules[index].copyWith(openedAt: DateTime.now());
      Logger.info('Capsule marked as opened: $capsuleId');

      // Notification will be handled by backend service when integrated
      _sendNotificationToSender(_capsules[index]);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to mark capsule as opened',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to mark capsule as opened: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  Future<void> addReaction(String capsuleId, String reaction) async {
    try {
      if (capsuleId.isEmpty) {
        throw const ValidationException('Capsule ID cannot be empty');
      }
      if (reaction.trim().isEmpty) {
        throw const ValidationException('Reaction cannot be empty');
      }

      await Future.delayed(AppConstants.deleteDelay);

      final index = _capsules.indexWhere((c) => c.id == capsuleId);
      if (index == -1) {
        throw NotFoundException('Capsule not found: $capsuleId');
      }

      _capsules[index] = _capsules[index].copyWith(reaction: reaction.trim());
      Logger.info('Reaction added to capsule: $capsuleId');

      // Notification will be handled by backend service when integrated
      _sendReactionNotification(_capsules[index], reaction);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to add reaction',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to add reaction: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _sendNotificationToSender(Capsule capsule) {
    // Notification service will be implemented when backend is integrated
    Logger.debug(
      'Capsule opened notification: sender=${capsule.senderId}, receiver=${capsule.receiverName}',
    );
  }

  void _sendReactionNotification(Capsule capsule, String reaction) {
    // Notification service will be implemented when backend is integrated
    Logger.debug(
      'Reaction notification: sender=${capsule.senderId}, receiver=${capsule.receiverName}, reaction=$reaction',
    );
  }
}

/// Repository interface for recipient operations
abstract class RecipientRepository {
  Future<List<Recipient>> getRecipients(String userId);
  Future<Recipient> createRecipient(Recipient recipient, {String? linkedUserId});
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
        id: AppConstants.mockPriyaId,
        userId: AppConstants.mockUserId,
        name: 'Priya',
        relationship: 'Partner',
        avatar: 'assets/images/avatar_priya.png',
      ),
      Recipient(
        id: AppConstants.mockAnanyaId,
        userId: AppConstants.mockUserId,
        name: 'Ananya',
        relationship: 'Daughter',
        avatar: 'assets/images/avatar_ananya.png',
      ),
      Recipient(
        id: AppConstants.mockRajId,
        userId: AppConstants.mockUserId,
        name: 'Raj',
        relationship: 'Best Friend',
        avatar: 'assets/images/avatar_raj.png',
      ),
      Recipient(
        id: AppConstants.mockMomId,
        userId: AppConstants.mockUserId,
        name: 'Mom',
        relationship: 'Mother',
        avatar: 'assets/images/avatar_mom.png',
      ),
    ]);
  }
  
  @override
  Future<List<Recipient>> getRecipients(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const ValidationException('User ID cannot be empty');
      }

      await Future.delayed(AppConstants.deleteDelay);

      final recipients = _recipients.where((r) => r.userId == userId).toList();
      recipients.sort((a, b) => a.name.compareTo(b.name));
      return recipients;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get recipients',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException(
        'Failed to retrieve recipients: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Recipient> createRecipient(Recipient recipient, {String? linkedUserId}) async {
    try {
      Validation.validateRecipientName(recipient.name);
      Validation.validateRelationship(recipient.relationship);

      await Future.delayed(AppConstants.createCapsuleDelay);
      _recipients.add(recipient);
      Logger.info('Recipient created: ${recipient.id}');
      return recipient;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to create recipient',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to create recipient: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Recipient> updateRecipient(Recipient recipient) async {
    try {
      Validation.validateRecipientName(recipient.name);
      Validation.validateRelationship(recipient.relationship);

      await Future.delayed(AppConstants.updateDelay);

      final index = _recipients.indexWhere((r) => r.id == recipient.id);
      if (index == -1) {
        throw NotFoundException('Recipient not found: ${recipient.id}');
      }

      _recipients[index] = recipient;
      Logger.info('Recipient updated: ${recipient.id}');
      return recipient;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to update recipient',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to update recipient: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteRecipient(String recipientId) async {
    try {
      if (recipientId.isEmpty) {
        throw const ValidationException('Recipient ID cannot be empty');
      }

      await Future.delayed(AppConstants.deleteDelay);

      final initialCount = _recipients.length;
      _recipients.removeWhere((r) => r.id == recipientId);
      if (_recipients.length == initialCount) {
        throw NotFoundException('Recipient not found: $recipientId');
      }

      Logger.info('Recipient deleted: $recipientId');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to delete recipient',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to delete recipient: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Repository interface for auth operations
abstract class AuthRepository {
  Future<User> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  });
  Future<User> signIn({required String email, required String password});
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<User> updateProfile({String? name, String? avatar});
}

/// Mock implementation
class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  
  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      final sanitizedEmail = Validation.sanitizeEmail(email);
      Validation.validateEmail(sanitizedEmail);
      Validation.validatePassword(password);
      Validation.validateName(firstName);
      Validation.validateName(lastName);

      await Future.delayed(AppConstants.authDelay);

      final fullName = '${Validation.sanitizeString(firstName)} ${Validation.sanitizeString(lastName)}';
      _currentUser = User(
        id: AppConstants.defaultUserId,
        name: fullName,
        email: sanitizedEmail,
        username: username.trim(),
      );

      Logger.info('User signed up: $sanitizedEmail');
      return _currentUser!;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to sign up',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException) {
        rethrow;
      }
      throw AuthenticationException(
        'Failed to sign up: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final sanitizedEmail = Validation.sanitizeEmail(email);
      Validation.validateEmail(sanitizedEmail);
      Validation.validatePassword(password);

      await Future.delayed(AppConstants.authDelay);

      _currentUser = User(
        id: AppConstants.defaultUserId,
        name: AppConstants.defaultUserName,
        email: sanitizedEmail,
      );

      Logger.info('User signed in: $sanitizedEmail');
      return _currentUser!;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to sign in',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException) {
        rethrow;
      }
      throw AuthenticationException(
        'Failed to sign in: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.delayed(AppConstants.signOutDelay);
      _currentUser = null;
      Logger.info('User signed out');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to sign out',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthenticationException(
        'Failed to sign out: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      await Future.delayed(AppConstants.getCurrentUserDelay);
      return _currentUser;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get current user',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<User> updateProfile({String? name, String? avatar}) async {
    try {
      if (_currentUser == null) {
        throw const AuthenticationException('No user logged in');
      }

      if (name != null) {
        Validation.validateName(name);
      }

      await Future.delayed(AppConstants.updateDelay);

      _currentUser = _currentUser!.copyWith(
        name: name != null ? Validation.sanitizeString(name) : null,
        avatar: avatar,
      );

      Logger.info('Profile updated: ${_currentUser!.id}');
      return _currentUser!;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to update profile',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is ValidationException || e is AuthenticationException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to update profile: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
