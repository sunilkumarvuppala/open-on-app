import 'package:openon_app/core/data/api_client.dart';
import 'package:openon_app/core/data/api_config.dart';
import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/data/token_storage.dart';
import 'package:openon_app/core/data/user_mapper.dart';
import 'package:openon_app/core/data/capsule_mapper.dart';
import 'package:openon_app/core/data/recipient_mapper.dart';
import 'package:openon_app/core/data/connection_repository.dart';
import 'package:openon_app/core/data/supabase_config.dart';
import 'package:openon_app/core/data/recipient_resolver.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/utils/uuid_utils.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/data/stream_polling_mixin.dart';
import 'dart:async';

/// API-based Auth Repository
class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();
  User? _cachedUser;
  
  // Static instance cache - this is a problem if multiple instances exist
  // But since we use providers, there should only be one instance per app
  // However, we need to ensure cache is cleared on logout

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

      // Check if response has tokens (success case) or just a message (user created, needs to sign in)
      final accessTokenValue = response['access_token'];
      if (accessTokenValue != null && accessTokenValue is String && accessTokenValue.isNotEmpty) {
        // Save tokens - safely extract values (we've already verified accessTokenValue is String)
        final accessToken = accessTokenValue;
        final refreshTokenValue = response['refresh_token'];
        final refreshToken = (refreshTokenValue is String) ? refreshTokenValue : '';
        await _tokenStorage.saveTokens(accessToken, refreshToken);

        // Get user info
        final userResponse = await _apiClient.get(ApiConfig.authMe);
        _cachedUser = UserMapper.fromJson(userResponse);
      } else if (response.containsKey('message')) {
        // User was created but tokens weren't returned - user needs to sign in
        final messageValue = response['message'];
        final message = (messageValue is String) ? messageValue : 'User created successfully. Please sign in.';
        throw AuthenticationException(message);
      } else {
        // Unexpected response format
        throw AuthenticationException(
          'Unexpected response from server. Please try signing in.',
        );
      }

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

      // Save tokens (handle null values)
      final accessToken = response['access_token'] as String?;
      final refreshToken = response['refresh_token'] as String? ?? '';
      
      if (accessToken == null) {
        throw AuthenticationException('No access token received from server');
      }
      
      await _tokenStorage.saveTokens(accessToken, refreshToken);

      // Get user info
      final userResponse = await _apiClient.get(ApiConfig.authMe);
      _cachedUser = UserMapper.fromJson(userResponse);

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
      // CRITICAL: Clear cached user FIRST before clearing tokens
      // This prevents any race conditions where getCurrentUser might return stale data
      _cachedUser = null;
      
      // Clear authentication tokens
      await _tokenStorage.clearTokens();
      
      Logger.info('User signed out - tokens and cache cleared');
    } catch (e, stackTrace) {
      Logger.error('Failed to sign out', error: e, stackTrace: stackTrace);
      // Even if clearing tokens fails, clear the cached user
      _cachedUser = null;
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
      // CRITICAL: Always check authentication first
      // If not authenticated, clear cache and return null to prevent data leakage
      final isAuthenticated = await _tokenStorage.isAuthenticated();
      if (!isAuthenticated) {
        _cachedUser = null;
        return null;
      }

      // Return cached user if available and authentication is valid
      // This reduces API calls and prevents rate limiting
      // We only fetch fresh data if cache is empty
      if (_cachedUser != null) {
        return _cachedUser;
      }

      // Fetch fresh user data only if cache is empty
      final userResponse = await _apiClient.get(ApiConfig.authMe);
      _cachedUser = UserMapper.fromJson(userResponse);
      return _cachedUser;
    } catch (e, stackTrace) {
      Logger.error('Failed to get current user', error: e, stackTrace: stackTrace);
      // If auth fails, clear tokens and cache
      if (e is AuthenticationException) {
        await _tokenStorage.clearTokens();
        _cachedUser = null;
      }
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
      if (_cachedUser == null) {
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

      print('[ApiAuthRepository.updateProfile] Received - firstName: $firstName, lastName: $lastName, username: $username, avatarUrl: $avatarUrl');
      
      // Prepare update payload
      final Map<String, dynamic> payload = {};
      if (firstName != null) {
        payload['first_name'] = Validation.sanitizeString(firstName);
        print('[ApiAuthRepository.updateProfile] Added first_name: ${payload['first_name']}');
      }
      if (lastName != null) {
        payload['last_name'] = Validation.sanitizeString(lastName);
        print('[ApiAuthRepository.updateProfile] Added last_name: ${payload['last_name']}');
      }
      if (username != null) {
        payload['username'] = username.trim();
        print('[ApiAuthRepository.updateProfile] Added username: ${payload['username']}');
      }
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        payload['avatar_url'] = avatarUrl;
        print('[ApiAuthRepository.updateProfile] Added avatar_url: ${payload['avatar_url']}');
      } else {
        print('[ApiAuthRepository.updateProfile] NOT adding avatar_url - avatarUrl is null or empty: $avatarUrl');
      }

      print('[ApiAuthRepository.updateProfile] Final payload: $payload');
      print('[ApiAuthRepository.updateProfile] Payload keys: ${payload.keys.toList()}');
      print('[ApiAuthRepository.updateProfile] Payload isEmpty: ${payload.isEmpty}');
      print('[ApiAuthRepository.updateProfile] avatarUrl value received: $avatarUrl');

      Logger.info('updateProfile payload: $payload');
      Logger.info('Payload keys: ${payload.keys.toList()}');
      Logger.info('Payload isEmpty: ${payload.isEmpty}');
      Logger.info('avatarUrl value: $avatarUrl');

      if (payload.isEmpty) {
        print('[ApiAuthRepository.updateProfile] ERROR: Payload is empty!');
        Logger.error('No fields to update - payload is empty. '
            'firstName: $firstName, lastName: $lastName, username: $username, avatarUrl: $avatarUrl');
        throw const ValidationException('No fields to update');
      }

      // Call backend API
      print('[ApiAuthRepository.updateProfile] Calling PUT ${ApiConfig.authMe} with payload: $payload');
      Logger.info('Calling PUT ${ApiConfig.authMe} with payload: $payload');
      final response = await _apiClient.put(
        ApiConfig.authMe,
        payload,
      );
      
      print('[ApiAuthRepository.updateProfile] Response received: $response');

      // Update cached user with fresh data from server
      _cachedUser = UserMapper.fromJson(response);

      Logger.info('Profile updated: ${_cachedUser!.id}');
      Logger.info('Avatar URL after update: ${_cachedUser!.avatar}');
      
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

}

/// API-based Capsule Repository
class ApiCapsuleRepository implements CapsuleRepository {
  final ApiClient _apiClient = ApiClient();
  final ApiAuthRepository _authRepo = ApiAuthRepository();

  @override
  Future<Capsule?> getCapsuleById(String capsuleId) async {
    try {
      UuidUtils.validateCapsuleId(capsuleId);
      
      Logger.info('Fetching capsule by ID: $capsuleId');
      
      final response = await _apiClient.get(ApiConfig.capsuleById(capsuleId));
      
      final capsule = CapsuleMapper.fromJson(response as Map<String, dynamic>);
      Logger.info('Capsule fetched successfully: ${capsule.id}');
      return capsule;
    } catch (e, stackTrace) {
      Logger.error('Failed to get capsule by ID', error: e, stackTrace: stackTrace);
      if (e is NotFoundException) {
        return null;
      }
      if (e is AppException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to get capsule: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Capsule>> getCapsules({
    required String userId,
    bool asSender = true,
  }) async {
    try {
      UuidUtils.validateUserId(userId);

      // NOTE: User verification is now handled in providers to avoid excessive API calls
      // The backend uses JWT token to determine the user, so even if wrong userId is passed,
      // the backend will return data for the authenticated user (preventing data leakage)
      // We still validate UUID format and log the userId for debugging

      final box = asSender ? 'outbox' : 'inbox';
      
      Logger.info('Fetching capsules: userId=$userId, box=$box, asSender=$asSender');
      
      // Use a reasonable page size that balances performance and UX
      // Loading too many capsules (100) causes performance issues
      // But we need enough to show most users' capsules without pagination
      // Using 50 as a middle ground - fast enough but shows most users' capsules
      final pageSize = 50; // Balance between performance (20) and completeness (100)
      final response = await _apiClient.get(
        ApiConfig.capsules,
        queryParams: {
          'box': box,
          'page': AppConstants.defaultPage.toString(),
          'page_size': pageSize.toString(),
        },
      );

      final capsulesList = response['capsules'] as List<dynamic>? ?? [];
      final total = response['total'] as int? ?? capsulesList.length;
      Logger.info('Received ${capsulesList.length} capsules from API (total: $total)');
      
      // Log warning if there are more capsules than loaded (UX consideration)
      if (total > pageSize) {
        Logger.info('User has $total capsules but only $pageSize loaded. Consider implementing pagination.');
      }
      
      final capsules = capsulesList
          .map((json) => CapsuleMapper.fromJson(json as Map<String, dynamic>))
          .toList();

      // Don't sort here - sorting is handled by providers based on tab requirements
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
      // Validate input
      Validation.validateContent(capsule.content);
      if (capsule.label.isNotEmpty) {
        Validation.validateLabel(capsule.label);
      }
      Validation.validateUnlockDate(capsule.unlockAt);

      // Get current user for recipient resolution
      final currentUser = await _authRepo.getCurrentUser();
      if (currentUser == null) {
        throw RepositoryException(
          'User not authenticated. Please sign in and try again.',
        );
      }

      // Resolve recipient UUID (handles UUID validation and lookup)
      final recipientRepo = ApiRecipientRepository();
      final recipientId = await RecipientResolver.resolveRecipientId(
        recipientId: capsule.receiverId,
        currentUserId: currentUser.id,
        recipientRepo: recipientRepo,
        recipientName: capsule.receiverName,
      );

      Logger.info(
        'Creating capsule: recipientId=$recipientId, '
        'receiverName=${capsule.receiverName}, '
        'unlocksAt=${capsule.unlockAt}, '
        'isAnonymous=${capsule.isAnonymous}, '
        'revealDelaySeconds=${capsule.revealDelaySeconds}'
      );
      
      // Build request payload
      final payload = <String, dynamic>{
        'recipient_id': recipientId,
        'title': capsule.label.isNotEmpty ? capsule.label : null,
        'body_text': capsule.content,
        'unlocks_at': capsule.unlockAt.toUtc().toIso8601String(),
        'is_anonymous': capsule.isAnonymous,
        'is_disappearing': false,
      };
      
      // Add reveal_delay_seconds if anonymous
      if (capsule.isAnonymous && capsule.revealDelaySeconds != null) {
        payload['reveal_delay_seconds'] = capsule.revealDelaySeconds;
      }
      
      // Create capsule via API
      final response = await _apiClient.post(
        ApiConfig.capsules,
        payload,
      );

      final createdCapsule = CapsuleMapper.fromJson(response);
      Logger.info('Capsule created successfully: id=${createdCapsule.id}');
      return createdCapsule;
    } on RepositoryException {
      // Re-throw repository exceptions as-is
      rethrow;
    } on ValidationException {
      // Re-throw validation exceptions as-is
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to create capsule', error: e, stackTrace: stackTrace);
      
      // Handle recipient not found errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('recipient not found') || 
          errorStr.contains('404') ||
          (errorStr.contains('detail') && errorStr.contains('recipient'))) {
        throw RepositoryException(
          'Recipient not found. Please ensure you are connected with this user and try again.',
          originalError: e,
          stackTrace: stackTrace,
        );
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
      UuidUtils.validateCapsuleId(capsule.id);

      Validation.validateContent(capsule.content);

      final response = await _apiClient.put(
        ApiConfig.capsuleById(capsule.id),
        {
          'title': capsule.label.isNotEmpty ? capsule.label : null,
          'body_text': capsule.content,
        },
      );

      final updatedCapsule = CapsuleMapper.fromJson(response);
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
      UuidUtils.validateCapsuleId(capsuleId);

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
      UuidUtils.validateCapsuleId(capsuleId);

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
  /// 
  /// DEPRECATED: Capsules are now created directly with unlocks_at set.
  /// This method is kept for backward compatibility but should not be used.
  @Deprecated('Capsules are created with unlocks_at directly. Use createCapsule instead.')
  Future<Capsule> sealCapsule(String capsuleId, DateTime unlockAt) async {
    throw RepositoryException(
      'sealCapsule is deprecated. Capsules are created with unlocks_at directly.',
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
        'message': 'Unable to check. Please try again.',
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
          .map((json) => UserMapper.fromJson(json as Map<String, dynamic>))
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

}

/// API-based Recipient Repository
class ApiRecipientRepository implements RecipientRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<Recipient>> getRecipients(String userId) async {
    try {
      UuidUtils.validateUserId(userId);

      // NOTE: User verification is now handled in providers to avoid excessive API calls
      // The backend uses JWT token to determine the user, so even if wrong userId is passed,
      // the backend will return data for the authenticated user (preventing data leakage)
      // We still validate UUID format and log the userId for debugging

      Logger.info('Fetching recipients for user: $userId');
      
      try {
        final response = await _apiClient.getList(
          ApiConfig.recipients,
          queryParams: {
            'page': AppConstants.defaultPage.toString(),
            'page_size': AppConstants.maxPageSize.toString(),
          },
        );

        Logger.info('Received ${response.length} recipients from API');
        
        // Handle empty response gracefully
        if (response.isEmpty) {
          Logger.info('No recipients found for user: $userId');
          return [];
        }
        
        final recipients = response
            .map((json) {
              try {
                return RecipientMapper.fromJson(json as Map<String, dynamic>);
              } catch (e, stackTrace) {
                Logger.error('Failed to map recipient JSON', error: e, stackTrace: stackTrace);
                rethrow;
              }
            })
            .toList();

        Logger.debug('Successfully mapped ${recipients.length} recipients');
        return recipients;
      } on NotFoundException {
        // 404 from backend - treat as empty list (user has no recipients yet)
        Logger.info('Recipients endpoint returned 404, treating as empty list for user: $userId');
        return [];
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to get recipients', error: e, stackTrace: stackTrace);
      if (e is AppException && e is! NotFoundException) {
        rethrow;
      }
      // For other errors, return empty list instead of throwing
      // This prevents the UI from showing error when user simply has no recipients
      Logger.warning('Error fetching recipients, returning empty list: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<Recipient> createRecipient(Recipient recipient, {String? linkedUserId}) async {
    try {
      Validation.validateName(recipient.name);

      // Build request body
      final requestBody = <String, dynamic>{
        'name': recipient.name,
      };
      
      // Add username if available
      if (recipient.username != null && recipient.username!.isNotEmpty) {
        requestBody['username'] = recipient.username;
      }
      
      // CRITICAL: Include email if available (needed for inbox matching)
      // The email is used to match recipient.email to current_user.email in inbox queries
      if (recipient.email != null && recipient.email!.isNotEmpty) {
        requestBody['email'] = recipient.email;
      }
      
      // If a linked user ID is provided (from user search), include it
      // Note: Backend doesn't use this, but we include it for potential future use
      if (linkedUserId != null && linkedUserId.isNotEmpty) {
        requestBody['user_id'] = linkedUserId;
      }

      final response = await _apiClient.post(
        ApiConfig.recipients,
        requestBody,
      );

      final createdRecipient = RecipientMapper.fromJson(response);
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
      UuidUtils.validateRecipientId(recipientId);

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
}

/// API-based Connection Repository
/// Uses FastAPI backend instead of Supabase directly
class ApiConnectionRepository with StreamPollingMixin implements ConnectionRepository {
  final ApiClient _apiClient = ApiClient();
  final ApiAuthRepository _authRepo = ApiAuthRepository();
  
  // Polling intervals optimized for rate limiting (60 requests/minute)
  // Connection requests: 15 seconds = 4 requests/minute per endpoint (8 total for both)
  // This leaves plenty of headroom for other API calls
  static const Duration _connectionRequestsPollInterval = Duration(seconds: 15);

  /// Transform snake_case response from FastAPI to camelCase for Flutter models
  /// Handles UUID objects, datetime objects, and null values
  Map<String, dynamic> _transformConnectionRequest(Map<String, dynamic> json) {
    try {
      // Helper to safely convert values to strings
      String? _toString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        if (value is DateTime) return value.toIso8601String();
        return value.toString();
      }

      // Build user profiles from individual fields if available
      Map<String, dynamic>? fromUserProfile;
      Map<String, dynamic>? toUserProfile;
      
      final fromUserId = _toString(json['from_user_id']) ?? _toString(json['fromUserId']) ?? '';
      final toUserId = _toString(json['to_user_id']) ?? _toString(json['toUserId']) ?? '';
      
      // Build fromUserProfile (for incoming requests - sender's profile)
      if (fromUserId.isNotEmpty) {
        final firstName = json['from_user_first_name'] as String? ?? json['fromUserFirstName'] as String?;
        final lastName = json['from_user_last_name'] as String? ?? json['fromUserLastName'] as String?;
        final username = json['from_user_username'] as String? ?? json['fromUserUsername'] as String?;
        final avatarUrl = json['from_user_avatar_url'] as String? ?? json['fromUserAvatarUrl'] as String?;
        
        if (firstName != null || lastName != null || username != null) {
          final displayName = [firstName, lastName].whereType<String>().join(' ').trim();
          fromUserProfile = {
            'userId': fromUserId,
            'displayName': displayName.isNotEmpty ? displayName : (username ?? 'User'),
            'username': username,
            'avatarUrl': avatarUrl,
          };
        }
      }

      // Build toUserProfile (for outgoing requests - recipient's profile)
      if (toUserId.isNotEmpty) {
        final firstName = json['to_user_first_name'] as String? ?? json['toUserFirstName'] as String?;
        final lastName = json['to_user_last_name'] as String? ?? json['toUserLastName'] as String?;
        final username = json['to_user_username'] as String? ?? json['toUserUsername'] as String?;
        final avatarUrl = json['to_user_avatar_url'] as String? ?? json['toUserAvatarUrl'] as String?;
        
        if (firstName != null || lastName != null || username != null) {
          final displayName = [firstName, lastName].whereType<String>().join(' ').trim();
          toUserProfile = {
            'userId': toUserId,
            'displayName': displayName.isNotEmpty ? displayName : (username ?? 'User'),
            'username': username,
            'avatarUrl': avatarUrl,
          };
        }
      }

      return {
        'id': _toString(json['id']) ?? '',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': _toString(json['status']) ?? 'pending',
        'message': json['message'] as String?,
        'declinedReason': json['declined_reason'] as String? ?? json['declinedReason'] as String?,
        'actedAt': _toString(json['acted_at']) ?? _toString(json['actedAt']),
        'createdAt': _toString(json['created_at']) ?? _toString(json['createdAt']) ?? DateTime.now().toIso8601String(),
        'updatedAt': _toString(json['updated_at']) ?? _toString(json['updatedAt']) ?? DateTime.now().toIso8601String(),
        'fromUserProfile': fromUserProfile ?? json['from_user_profile'] ?? json['fromUserProfile'],
        'toUserProfile': toUserProfile ?? json['to_user_profile'] ?? json['toUserProfile'],
      };
    } catch (e, stackTrace) {
      Logger.error('Error transforming connection request response', error: e, stackTrace: stackTrace);
      Logger.error('Original JSON: $json');
      rethrow;
    }
  }

  @override
  Future<ConnectionRequest> sendConnectionRequest({
    required String toUserId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.connectionRequests,
        {
          'to_user_id': toUserId,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );

      final transformed = _transformConnectionRequest(response);
      return ConnectionRequest.fromJson(transformed);
    } catch (e, stackTrace) {
      Logger.error('Failed to send connection request', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      // Check if it's a JSON parsing error
      if (e.toString().contains('fromJson') || e.toString().contains('JSON')) {
        Logger.error('JSON parsing error. Response was: ${e.toString()}');
        throw RepositoryException(
          'Invalid response format from server. Please try again.',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
      throw RepositoryException(
        'Failed to send connection request: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<ConnectionRequest> respondToRequest({
    required String requestId,
    required bool accept,
    String? declinedReason,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiConfig.connectionRequestById(requestId),
        {
          'status': accept ? 'accepted' : 'declined',
          if (declinedReason != null && declinedReason.isNotEmpty)
            'declined_reason': declinedReason,
        },
      );

      final transformed = _transformConnectionRequest(response);
      return ConnectionRequest.fromJson(transformed);
    } catch (e, stackTrace) {
      Logger.error('Failed to respond to request', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to respond to connection request: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<PendingRequests> getPendingRequests() async {
    try {
      final incomingResponse = await _apiClient.get(ApiConfig.incomingRequests);
      final outgoingResponse = await _apiClient.get(ApiConfig.outgoingRequests);


      final incomingList = (incomingResponse['requests'] as List?)
              ?.map((json) {
                try {
                  return ConnectionRequest.fromJson(_transformConnectionRequest(json as Map<String, dynamic>));
                } catch (e, stackTrace) {
                  Logger.error('Error parsing incoming request', error: e, stackTrace: stackTrace);
                  Logger.error('Problematic JSON: $json');
                  rethrow;
                }
              })
              .toList() ??
          [];
      final outgoingList = (outgoingResponse['requests'] as List?)
              ?.map((json) {
                try {
                  return ConnectionRequest.fromJson(_transformConnectionRequest(json as Map<String, dynamic>));
                } catch (e, stackTrace) {
                  Logger.error('Error parsing outgoing request', error: e, stackTrace: stackTrace);
                  Logger.error('Problematic JSON: $json');
                  rethrow;
                }
              })
              .toList() ??
          [];

      return PendingRequests(
        incoming: incomingList,
        outgoing: outgoingList,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to get pending requests', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to get pending requests: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Connection>> getConnections() async {
    try {
      final response = await _apiClient.get(ApiConfig.connections);

      final connectionsList = (response['connections'] as List?)
              ?.map((json) {
                final connJson = json as Map<String, dynamic>;
                // The API returns user_id_1 and user_id_2, but Connection model needs
                // otherUserId and otherUserProfile. We'll need to fetch user profiles.
                // For now, return a basic connection - we can enhance this later
                final userId1 = connJson['user_id_1']?.toString() ?? connJson['userId1']?.toString() ?? '';
                final userId2 = connJson['user_id_2']?.toString() ?? connJson['userId2']?.toString() ?? '';
                final connectedAtStr = connJson['connected_at']?.toString() ?? connJson['connectedAt']?.toString() ?? DateTime.now().toIso8601String();
                
                return Connection(
                  userId1: userId1,
                  userId2: userId2,
                  connectedAt: DateTime.parse(connectedAtStr),
                  otherUserId: '', // Will be set by caller
                  otherUserProfile: const ConnectionUserProfile(
                    userId: '',
                    displayName: 'Unknown',
                  ),
                );
              })
              .toList() ??
          [];

      return connectionsList;
    } catch (e, stackTrace) {
      Logger.error('Failed to get connections', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw RepositoryException(
        'Failed to get connections: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<ConnectionUserProfile>> searchUsers(String query, {String? userId}) async {
    // Use the existing user search endpoint (same as AddRecipientScreen)
    try {
      final users = await ApiUserService().searchUsers(query);
      return users.map((user) {
        final displayName = user.name.isNotEmpty ? user.name : user.username;
        return ConnectionUserProfile(
          userId: user.id,
          displayName: displayName,
          avatarUrl: user.avatarUrl,
          username: user.username,
        );
      }).toList();
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

  @override
  Future<bool> areConnected(String userId1, String userId2) async {
    try {
      final connections = await getConnections();
      return connections.any((conn) =>
          (conn.userId1 == userId1 && conn.userId2 == userId2) ||
          (conn.userId1 == userId2 && conn.userId2 == userId1));
    } catch (e, stackTrace) {
      Logger.error('Failed to check connection status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<void> blockUser(String userId) async {
    // TODO: Implement blocking when backend endpoint is available
    throw UnimplementedError('Blocking not yet implemented in API');
  }

  @override
  Future<void> unblockUser(String userId) async {
    // TODO: Implement unblocking when backend endpoint is available
    throw UnimplementedError('Unblocking not yet implemented in API');
  }

  @override
  Stream<List<ConnectionRequest>> watchIncomingRequests() {
    return createPollingStream<List<ConnectionRequest>>(
      loadData: _loadIncomingRequestsData,
      pollInterval: _connectionRequestsPollInterval, // 15 seconds to avoid rate limits
    );
  }
  
  Future<List<ConnectionRequest>> _loadIncomingRequestsData() async {
    Logger.debug('Loading incoming requests from API...');
    final response = await _apiClient.get(ApiConfig.incomingRequests);
    
    final requestsRaw = response['requests'];
    if (requestsRaw is! List) {
      Logger.warning('Invalid response format for incoming requests');
      return [];
    }
    
    final requestsList = requestsRaw
        .map((json) {
          try {
            final transformed = _transformConnectionRequest(json as Map<String, dynamic>);
            return ConnectionRequest.fromJson(transformed);
          } catch (e, stackTrace) {
            Logger.error('Error parsing incoming request', error: e, stackTrace: stackTrace);
            return null;
          }
        })
        .whereType<ConnectionRequest>()
        .toList();
    
    Logger.debug('Successfully parsed ${requestsList.length} incoming requests');
    return requestsList;
  }
  

  @override
  Stream<List<ConnectionRequest>> watchOutgoingRequests() {
    return createPollingStream<List<ConnectionRequest>>(
      loadData: _loadOutgoingRequestsData,
      pollInterval: _connectionRequestsPollInterval, // 15 seconds to avoid rate limits
    );
  }
  
  Future<List<ConnectionRequest>> _loadOutgoingRequestsData() async {
    Logger.debug('Loading outgoing requests from API...');
    final response = await _apiClient.get(ApiConfig.outgoingRequests);
    
    final requestsRaw = response['requests'];
    if (requestsRaw is! List) {
      Logger.warning('Invalid response format for outgoing requests');
      return [];
    }
    
    final requestsList = requestsRaw
        .map((json) {
          try {
            final transformed = _transformConnectionRequest(json as Map<String, dynamic>);
            return ConnectionRequest.fromJson(transformed);
          } catch (e, stackTrace) {
            Logger.error('Error parsing outgoing request', error: e, stackTrace: stackTrace);
            return null;
          }
        })
        .whereType<ConnectionRequest>()
        .toList();
    
    Logger.debug('Successfully parsed ${requestsList.length} outgoing requests');
    return requestsList;
  }

  @override
  Stream<List<Connection>> watchConnections() {
    return createPollingStream<List<Connection>>(
      loadData: _loadConnectionsData,
      pollInterval: _connectionRequestsPollInterval, // 15 seconds to avoid rate limits
    );
  }
  
  Future<List<Connection>> _loadConnectionsData() async {
    Logger.debug('Loading connections from API...');
    final response = await _apiClient.get(ApiConfig.connections);
    
    // Get current user ID to determine which user is the "other" user
    final currentUser = await _authRepo.getCurrentUser();
    final currentUserId = currentUser?.id ?? '';
    
    final connectionsRaw = response['connections'];
    if (connectionsRaw is! List) {
      Logger.warning('Invalid response format for connections');
      return [];
    }
    
    final connectionsList = connectionsRaw
        .map((json) {
          try {
            final connJson = json as Map<String, dynamic>;
            final userId1 = connJson['user_id_1']?.toString() ?? connJson['userId1']?.toString() ?? '';
            final userId2 = connJson['user_id_2']?.toString() ?? connJson['userId2']?.toString() ?? '';
            final connectedAtStr = connJson['connected_at']?.toString() ?? connJson['connectedAt']?.toString() ?? DateTime.now().toIso8601String();
            
            // Determine which user is the "other" user
            final otherUserId = userId1 == currentUserId ? userId2 : userId1;
            
            // Build profile from individual fields
            final firstName = connJson['other_user_first_name'] as String?;
            final lastName = connJson['other_user_last_name'] as String?;
            final username = connJson['other_user_username'] as String?;
            final avatarUrl = connJson['other_user_avatar_url'] as String?;
            
            final displayName = [firstName, lastName].whereType<String>().join(' ').trim();
            final profileDisplayName = displayName.isNotEmpty 
                ? displayName 
                : (username ?? 'User ${otherUserId.substring(0, 8)}...');
            
            final otherUserProfile = ConnectionUserProfile(
              userId: otherUserId,
              displayName: profileDisplayName,
              username: username,
              avatarUrl: avatarUrl,
            );
            
            return Connection(
              userId1: userId1,
              userId2: userId2,
              connectedAt: DateTime.parse(connectedAtStr),
              otherUserId: otherUserId,
              otherUserProfile: otherUserProfile,
            );
          } catch (e, stackTrace) {
            Logger.error('Error parsing connection', error: e, stackTrace: stackTrace);
            Logger.error('Problematic JSON: $json');
            return null;
          }
        })
        .whereType<Connection>()
        .toList();
    
    Logger.debug('Successfully parsed ${connectionsList.length} connections');
    return connectionsList;
  }

  @override
  Future<ConnectionDetail> getConnectionDetail(String connectionId, {String? userId}) async {
    try {
      // Security: Validate connectionId format (UUID)
      try {
        Validation.validateConnectionId(connectionId);
      } catch (e) {
        Logger.error('Invalid connection ID format', error: e);
        throw ValidationException('Invalid connection ID format');
      }
      
      // Get current user ID
      final currentUser = await _authRepo.getCurrentUser();
      final currentUserId = userId ?? currentUser?.id;
      
      if (currentUserId == null) {
        throw AuthenticationException('Not authenticated. Please log in to view connection details.');
      }
      
      // Security: Validate currentUserId format
      try {
        Validation.validateUserId(currentUserId);
      } catch (e) {
        Logger.error('Invalid user ID format', error: e);
        throw AuthenticationException('Invalid user authentication');
      }
      
      Logger.info('Getting connection detail via API for connectionId: $connectionId, currentUserId: $currentUserId');
      
      // Use _loadConnectionsData() which properly loads and parses connections from API
      final connections = await _loadConnectionsData();
      Logger.info('Loaded ${connections.length} connections from API');
      
      if (connections.isEmpty) {
        Logger.warning('No connections found in API response');
        throw NetworkException('No connections found. Please ensure you are connected with this user.');
      }
      
      // Find the connection matching the connectionId
      final connection = connections.firstWhere(
        (c) => c.otherUserId == connectionId,
        orElse: () {
          final availableIds = connections.map((c) => c.otherUserId).toList();
          Logger.warning('Connection not found. Looking for: $connectionId, Available: $availableIds');
          throw NetworkException('Connection not found. This user may not be in your connections list.');
        },
      );
      
      Logger.info('Found connection: ${connection.otherUserProfile.displayName}');
      
      // Calculate letter counts using connection user ID (linkedUserId) - production-ready, optimized
      // Strategy: Use connection user ID (stable UUID) to find recipient UUIDs from existing capsules
      // This avoids name-based matching which can fail when names change (e.g., "test1" -> "test2")
      // CRITICAL: We use linkedUserId (connection user ID) as the stable identifier, not names
      final capsuleRepo = ApiCapsuleRepository();
      final recipientRepo = ApiRecipientRepository();
      
      // Get recipients list to find recipient with linkedUserId = connectionId
      // This gives us the recipient record that represents this connection (if it exists)
      final currentUserRecipients = await recipientRepo.getRecipients(currentUserId);
      final connectionRecipient = currentUserRecipients.firstWhere(
        (r) => r.linkedUserId == connectionId,
        orElse: () => Recipient(
          userId: currentUserId,
          name: connection.otherUserProfile.displayName,
          username: connection.otherUserProfile.username,
          linkedUserId: connectionId,
        ),
      );
      
      // Letters sent: Count letters from current user (A) to connection user (B)
      // Strategy: Use recipient UUID owned by current user with linked_user_id = connectionId
      // This is the exact recipient UUID that represents the connection user (B) in current user's (A) recipient list
      int lettersSent = 0;
      try {
        // Get the exact recipient UUID from recipients API (should have linkedUserId = connectionId)
        String? currentUserRecipientId;
        
        // The connectionRecipient should already have the correct UUID if it was found
        if (connectionRecipient.id.length == 36 && connectionRecipient.id.contains('-')) {
          currentUserRecipientId = connectionRecipient.id;
          Logger.info('Using recipient UUID from recipients API (linkedUserId=$connectionId): $currentUserRecipientId');
        } else {
          // Fallback: Try to get it from Supabase directly
          try {
            if (SupabaseConfig.isInitialized) {
              final recipientsResponse = await SupabaseConfig.client
                  .from('recipients')
                  .select('id, linked_user_id')
                  .eq('owner_id', currentUserId)
                  .eq('linked_user_id', connectionId)
                  .maybeSingle();
              
              if (recipientsResponse != null) {
                currentUserRecipientId = recipientsResponse['id'] as String?;
                Logger.info('Found recipient UUID from Supabase (owner=$currentUserId, linked_user_id=$connectionId): $currentUserRecipientId');
              }
            }
          } catch (e) {
            Logger.warning('Error querying Supabase for recipient, will use fallback method', error: e);
          }
        }
        
        // Count capsules using the exact recipient UUID
        if (currentUserRecipientId != null) {
          final outboxCapsules = await capsuleRepo.getCapsules(
            userId: currentUserId,
            asSender: true,
          );
          
          // Count only capsules sent to this specific recipient (exact UUID match)
          lettersSent = outboxCapsules
              .where((c) => c.receiverId == currentUserRecipientId)
              .length;
          
          Logger.info(
            'Found $lettersSent letters sent to connection $connectionId '
            'using recipient UUID: $currentUserRecipientId'
          );
        } else {
          Logger.warning('Could not determine recipient UUID for connection user from current user');
        }
      } catch (e) {
        Logger.warning('Error counting sent letters', error: e);
      }
      
      // Letters received: Find recipient UUID owned by connection user that represents current user
      // Strategy: Query Supabase directly to get recipient owned by connection user with linked_user_id = currentUserId
      // This is the exact recipient UUID that represents the current user in the connection user's recipient list
      int lettersReceived = 0;
      try {
        // First, try to get the exact recipient UUID from Supabase
        String? otherUserRecipientId;
        try {
          if (SupabaseConfig.isInitialized) {
            final recipientsResponse = await SupabaseConfig.client
                .from('recipients')
                .select('id, linked_user_id')
                .eq('owner_id', connectionId)
                .eq('linked_user_id', currentUserId)
                .maybeSingle();
            
            if (recipientsResponse != null) {
              otherUserRecipientId = recipientsResponse['id'] as String?;
              Logger.info('Found recipient UUID from Supabase (owner=$connectionId, linked_user_id=$currentUserId): $otherUserRecipientId');
            } else {
              Logger.info('No recipient found in Supabase for owner=$connectionId, linked_user_id=$currentUserId');
            }
          }
        } catch (e) {
          Logger.warning('Error querying Supabase for recipient, will use fallback method', error: e);
        }
        
        // If we couldn't get it from Supabase, use fallback: most common recipient_id from capsules
        if (otherUserRecipientId == null) {
          Logger.info('Using fallback method: finding most common recipient_id from capsules');
          final inboxCapsules = await capsuleRepo.getCapsules(
            userId: currentUserId,
            asSender: false,
          );
          
          if (inboxCapsules.isNotEmpty) {
            final capsulesFromConnection = inboxCapsules
                .where((c) => c.senderId == connectionId)
                .toList();
            
            if (capsulesFromConnection.isNotEmpty) {
              // Find the most common recipient_id (should be the one representing current user)
              final recipientIdCounts = <String, int>{};
              for (final capsule in capsulesFromConnection) {
                final recipientId = capsule.receiverId;
                if (recipientId.length == 36 && recipientId.contains('-')) {
                  recipientIdCounts[recipientId] = (recipientIdCounts[recipientId] ?? 0) + 1;
                }
              }
              
              if (recipientIdCounts.isNotEmpty) {
                int maxCount = 0;
                recipientIdCounts.forEach((recipientId, count) {
                  if (count > maxCount) {
                    maxCount = count;
                    otherUserRecipientId = recipientId;
                  }
                });
                Logger.info('Using fallback recipient UUID: $otherUserRecipientId (appeared $maxCount times)');
              }
            }
          }
        }
        
        // Count capsules using the recipient UUID
        if (otherUserRecipientId != null) {
          final inboxCapsules = await capsuleRepo.getCapsules(
            userId: currentUserId,
            asSender: false,
          );
          
          lettersReceived = inboxCapsules
              .where((c) => c.senderId == connectionId && c.receiverId == otherUserRecipientId)
              .length;
          
          Logger.info(
            'Found $lettersReceived letters received from connection $connectionId '
            'using recipient UUID: $otherUserRecipientId'
          );
        } else {
          Logger.warning('Could not determine recipient UUID for current user from connection user');
        }
      } catch (e) {
        Logger.warning('Error counting received letters', error: e);
      }
      
      Logger.info('Final letter counts - Sent: $lettersSent, Received: $lettersReceived');
      
      return ConnectionDetail(
        connection: connection,
        lettersSent: lettersSent,
        lettersReceived: lettersReceived,
      );
    } catch (e, stackTrace) {
      Logger.error('Error getting connection detail via API', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to get connection detail: ${e.toString()}');
    }
  }
}

