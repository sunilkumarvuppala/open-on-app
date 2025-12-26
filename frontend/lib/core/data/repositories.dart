import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/data/draft_storage.dart';

/// Repository interface for capsule operations
/// 
/// This is a mock implementation for development.
/// Replace with actual backend implementation (e.g., Supabase, Firebase) when ready.
abstract class CapsuleRepository {
  Future<List<Capsule>> getCapsules({required String userId, bool asSender = true});
  Future<Capsule?> getCapsuleById(String capsuleId);
  Future<Capsule> createCapsule(
    Capsule capsule, {
    String? hint1,
    String? hint2,
    String? hint3,
    bool isUnregisteredRecipient = false,
    String? unregisteredRecipientName,
  });
  Future<Capsule> updateCapsule(Capsule capsule);
  Future<void> deleteCapsule(String capsuleId);
  Future<void> markAsOpened(String capsuleId);
  Future<void> addReaction(String capsuleId, String reaction);
  Future<Map<String, dynamic>?> getCurrentHint(String capsuleId);
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
        senderAvatarValue: '', // User's own avatar (can be empty for mock)
        receiverId: AppConstants.mockPriyaId,
        receiverName: 'Priya',
        receiverAvatarValue: AppConstants.avatarPriya,
        label: 'Open on your birthday 🎂',
        content: 'Happy birthday my love! I hope this year brings you everything you\'ve been dreaming of...',
        unlockAt: now.add(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Capsule(
        id: 'mock-2',
        senderId: AppConstants.mockUserId,
        senderName: 'You',
        senderAvatarValue: '', // User's own avatar (can be empty for mock)
        receiverId: AppConstants.mockAnanyaId,
        receiverName: 'Ananya',
        receiverAvatarValue: AppConstants.avatarAnanya,
        label: 'For your graduation day',
        content: 'My dearest Ananya, watching you grow has been the greatest joy of my life...',
        unlockAt: now.add(const Duration(days: 45)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Capsule(
        id: 'mock-3',
        senderId: AppConstants.mockUserId,
        senderName: 'You',
        senderAvatarValue: '', // User's own avatar (can be empty for mock)
        receiverId: AppConstants.mockRajId,
        receiverName: 'Raj',
        receiverAvatarValue: AppConstants.avatarRaj,
        label: 'Anniversary surprise',
        content: 'Remember our first date? You wore that blue shirt and I couldn\'t stop smiling...',
        unlockAt: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Capsule(
        id: 'mock-4',
        senderId: AppConstants.mockUserId,
        senderName: 'You',
        senderAvatarValue: '', // User's own avatar (can be empty for mock)
        receiverId: AppConstants.mockMomId,
        receiverName: 'Mom',
        receiverAvatarValue: AppConstants.avatarMom,
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
        senderAvatarValue: AppConstants.avatarPriya, // Sender's avatar
        receiverId: AppConstants.mockUserId,
        receiverName: 'You',
        receiverAvatarValue: '', // User's own avatar (can be empty for mock)
        label: 'Open on your birthday 🎂',
        content: 'Happy birthday! I wanted to send you something special...',
        unlockAt: now.add(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Capsule(
        id: 'incoming-2',
        senderId: AppConstants.mockAnanyaId,
        senderName: 'Ananya',
        senderAvatarValue: AppConstants.avatarAnanya, // Sender's avatar
        receiverId: AppConstants.mockUserId,
        receiverName: 'You',
        receiverAvatarValue: '', // User's own avatar (can be empty for mock)
        label: 'For when you need encouragement',
        content: 'You\'ve always been there for me. Here\'s something for when you need a boost...',
        unlockAt: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Capsule(
        id: 'incoming-3',
        senderId: AppConstants.mockMomId,
        senderName: 'Mom',
        senderAvatarValue: AppConstants.avatarMom, // Sender's avatar
        receiverId: AppConstants.mockUserId,
        receiverName: 'You',
        receiverAvatarValue: '', // User's own avatar (can be empty for mock)
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
  Future<Capsule?> getCapsuleById(String capsuleId) async {
    try {
      final capsule = _capsules.firstWhere(
        (c) => c.id == capsuleId,
        orElse: () => throw NotFoundException('Capsule not found: $capsuleId'),
      );
      return capsule;
    } catch (e, stackTrace) {
      Logger.error('Failed to get capsule by ID', error: e, stackTrace: stackTrace);
      if (e is NotFoundException) {
        return null;
      }
      throw RepositoryException(
        'Failed to get capsule: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
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

      // Don't sort here - sorting is handled by providers based on tab requirements
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
  Future<Capsule> createCapsule(
    Capsule capsule, {
    String? hint1,
    String? hint2,
    String? hint3,
    bool isUnregisteredRecipient = false,
    String? unregisteredRecipientName,
  }) async {
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
  Future<Map<String, dynamic>?> getCurrentHint(String capsuleId) async {
    // Mock implementation - return null (no hints in mock)
    return null;
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

/// Repository interface for draft operations
/// 
/// Drafts are crash-safe, automatically saved letters that haven't been sealed yet.
/// They are stored both locally (immediate) and remotely (async with retry).
abstract class DraftRepository {
  /// Create a new draft
  Future<Draft> createDraft({
    required String userId,
    String? title,
    required String content,
    String? recipientName,
    String? recipientAvatar,
  });
  
  /// Get a draft by ID
  Future<Draft?> getDraft(String draftId);
  
  /// Update draft content and/or title
  Future<Draft> updateDraft(
    String draftId,
    String content, {
    String? title,
    String? recipientName,
    String? recipientAvatar,
  });
  
  /// Get all drafts for a user
  Future<List<Draft>> getDrafts(String userId);
  
  /// Delete a draft
  Future<void> deleteDraft(String draftId, String userId);
}

/// Local implementation using SharedPreferences
/// 
/// This provides crash-safe local storage for drafts.
/// Remote sync can be added later without changing the interface.
class LocalDraftRepository implements DraftRepository {
  @override
  Future<Draft> createDraft({
    required String userId,
    String? title,
    required String content,
    String? recipientName,
    String? recipientAvatar,
  }) async {
    try {
      Logger.debug('Creating draft for user: $userId, title: $title, content length: ${content.length}');
      
      final draft = Draft(
        userId: userId,
        title: title,
        body: content,
        recipientName: recipientName,
        recipientAvatar: recipientAvatar,
      );
      
      // Mark as new draft so it gets added to the list
      await DraftStorage.saveDraft(userId, draft, isNewDraft: true);
      Logger.info('Draft created: ${draft.id} for user: $userId');
      
      // Verify it was saved
      final savedDraft = await DraftStorage.getDraft(draft.id);
      if (savedDraft == null) {
        Logger.error('Draft was not saved correctly - verification failed');
        throw RepositoryException('Draft was not saved correctly');
      }
      Logger.debug('Draft verification successful: ${savedDraft.id}');
      
      return draft;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to create draft',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException(
        'Failed to create draft: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Draft?> getDraft(String draftId) async {
    try {
      return await DraftStorage.getDraft(draftId);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get draft',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException(
        'Failed to get draft: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Draft> updateDraft(
    String draftId,
    String content, {
    String? title,
    String? recipientName,
    String? recipientAvatar,
  }) async {
    try {
      final existingDraft = await DraftStorage.getDraft(draftId);
      if (existingDraft == null) {
        throw NotFoundException('Draft not found: $draftId');
      }
      
      final updatedDraft = existingDraft.copyWith(
        title: title,
        body: content,
        recipientName: recipientName,
        recipientAvatar: recipientAvatar,
        lastEdited: DateTime.now(),
      );
      
      // Mark as update (not new) so it doesn't unnecessarily update the list
      await DraftStorage.saveDraft(existingDraft.userId, updatedDraft, isNewDraft: false);
      Logger.info('Draft updated: $draftId');
      return updatedDraft;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to update draft',
        error: e,
        stackTrace: stackTrace,
      );
      if (e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to update draft: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Draft>> getDrafts(String userId) async {
    try {
      Logger.debug('Getting drafts for user: $userId');
      final drafts = await DraftStorage.getAllDrafts(userId);
      Logger.debug('Retrieved ${drafts.length} drafts for user: $userId');
      
      // Log draft IDs for debugging
      if (drafts.isNotEmpty) {
        Logger.debug('Draft IDs: ${drafts.map((d) => d.id).join(", ")}');
      }
      
      return drafts;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get drafts for user: $userId',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException(
        'Failed to get drafts: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteDraft(String draftId, String userId) async {
    try {
      await DraftStorage.deleteDraft(userId, draftId);
      Logger.info('Draft deleted: $draftId');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to delete draft',
        error: e,
        stackTrace: stackTrace,
      );
      throw RepositoryException(
        'Failed to delete draft: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
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
        username: 'priya',
        avatar: 'assets/images/avatar_priya.png',
      ),
      Recipient(
        id: AppConstants.mockAnanyaId,
        userId: AppConstants.mockUserId,
        name: 'Ananya',
        username: 'ananya',
        avatar: 'assets/images/avatar_ananya.png',
      ),
      Recipient(
        id: AppConstants.mockRajId,
        userId: AppConstants.mockUserId,
        name: 'Raj',
        username: 'raj',
        avatar: 'assets/images/avatar_raj.png',
      ),
      Recipient(
        id: AppConstants.mockMomId,
        userId: AppConstants.mockUserId,
        name: 'Mom',
        username: 'mom',
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
abstract class SelfLetterRepository {
  Future<SelfLetter> createSelfLetter({
    required String content,
    required DateTime scheduledOpenAt,
    String? mood,
    String? lifeArea,
    String? city,
  });
  
  Future<List<SelfLetter>> getSelfLetters({
    int skip = 0,
    int limit = 50,
  });
  
  Future<SelfLetter> openSelfLetter(String letterId);
  
  Future<void> submitReflection({
    required String letterId,
    required String answer, // "yes", "no", or "skipped"
  });
}

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
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
  });
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
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
  }) async {
    try {
      if (_currentUser == null) {
        throw const AuthenticationException('No user logged in');
      }

      if (firstName != null) {
        Validation.validateName(firstName);
      }
      if (lastName != null) {
        Validation.validateName(lastName);
      }
      if (username != null) {
        Validation.validateUsername(username);
      }

      await Future.delayed(AppConstants.updateDelay);

      // Build full name from first and last name
      String? fullName;
      if (firstName != null || lastName != null) {
        final first = firstName != null 
            ? Validation.sanitizeString(firstName) 
            : _currentUser!.firstName;
        final last = lastName != null 
            ? Validation.sanitizeString(lastName) 
            : (_currentUser!.name.split(' ').length > 1 
                ? _currentUser!.name.split(' ').sublist(1).join(' ') 
                : '');
        fullName = '$first $last'.trim();
      }

      _currentUser = _currentUser!.copyWith(
        name: fullName ?? _currentUser!.name,
        username: username != null ? username.trim() : _currentUser!.username,
        avatar: avatarUrl ?? _currentUser!.avatar,
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

/// Repository interface for letter reply operations
abstract class LetterReplyRepository {
  /// Get reply for a letter (if exists)
  Future<LetterReply?> getReplyByLetterId(String letterId);
  
  /// Create a reply for a letter (one-time only)
  Future<LetterReply> createReply(String letterId, String replyText, String replyEmoji);
  
  /// Mark receiver animation as seen (after sending reply)
  Future<void> markReceiverAnimationSeen(String letterId);
  
  /// Mark sender animation as seen (when viewing reply)
  Future<void> markSenderAnimationSeen(String letterId);
}
