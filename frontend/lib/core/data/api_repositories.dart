import 'package:openon_app/core/data/api_client.dart';
import 'package:openon_app/core/data/api_config.dart';
import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/data/token_storage.dart';
import 'package:openon_app/core/data/user_mapper.dart';
import 'package:openon_app/core/data/capsule_mapper.dart';
import 'package:openon_app/core/data/recipient_mapper.dart';
import 'package:openon_app/core/data/connection_repository.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'dart:async';

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
      _cachedUser = UserMapper.fromJson(userResponse);
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
      
      // Log for debugging
      Logger.info('Fetching capsules: userId=$userId, box=$box, asSender=$asSender');
      
      final response = await _apiClient.get(
        ApiConfig.capsules,
        queryParams: {
          'box': box,
          'page': AppConstants.defaultPage.toString(),
          'page_size': AppConstants.maxPageSize.toString(),
        },
      );

      final capsulesList = response['capsules'] as List<dynamic>? ?? [];
      Logger.info('Received ${capsulesList.length} capsules from API');
      
      final capsules = capsulesList
          .map((json) => CapsuleMapper.fromJson(json as Map<String, dynamic>))
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
      Validation.validateUnlockDate(capsule.unlockAt);

      // Backend expects recipient_id (UUID of recipient record), not receiver_id (user ID)
      // The capsule.receiverId should be the recipient.id, not a user ID
      Logger.info('Creating capsule with recipient_id: ${capsule.receiverId}, unlocks_at: ${capsule.unlockAt}');
      
      final response = await _apiClient.post(
        ApiConfig.capsules,
        {
          'recipient_id': capsule.receiverId, // This should be recipient.id (UUID)
          'title': capsule.label.isNotEmpty ? capsule.label : null,
          'body_text': capsule.content, // Backend uses body_text, not body
          'unlocks_at': capsule.unlockAt.toUtc().toIso8601String(), // Backend expects unlocks_at
          'is_anonymous': false, // Default to non-anonymous
          'is_disappearing': false, // Default to non-disappearing
        },
      );

      final createdCapsule = CapsuleMapper.fromJson(response);
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
      if (userId.isEmpty) {
        throw const ValidationException('User ID cannot be empty');
      }

      Logger.info('Fetching recipients for user: $userId');
      
      final response = await _apiClient.getList(
        ApiConfig.recipients,
        queryParams: {
          'page': AppConstants.defaultPage.toString(),
          'page_size': AppConstants.maxPageSize.toString(),
        },
      );

      Logger.info('Received ${response.length} recipients from API');
      
      // Log raw response for debugging
      if (response.isNotEmpty) {
        Logger.debug('First recipient raw JSON: ${response[0]}');
      } else {
        Logger.info('API returned empty recipients list');
      }

      final recipients = response
          .map((json) {
            try {
              Logger.debug('Mapping recipient JSON: $json');
              final recipient = RecipientMapper.fromJson(json as Map<String, dynamic>);
              Logger.debug('Mapped recipient: id=${recipient.id}, name=${recipient.name}');
              return recipient;
            } catch (e, stackTrace) {
              Logger.error('Failed to map recipient JSON: $json', error: e, stackTrace: stackTrace);
              rethrow;
            }
          })
          .toList();

      Logger.info('Successfully mapped ${recipients.length} recipients');
      if (recipients.isNotEmpty) {
        Logger.info('First recipient: ${recipients[0].name} (${recipients[0].id})');
      }
      return recipients;
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
        'relationship': recipient.relationship,
      };
      
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
}

/// API-based Connection Repository
/// Uses FastAPI backend instead of Supabase directly
class ApiConnectionRepository implements ConnectionRepository {
  final ApiClient _apiClient = ApiClient();
  final ApiAuthRepository _authRepo = ApiAuthRepository();

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

      // Build user profile from individual fields if available
      Map<String, dynamic>? fromUserProfile;
      final fromUserId = _toString(json['from_user_id']) ?? _toString(json['fromUserId']) ?? '';
      print('🔵 [TRANSFORM] Building profile for userId: $fromUserId');
      print('🔵 [TRANSFORM] Available keys: ${json.keys.toList()}');
      
      if (fromUserId.isNotEmpty) {
        final firstName = json['from_user_first_name'] as String? ?? json['fromUserFirstName'] as String?;
        final lastName = json['from_user_last_name'] as String? ?? json['fromUserLastName'] as String?;
        final username = json['from_user_username'] as String? ?? json['fromUserUsername'] as String?;
        final avatarUrl = json['from_user_avatar_url'] as String? ?? json['fromUserAvatarUrl'] as String?;
        
        print('🔵 [TRANSFORM] Profile fields - firstName: $firstName, lastName: $lastName, username: $username, avatarUrl: $avatarUrl');
        
        if (firstName != null || lastName != null || username != null) {
          final displayName = [firstName, lastName].whereType<String>().join(' ').trim();
          fromUserProfile = {
            'userId': fromUserId,
            'displayName': displayName.isNotEmpty ? displayName : (username ?? 'User'),
            'username': username,
            'avatarUrl': avatarUrl,
          };
          print('🟢 [TRANSFORM] Created profile: $fromUserProfile');
        } else {
          print('🟡 [TRANSFORM] No profile fields found, will use fallback');
        }
      }

      return {
        'id': _toString(json['id']) ?? '',
        'fromUserId': fromUserId,
        'toUserId': _toString(json['to_user_id']) ?? _toString(json['toUserId']) ?? '',
        'status': _toString(json['status']) ?? 'pending',
        'message': json['message'] as String?,
        'declinedReason': json['declined_reason'] as String? ?? json['declinedReason'] as String?,
        'actedAt': _toString(json['acted_at']) ?? _toString(json['actedAt']),
        'createdAt': _toString(json['created_at']) ?? _toString(json['createdAt']) ?? DateTime.now().toIso8601String(),
        'updatedAt': _toString(json['updated_at']) ?? _toString(json['updatedAt']) ?? DateTime.now().toIso8601String(),
        'fromUserProfile': fromUserProfile ?? json['from_user_profile'] ?? json['fromUserProfile'],
        'toUserProfile': json['to_user_profile'] ?? json['toUserProfile'],
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
      Logger.debug('Transformed connection request: $transformed');
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
      Logger.debug('Transformed connection request response: $transformed');
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

      Logger.debug('Incoming response: $incomingResponse');
      Logger.debug('Outgoing response: $outgoingResponse');

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
    // Use a broadcast stream that can be listened to multiple times
    // Poll every 5 seconds for updates
    final controller = StreamController<List<ConnectionRequest>>.broadcast();
    
    // Load data immediately (don't emit empty list first)
    _loadIncomingRequests(controller);
    
    // Poll for updates every 5 seconds
    Timer? timer;
    timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (controller.isClosed) {
        t.cancel();
        return;
      }
      _loadIncomingRequests(controller);
    });
    
    // Cancel timer when stream is closed
    controller.onCancel = () {
      timer?.cancel();
    };
    
    return controller.stream;
  }
  
  Future<void> _loadIncomingRequests(StreamController<List<ConnectionRequest>> controller) async {
    try {
      print('🔵 [CONNECTION] Loading incoming requests from API...');
      Logger.info('Loading incoming requests from API...');
      final response = await _apiClient.get(ApiConfig.incomingRequests);
      print('🔵 [CONNECTION] API response: $response');
      print('🔵 [CONNECTION] Response keys: ${response.keys.toList()}');
      Logger.info('Incoming requests API response: $response');
      Logger.info('Response type: ${response.runtimeType}');
      Logger.info('Response keys: ${response.keys.toList()}');
      
      final requestsRaw = response['requests'];
      print('🔵 [CONNECTION] Requests raw: $requestsRaw');
      print('🔵 [CONNECTION] Requests type: ${requestsRaw.runtimeType}');
      print('🔵 [CONNECTION] Is List: ${requestsRaw is List}');
      Logger.info('Requests raw: $requestsRaw');
      Logger.info('Requests type: ${requestsRaw.runtimeType}');
      Logger.info('Is List: ${requestsRaw is List}');
      
      if (requestsRaw is List) {
        print('🔵 [CONNECTION] Requests list length: ${requestsRaw.length}');
        Logger.info('Requests list length: ${requestsRaw.length}');
      }
      
      final requestsList = (requestsRaw as List?)
              ?.map((json) {
                try {
                  print('🔵 [CONNECTION] Parsing request JSON: $json');
                  Logger.debug('Parsing request JSON: $json');
                  final transformed = _transformConnectionRequest(json as Map<String, dynamic>);
                  print('🔵 [CONNECTION] Transformed: $transformed');
                  Logger.debug('Transformed: $transformed');
                  final request = ConnectionRequest.fromJson(transformed);
                  print('🔵 [CONNECTION] Parsed request: id=${request.id}, from=${request.fromUserId}, to=${request.toUserId}, status=${request.status}');
                  Logger.debug('Parsed request: ${request.id}, from: ${request.fromUserId}, to: ${request.toUserId}');
                  return request;
                } catch (e, stackTrace) {
                  print('🔴 [CONNECTION] Error parsing request: $e');
                  print('🔴 [CONNECTION] JSON: $json');
                  Logger.error('Error parsing incoming request', error: e, stackTrace: stackTrace);
                  Logger.error('Problematic JSON: $json');
                  return null;
                }
              })
              .whereType<ConnectionRequest>()
              .toList() ??
          [];
      
      print('🟢 [CONNECTION] Successfully parsed ${requestsList.length} incoming requests');
      for (var i = 0; i < requestsList.length; i++) {
        print('🟢 [CONNECTION] Request $i: id=${requestsList[i].id}, status=${requestsList[i].status}');
        Logger.info('Request $i: id=${requestsList[i].id}, status=${requestsList[i].status}');
      }
      
      if (!controller.isClosed) {
        print('🟢 [CONNECTION] Adding ${requestsList.length} requests to stream. Controller closed: ${controller.isClosed}');
        Logger.info('Adding ${requestsList.length} requests to stream');
        controller.add(requestsList);
        print('🟢 [CONNECTION] Requests added to stream successfully');
        Logger.info('Requests added to stream successfully');
      } else {
        print('🟡 [CONNECTION] Stream controller is CLOSED, cannot add requests');
        Logger.warning('Stream controller is closed, cannot add requests');
      }
    } catch (e, stackTrace) {
      print('🔴 [CONNECTION] Error loading incoming requests: $e');
      print('🔴 [CONNECTION] Stack: $stackTrace');
      Logger.error('Error loading incoming requests', error: e, stackTrace: stackTrace);
      if (!controller.isClosed) {
        controller.addError(e, stackTrace);
      }
    }
  }

  @override
  Stream<List<ConnectionRequest>> watchOutgoingRequests() {
    // Use a broadcast stream that can be listened to multiple times
    // Poll every 5 seconds for updates
    final controller = StreamController<List<ConnectionRequest>>.broadcast();
    
    // Load data immediately (don't emit empty list first)
    _loadOutgoingRequests(controller);
    
    // Poll for updates every 5 seconds
    Timer? timer;
    timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (controller.isClosed) {
        t.cancel();
        return;
      }
      _loadOutgoingRequests(controller);
    });
    
    // Cancel timer when stream is closed
    controller.onCancel = () {
      timer?.cancel();
    };
    
    return controller.stream;
  }
  
  Future<void> _loadOutgoingRequests(StreamController<List<ConnectionRequest>> controller) async {
    try {
      Logger.info('Loading outgoing requests from API...');
      final response = await _apiClient.get(ApiConfig.outgoingRequests);
      Logger.info('Outgoing requests API response: $response');
      
      final requestsRaw = response['requests'];
      Logger.info('Outgoing requests raw: $requestsRaw, type: ${requestsRaw.runtimeType}, is List: ${requestsRaw is List}');
      
      if (requestsRaw is List) {
        Logger.info('Outgoing requests list length: ${requestsRaw.length}');
      }
      
      final requestsList = (requestsRaw as List?)
              ?.map((json) {
                try {
                  Logger.debug('Parsing outgoing request JSON: $json');
                  final transformed = _transformConnectionRequest(json as Map<String, dynamic>);
                  Logger.debug('Transformed outgoing: $transformed');
                  final request = ConnectionRequest.fromJson(transformed);
                  Logger.debug('Parsed outgoing request: ${request.id}, status=${request.status}');
                  return request;
                } catch (e, stackTrace) {
                  Logger.error('Error parsing outgoing request', error: e, stackTrace: stackTrace);
                  Logger.error('Problematic JSON: $json');
                  return null;
                }
              })
              .whereType<ConnectionRequest>()
              .toList() ??
          [];
      
      Logger.info('Successfully parsed ${requestsList.length} outgoing requests');
      if (!controller.isClosed) {
        Logger.info('Adding ${requestsList.length} outgoing requests to stream');
        controller.add(requestsList);
      } else {
        Logger.warning('Stream controller is closed, cannot add outgoing requests');
      }
    } catch (e, stackTrace) {
      Logger.error('Error loading outgoing requests', error: e, stackTrace: stackTrace);
      if (!controller.isClosed) {
        controller.addError(e, stackTrace);
      }
    }
  }

  @override
  Stream<List<Connection>> watchConnections() {
    // Use a broadcast stream that can be listened to multiple times
    // Poll every 5 seconds for updates
    final controller = StreamController<List<Connection>>.broadcast();
    
    // Load data immediately (don't emit empty list first)
    _loadConnections(controller);
    
    // Poll for updates every 5 seconds
    Timer? timer;
    timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (controller.isClosed) {
        t.cancel();
        return;
      }
      _loadConnections(controller);
    });
    
    // Cancel timer when stream is closed
    controller.onCancel = () {
      timer?.cancel();
    };
    
    return controller.stream;
  }
  
  Future<void> _loadConnections(StreamController<List<Connection>> controller) async {
    try {
      final response = await _apiClient.get(ApiConfig.connections);
      Logger.debug('Connections response: $response');
      
      // Get current user ID to determine which user is the "other" user
      final currentUser = await _authRepo.getCurrentUser();
      final currentUserId = currentUser?.id ?? '';
      
      final connectionsList = (response['connections'] as List?)
              ?.map((json) {
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
              .toList() ??
          [];
      
      Logger.debug('Parsed ${connectionsList.length} connections');
      if (!controller.isClosed) {
        controller.add(connectionsList);
      }
    } catch (e, stackTrace) {
      Logger.error('Error loading connections', error: e, stackTrace: stackTrace);
      if (!controller.isClosed) {
        controller.addError(e, stackTrace);
      }
    }
  }
}

