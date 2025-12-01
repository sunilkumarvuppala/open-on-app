import 'dart:convert';
import 'package:openon_app/core/data/api_client.dart';
import 'package:openon_app/core/data/api_config.dart';
import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/data/token_storage.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/constants/app_constants.dart';

/// API-based Auth Repository
class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();
  User? _cachedUser;

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

      final response = await _apiClient.post(
        ApiConfig.authSignup,
        {
          'email': sanitizedEmail,
          'username': username.trim(),
          'password': password,
          'first_name': Validation.sanitizeString(firstName),
          'last_name': Validation.sanitizeString(lastName),
        },
        includeAuth: false,
      );

      // Save tokens
      final accessToken = response['access_token'] as String;
      final refreshToken = response['refresh_token'] as String;
      await _tokenStorage.saveTokens(accessToken, refreshToken);

      // Get user info
      final userResponse = await _apiClient.get(ApiConfig.authMe);
      _cachedUser = _mapUserFromJson(userResponse);

      Logger.info('User signed up: $sanitizedEmail');
      return _cachedUser!;
    } catch (e, stackTrace) {
      Logger.error('Failed to sign up', error: e, stackTrace: stackTrace);
      if (e is AppException) {
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

      // Backend uses username for login, but we'll try email first
      final response = await _apiClient.post(
        ApiConfig.authLogin,
        {
          'username': sanitizedEmail, // Try email as username
          'password': password,
        },
        includeAuth: false,
      );

      // Save tokens
      final accessToken = response['access_token'] as String;
      final refreshToken = response['refresh_token'] as String;
      await _tokenStorage.saveTokens(accessToken, refreshToken);

      // Get user info
      final userResponse = await _apiClient.get(ApiConfig.authMe);
      _cachedUser = _mapUserFromJson(userResponse);

      Logger.info('User signed in: $sanitizedEmail');
      return _cachedUser!;
    } catch (e, stackTrace) {
      Logger.error('Failed to sign in', error: e, stackTrace: stackTrace);
      if (e is AppException) {
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
      await _tokenStorage.clearTokens();
      _cachedUser = null;
      Logger.info('User signed out');
    } catch (e, stackTrace) {
      Logger.error('Failed to sign out', error: e, stackTrace: stackTrace);
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
      if (_cachedUser != null) {
        return _cachedUser;
      }

      final isAuthenticated = await _tokenStorage.isAuthenticated();
      if (!isAuthenticated) {
        return null;
      }

      final userResponse = await _apiClient.get(ApiConfig.authMe);
      _cachedUser = _mapUserFromJson(userResponse);
      return _cachedUser;
    } catch (e, stackTrace) {
      Logger.error('Failed to get current user', error: e, stackTrace: stackTrace);
      // If auth fails, clear tokens
      if (e is AuthenticationException) {
        await _tokenStorage.clearTokens();
        _cachedUser = null;
      }
      return null;
    }
  }

  @override
  Future<User> updateProfile({String? name, String? avatar}) async {
    try {
      if (_cachedUser == null) {
        throw const AuthenticationException('No user logged in');
      }

      if (name != null) {
        Validation.validateName(name);
      }

      // Backend doesn't have update profile endpoint yet, so we'll just update cache
      _cachedUser = _cachedUser!.copyWith(
        name: name != null ? Validation.sanitizeString(name) : null,
        avatar: avatar,
      );

      Logger.info('Profile updated: ${_cachedUser!.id}');
      return _cachedUser!;
    } catch (e, stackTrace) {
      Logger.error('Failed to update profile', error: e, stackTrace: stackTrace);
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

  User _mapUserFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? json['username'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

/// API-based Capsule Repository
class ApiCapsuleRepository implements CapsuleRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<Capsule>> getCapsules({
    required String userId,
    bool asSender = true,
  }) async {
    try {
      if (userId.isEmpty) {
        throw const ValidationException('User ID cannot be empty');
      }

      final box = asSender ? 'outbox' : 'inbox';
      final response = await _apiClient.get(
        ApiConfig.capsules,
        queryParams: {
          'box': box,
          'page': AppConstants.defaultPage.toString(),
          'page_size': AppConstants.maxPageSize.toString(),
        },
      );

      final capsulesList = response['capsules'] as List<dynamic>? ?? [];
      final capsules = capsulesList
          .map((json) => _mapCapsuleFromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by unlock time
      capsules.sort((a, b) => a.unlockAt.compareTo(b.unlockAt));

      return capsules;
    } catch (e, stackTrace) {
      Logger.error('Failed to get capsules', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
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

      final response = await _apiClient.post(
        ApiConfig.capsules,
        {
          'receiver_id': capsule.receiverId,
          'title': capsule.label,
          'body': capsule.content,
          'media_urls': capsule.photoUrl != null ? [capsule.photoUrl] : null,
          'allow_early_view': false,
          'allow_receiver_reply': true,
        },
      );

      final createdCapsule = _mapCapsuleFromJson(response);
      Logger.info('Capsule created: ${createdCapsule.id}');
      return createdCapsule;
    } catch (e, stackTrace) {
      Logger.error('Failed to create capsule', error: e, stackTrace: stackTrace);
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
      if (capsule.id.isEmpty) {
        throw const ValidationException('Capsule ID cannot be empty');
      }

      Validation.validateContent(capsule.content);

      final response = await _apiClient.put(
        ApiConfig.capsuleById(capsule.id),
        {
          'title': capsule.label,
          'body': capsule.content,
          'media_urls': capsule.photoUrl != null ? [capsule.photoUrl] : null,
        },
      );

      final updatedCapsule = _mapCapsuleFromJson(response);
      Logger.info('Capsule updated: ${updatedCapsule.id}');
      return updatedCapsule;
    } catch (e, stackTrace) {
      Logger.error('Failed to update capsule', error: e, stackTrace: stackTrace);
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

      await _apiClient.delete(ApiConfig.capsuleById(capsuleId));
      Logger.info('Capsule deleted: $capsuleId');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete capsule', error: e, stackTrace: stackTrace);
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

      await _apiClient.post(
        ApiConfig.openCapsule(capsuleId),
        {},
      );

      Logger.info('Capsule marked as opened: $capsuleId');
    } catch (e, stackTrace) {
      Logger.error('Failed to mark capsule as opened', error: e, stackTrace: stackTrace);
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
    // Backend doesn't have reaction endpoint yet
    // This is a placeholder for future implementation
    Logger.debug('Reaction added to capsule: $capsuleId - $reaction');
  }

  /// Seal a capsule with unlock time
  Future<Capsule> sealCapsule(String capsuleId, DateTime unlockAt) async {
    try {
      if (capsuleId.isEmpty) {
        throw const ValidationException('Capsule ID cannot be empty');
      }

      final response = await _apiClient.post(
        ApiConfig.sealCapsule(capsuleId),
        {
          'scheduled_unlock_at': unlockAt.toUtc().toIso8601String(),
        },
      );

      final sealedCapsule = _mapCapsuleFromJson(response);
      Logger.info('Capsule sealed: $capsuleId');
      return sealedCapsule;
    } catch (e, stackTrace) {
      Logger.error('Failed to seal capsule', error: e, stackTrace: stackTrace);
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to seal capsule: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Capsule _mapCapsuleFromJson(Map<String, dynamic> json) {
    // Parse media URLs
    List<String>? mediaUrls;
    if (json['media_urls'] != null) {
      if (json['media_urls'] is String) {
        try {
          mediaUrls = List<String>.from(jsonDecode(json['media_urls'] as String));
        } catch (_) {
          mediaUrls = null;
        }
      } else if (json['media_urls'] is List) {
        mediaUrls = List<String>.from(json['media_urls'] as List);
      }
    }

    final scheduledUnlockAt = json['scheduled_unlock_at'] as String?;
    final openedAt = json['opened_at'] as String?;

    return Capsule(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderName: 'Sender', // Backend doesn't return sender name, would need to fetch
      receiverId: json['receiver_id'] as String,
      receiverName: 'Recipient', // Backend doesn't return receiver name, would need to fetch
      receiverAvatar: '',
      label: json['title'] as String? ?? '',
      content: json['body'] as String,
      photoUrl: mediaUrls?.isNotEmpty == true ? mediaUrls!.first : null,
      unlockAt: scheduledUnlockAt != null
          ? DateTime.parse(scheduledUnlockAt).toLocal()
          : DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      openedAt: openedAt != null ? DateTime.parse(openedAt).toLocal() : null,
    );
  }
}

/// API-based User Service (for searching users)
class ApiUserService {
  final ApiClient _apiClient = ApiClient();

  /// Check if username is available
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    try {
      if (username.length < 3) {
        return {
          'available': false,
          'message': 'Username must be at least 3 characters',
        };
      }

      final response = await _apiClient.get(
        ApiConfig.checkUsernameAvailability(username),
        includeAuth: false,
      );

      return {
        'available': response['available'] as bool,
        'message': response['message'] as String,
      };
    } catch (e, stackTrace) {
      Logger.error('Failed to check username availability', error: e, stackTrace: stackTrace);
      // If it's a validation error, return that message
      if (e is ValidationException) {
        return {
          'available': false,
          'message': e.message,
        };
      }
      // For network errors, assume unavailable to be safe
      return {
        'available': false,
        'message': 'Unable to check username availability. Please try again.',
      };
    }
  }

  /// Search for registered users
  Future<List<User>> searchUsers(String query, {int limit = AppConstants.defaultSearchLimit}) async {
    try {
      if (query.length < AppConstants.minSearchQueryLength) {
        return [];
      }

      final response = await _apiClient.getList(
        ApiConfig.searchUsers(query, limit: limit),
      );

      return response
          .map((json) => _mapUserFromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Failed to search users', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to search users: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Map user JSON to User model (same as ApiAuthRepository)
  User _mapUserFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? json['username'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

/// API-based Recipient Repository
class ApiRecipientRepository implements RecipientRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<Recipient>> getRecipients(String userId) async {
    try {
      if (userId.isEmpty) {
        throw const ValidationException('User ID cannot be empty');
      }

      final response = await _apiClient.getList(
        ApiConfig.recipients,
        queryParams: {'page': '1', 'page_size': '100'},
      );

      return response
          .map((json) => _mapRecipientFromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Failed to get recipients', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
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
      Validation.validateName(recipient.name);
      Validation.validateRelationship(recipient.relationship);

      // Build request body
      final requestBody = <String, dynamic>{
        'name': recipient.name,
      };
      
      // If a linked user ID is provided (from user search), include it
      if (linkedUserId != null && linkedUserId.isNotEmpty) {
        requestBody['user_id'] = linkedUserId;
      }

      final response = await _apiClient.post(
        ApiConfig.recipients,
        requestBody,
      );

      final createdRecipient = _mapRecipientFromJson(response);
      Logger.info('Recipient created: ${createdRecipient.id}');
      return createdRecipient;
    } catch (e, stackTrace) {
      Logger.error('Failed to create recipient', error: e, stackTrace: stackTrace);
      if (e is ValidationException || e is AuthenticationException || e is NetworkException) {
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
    // Backend doesn't have update recipient endpoint yet
    throw const RepositoryException('Update recipient not yet implemented');
  }

  @override
  Future<void> deleteRecipient(String recipientId) async {
    try {
      if (recipientId.isEmpty) {
        throw const ValidationException('Recipient ID cannot be empty');
      }

      await _apiClient.delete(ApiConfig.recipientById(recipientId));
      Logger.info('Recipient deleted: $recipientId');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete recipient', error: e, stackTrace: stackTrace);
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

  Recipient _mapRecipientFromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'] as String,
      userId: json['owner_id'] as String,
      name: json['name'] as String,
      relationship: 'Contact', // Backend doesn't have relationship field
      avatar: '',
    );
  }
}

/// API-based Draft Repository (placeholder for future implementation)
class ApiDraftRepository {
  // TODO: Implement draft repository when backend draft endpoints are ready
  // Will use ApiClient for draft CRUD operations
}

