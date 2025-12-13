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
import 'package:openon_app/core/data/stream_polling_mixin.dart';
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
      
      Logger.info('Fetching capsules: userId=$userId, box=$box, asSender=$asSender');
      
      // Use default page size instead of max to reduce load time
      // Max page size (100) is too large and causes performance issues
      final response = await _apiClient.get(
        ApiConfig.capsules,
        queryParams: {
          'box': box,
          'page': AppConstants.defaultPage.toString(),
          'page_size': AppConstants.defaultPageSize.toString(), // Use default (20) instead of max (100)
        },
      );

      final capsulesList = response['capsules'] as List<dynamic>? ?? [];
      Logger.info('Received ${capsulesList.length} capsules from API');
      
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
class ApiConnectionRepository with StreamPollingMixin implements ConnectionRepository {
  final ApiClient _apiClient = ApiClient();
  final ApiAuthRepository _authRepo = ApiAuthRepository();
  
  static const Duration _pollInterval = Duration(seconds: 5);

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
      pollInterval: _pollInterval,
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
      pollInterval: _pollInterval,
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
      pollInterval: _pollInterval,
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
      
      // Calculate letter counts by querying capsules
      // Get recipients to find the recipient IDs that link the two users
      final recipientRepo = ApiRecipientRepository();
      final currentUserRecipients = await recipientRepo.getRecipients(currentUserId);
      
      Logger.info('Checking ${currentUserRecipients.length} recipients for connection $connectionId');
      
      // Find recipient for the other user (connection-based recipients have linkedUserId)
      String? currentUserRecipientId;
      for (final recipient in currentUserRecipients) {
        if (recipient.linkedUserId == connectionId) {
          currentUserRecipientId = recipient.id;
          Logger.info('Found recipient for connection by linkedUserId: ${recipient.id} (name: ${recipient.name})');
          break;
        }
      }
      
      // If not found by linkedUserId, try matching by name (sanitized for security)
      if (currentUserRecipientId == null) {
        final sanitizedOtherDisplayName = Validation.sanitizeString(
          connection.otherUserProfile.displayName,
        ).toLowerCase();
        Logger.info('Trying name match for: "$sanitizedOtherDisplayName"');
        for (final recipient in currentUserRecipients) {
          final sanitizedRecipientName = Validation.sanitizeString(recipient.name).toLowerCase();
          if (sanitizedRecipientName == sanitizedOtherDisplayName ||
              sanitizedRecipientName.contains(sanitizedOtherDisplayName) ||
              sanitizedOtherDisplayName.contains(sanitizedRecipientName)) {
            currentUserRecipientId = recipient.id;
            Logger.info('Found recipient by name match: ${recipient.id} (name: ${recipient.name})');
            break;
          }
        }
      }
      
      if (currentUserRecipientId == null) {
        Logger.warning('Could not find recipient for connection $connectionId. Available recipients: ${currentUserRecipients.map((r) => '${r.name} (linkedUserId: ${r.linkedUserId})').join(", ")}');
      }
      
      // Get capsules to calculate counts
      final capsuleRepo = ApiCapsuleRepository();
      
      // Letters sent: total outbox capsules where recipient_id matches
      // Outbox = all capsules sent by current user (sender_id = currentUserId)
      // Filter by recipient_id = currentUserRecipientId to get only letters to this connection
      int lettersSent = 0;
      if (currentUserRecipientId != null) {
        try {
          final outboxCapsules = await capsuleRepo.getCapsules(
            userId: currentUserId,
            asSender: true,
          );
          Logger.info('Retrieved ${outboxCapsules.length} total outbox capsules');
          lettersSent = outboxCapsules
              .where((c) => c.receiverId == currentUserRecipientId)
              .length;
          Logger.info('Found $lettersSent letters sent to recipient $currentUserRecipientId (out of ${outboxCapsules.length} total sent)');
        } catch (e) {
          Logger.warning('Error counting sent letters', error: e);
        }
      } else {
        Logger.warning('Cannot count sent letters: recipient not found for connection');
      }
      
      // Letters received: total inbox capsules where sender_id matches connectionId
      // Inbox = all capsules received by current user (already filtered by backend)
      // Filter by sender_id = connectionId to get only letters from this connection
      int lettersReceived = 0;
      try {
        final inboxCapsules = await capsuleRepo.getCapsules(
          userId: currentUserId,
          asSender: false,
        );
        Logger.info('Retrieved ${inboxCapsules.length} total inbox capsules');
        lettersReceived = inboxCapsules
            .where((c) => c.senderId == connectionId)
            .length;
        Logger.info('Found $lettersReceived letters received from sender $connectionId (out of ${inboxCapsules.length} total received)');
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

