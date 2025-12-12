import 'package:openon_app/core/data/supabase_config.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for managing connection requests and connections
abstract class ConnectionRepository {
  /// Send a connection request to another user
  Future<ConnectionRequest> sendConnectionRequest({
    required String toUserId,
    String? message,
  });

  /// Respond to a connection request (accept or decline)
  Future<ConnectionRequest> respondToRequest({
    required String requestId,
    required bool accept,
    String? declinedReason,
  });

  /// Get all pending requests (incoming and outgoing)
  Future<PendingRequests> getPendingRequests();

  /// Get all connections (mutual friends)
  Future<List<Connection>> getConnections();

  /// Search for users by username, email, or name
  /// [userId] is optional - if not provided, will try to get from Supabase auth
  Future<List<ConnectionUserProfile>> searchUsers(String query, {String? userId});

  /// Check if two users are connected
  Future<bool> areConnected(String userId1, String userId2);

  /// Block a user
  Future<void> blockUser(String userId);

  /// Unblock a user
  Future<void> unblockUser(String userId);

  /// Get real-time stream of incoming requests
  Stream<List<ConnectionRequest>> watchIncomingRequests();

  /// Get real-time stream of outgoing requests
  Stream<List<ConnectionRequest>> watchOutgoingRequests();

  /// Get real-time stream of connections
  Stream<List<Connection>> watchConnections();

  /// Get connection detail with letter statistics
  /// [connectionId] is the other user's ID in the connection
  /// [userId] is optional - if not provided, will try to get from Supabase auth
  Future<ConnectionDetail> getConnectionDetail(String connectionId, {String? userId});
}

/// Supabase implementation of ConnectionRepository
class SupabaseConnectionRepository implements ConnectionRepository {
  /// Get Supabase client - lazy initialization to avoid errors if not initialized
  SupabaseClient get _supabase {
    // First check if SupabaseConfig is initialized
    if (SupabaseConfig.isInitialized) {
      return SupabaseConfig.client;
    }
    
    // Try to check if Supabase.instance is initialized
    try {
      // Check if Supabase.instance exists and is initialized
      final instance = Supabase.instance;
      if (instance.client.auth.currentSession != null || 
          instance.client.auth.currentUser != null) {
        // Instance exists and has a session, use it
        return instance.client;
      }
    } catch (e) {
      // Supabase.instance is not initialized
    }
    
    // If we get here, Supabase is not initialized
    throw Exception(
      'Supabase not initialized. Connection features require Supabase to be initialized. '
      'Please ensure SUPABASE_URL and SUPABASE_ANON_KEY environment variables are set, '
      'or call SupabaseConfig.initialize() with the required parameters. '
      'The app should initialize Supabase at startup in main.dart.'
    );
  }

  @override
  Future<ConnectionRequest> sendConnectionRequest({
    required String toUserId,
    String? message,
  }) async {
    // Check if Supabase is initialized before attempting to use it
    if (!SupabaseConfig.isInitialized) {
      try {
        // Try to access Supabase.instance to see if it's initialized
        final _ = Supabase.instance.client;
      } catch (e) {
        throw Exception(
          'Supabase is not initialized. Connection features require Supabase to be set up. '
          'Please ensure SUPABASE_URL and SUPABASE_ANON_KEY environment variables are configured, '
          'or contact support if this issue persists.'
        );
      }
    }
    
    try {
      final response = await _supabase.rpc(
        'send_connection_request',
        params: {
          'p_to_user_id': toUserId,
          'p_message': message,
        },
      );

      if (response == null) {
        throw NetworkException('Failed to send connection request');
      }

      return ConnectionRequest.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      Logger.error('Supabase error sending request', error: e);
      
      // Handle specific error codes
      final message = e.message ?? 'Failed to send connection request';
      if (message.contains('cooldown_active')) {
        throw ValidationException('Please wait 7 days before sending another request');
      } else if (message.contains('already connected')) {
        throw ValidationException('You are already connected with this user');
      } else if (message.contains('blocked')) {
        throw ValidationException('Cannot send request: user is blocked');
      } else if (message.contains('Rate limit')) {
        throw ValidationException('Rate limit exceeded: Maximum 5 requests per day');
      } else if (message.contains('already sent')) {
        throw ValidationException('Request already sent');
      } else if (message.contains('pending request from')) {
        throw ValidationException('You have a pending request from this user');
      }
      
      throw NetworkException(message);
    } catch (e, stackTrace) {
      Logger.error('Error sending connection request', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to send connection request: ${e.toString()}');
    }
  }

  @override
  Future<ConnectionRequest> respondToRequest({
    required String requestId,
    required bool accept,
    String? declinedReason,
  }) async {
    try {
      final response = await _supabase.rpc(
        'respond_to_request',
        params: {
          'p_request_id': requestId,
          'p_action': accept ? 'accept' : 'decline',
          'p_declined_reason': declinedReason,
        },
      );

      if (response == null) {
        throw NetworkException('Failed to respond to request');
      }

      return ConnectionRequest.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      Logger.error('Supabase error responding to request', error: e);
      final message = e.message ?? 'Failed to respond to request';
      throw NetworkException(message);
    } catch (e, stackTrace) {
      Logger.error('Error responding to request', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to respond to request: ${e.toString()}');
    }
  }

  @override
  Future<PendingRequests> getPendingRequests() async {
    try {
      final response = await _supabase.rpc('get_pending_requests');

      if (response == null) {
        return const PendingRequests(incoming: [], outgoing: []);
      }

      return PendingRequests.fromJson(response as Map<String, dynamic>);
    } catch (e, stackTrace) {
      Logger.error('Error getting pending requests', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to get pending requests: ${e.toString()}');
    }
  }

  @override
  Future<List<Connection>> getConnections() async {
    try {
      final response = await _supabase.rpc('get_connections');

      if (response == null) {
        return [];
      }

      final List<dynamic> connectionsList = response as List<dynamic>;
      return connectionsList
          .map((json) => Connection.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Error getting connections', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to get connections: ${e.toString()}');
    }
  }

  @override
  Future<List<ConnectionUserProfile>> searchUsers(String query, {String? userId}) async {
    try {
      if (query.trim().isEmpty) {
        Logger.info('Search query is empty');
        return [];
      }

      // Don't convert to lowercase - let the database handle case-insensitive search
      final searchQuery = query.trim();
      
      // Get current user ID - prefer passed userId, then Supabase auth, then try to get from Supabase instance
      String? currentUserId = userId;
      
      if (currentUserId == null) {
        currentUserId = SupabaseConfig.currentUserId;
      }
      
      if (currentUserId == null) {
        try {
          currentUserId = _supabase.auth.currentUser?.id;
        } catch (e) {
          Logger.warning('Could not get user from Supabase auth', error: e);
        }
      }
      
      if (currentUserId == null) {
        Logger.error('User not authenticated for search - no user ID available');
        throw AuthenticationException('Not authenticated. Please ensure you are logged in.');
      }
      
      Logger.info('Searching with user ID: $currentUserId');
      
      // Note: Supabase RLS policies use auth.uid() which requires Supabase authentication.
      // Since this app uses FastAPI auth, we need to ensure the user is authenticated with Supabase.
      // The search_users RPC function uses SECURITY DEFINER, so it should work even without
      // Supabase auth session, but the direct query fallback requires RLS policies.
      
      // Try to set a session if we have userId but no Supabase session
      if (SupabaseConfig.currentUserId == null && currentUserId != null) {
        try {
          // Attempt to sign in with Supabase using the user ID
          // This assumes the user exists in auth.users with the same ID
          // In production, you may need to sync users between FastAPI and Supabase auth
          Logger.info('No Supabase session found, but have userId. Proceeding with query...');
        } catch (e) {
          Logger.warning('Could not set Supabase session', error: e);
        }
      }

      Logger.info('Searching users with query: "$searchQuery"');

      // Use RPC function for better search with email support
      // If RPC doesn't exist, fall back to direct query
      try {
        // Try RPC call with correct Supabase Flutter syntax
        // First try with user_id parameter (for updated function that supports external auth)
        dynamic response;
        try {
          Logger.info('Attempting RPC search_users with query: "$searchQuery", userId: $currentUserId');
          response = await _supabase.rpc(
            'search_users',
            params: {
              'search_query': searchQuery,
              'p_user_id': currentUserId,
            },
          );
        } catch (e) {
          // If that fails, try without user_id (for older function signature)
          Logger.info('RPC with user_id failed, trying without user_id parameter', error: e);
          response = await _supabase.rpc(
            'search_users',
            params: {'search_query': searchQuery},
          );
        }
        Logger.info('RPC search_users response type: ${response.runtimeType}');

        if (response != null && response is List) {
          final List<dynamic> usersList = response;
          final results = usersList
              .where((json) {
                final data = json as Map<String, dynamic>;
                final userId = data['user_id'] as String?;
                // Exclude current user from results (double check)
                return userId != null && userId != currentUserId;
              })
              .map((json) {
                final data = json as Map<String, dynamic>;
                final firstName = data['first_name'] as String? ?? '';
                final lastName = data['last_name'] as String? ?? '';
                final username = data['username'] as String? ?? '';
                
                // Build display name
                String displayName = '';
                if (firstName.isNotEmpty && lastName.isNotEmpty) {
                  displayName = '$firstName $lastName';
                } else if (firstName.isNotEmpty) {
                  displayName = firstName;
                } else if (lastName.isNotEmpty) {
                  displayName = lastName;
                } else if (username.isNotEmpty) {
                  displayName = username;
                } else {
                  displayName = 'User';
                }

                return ConnectionUserProfile(
                  userId: data['user_id'] as String,
                  displayName: displayName,
                  avatarUrl: data['avatar_url'] as String?,
                  username: username.isNotEmpty ? username : null,
                );
              })
              .toList();
          
          Logger.info('RPC search_users returned ${results.length} results');
          return results;
        } else {
          Logger.warning('RPC search_users returned null or invalid format');
        }
      } catch (rpcError) {
        // If RPC fails, log and use direct query
        Logger.warning('RPC search_users error, using direct query fallback', error: rpcError);
      }
      
      // Fallback to direct query if RPC failed or returned no results
      Logger.info('Using direct query fallback for user search');
      
      // Escape query for SQL LIKE and convert to lowercase for case-insensitive search
      final escapedQuery = searchQuery.toLowerCase().replaceAll('%', '\\%').replaceAll('_', '\\_');
      final searchPattern = '%$escapedQuery%';
      
      Logger.info('Fallback query pattern: "$searchPattern"');
      
      // Search in user_profiles by username, first_name, last_name
      // Note: Email search requires joining with auth.users which has RLS restrictions
      // Use separate filters with OR logic - need to properly format the OR query
      // The OR syntax needs to be: 'field1.ilike.value,field2.ilike.value'
      try {
        final fallbackResponse = await _supabase
            .from('user_profiles')
            .select('user_id, first_name, last_name, username, avatar_url')
            .neq('user_id', currentUserId) // Exclude current user
            .or('username.ilike.$searchPattern,first_name.ilike.$searchPattern,last_name.ilike.$searchPattern')
            .limit(20);
        
        Logger.info('Fallback query executed, checking response...');
        
        if (fallbackResponse == null) {
          Logger.warning('Direct query fallback returned null');
          return [];
        }

        final List<dynamic> usersList = fallbackResponse as List<dynamic>;
        Logger.info('Direct query returned ${usersList.length} results');
        
        return usersList.map((json) {
          final data = json as Map<String, dynamic>;
          final firstName = data['first_name'] as String? ?? '';
          final lastName = data['last_name'] as String? ?? '';
          final username = data['username'] as String? ?? '';
          
          // Build display name
          String displayName = '';
          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            displayName = '$firstName $lastName';
          } else if (firstName.isNotEmpty) {
            displayName = firstName;
          } else if (lastName.isNotEmpty) {
            displayName = lastName;
          } else if (username.isNotEmpty) {
            displayName = username;
          } else {
            displayName = 'User';
          }

          return ConnectionUserProfile(
            userId: data['user_id'] as String,
            displayName: displayName,
            avatarUrl: data['avatar_url'] as String?,
            username: username.isNotEmpty ? username : null,
          );
        }).toList();
      } catch (queryError) {
        Logger.error('Fallback query error', error: queryError);
        // Try a simpler query without OR - just search username
        try {
          Logger.info('Trying simpler query with username filter only...');
          final simpleResponse = await _supabase
              .from('user_profiles')
              .select('user_id, first_name, last_name, username, avatar_url')
              .neq('user_id', currentUserId)
              .ilike('username', searchPattern)
              .limit(20);
          
          if (simpleResponse != null) {
            Logger.info('Simple query returned ${simpleResponse.length} results');
            // Process results same as above
            final List<dynamic> usersList = simpleResponse as List<dynamic>;
            return usersList.map((json) {
              final data = json as Map<String, dynamic>;
              final firstName = data['first_name'] as String? ?? '';
              final lastName = data['last_name'] as String? ?? '';
              final username = data['username'] as String? ?? '';
              
              String displayName = '';
              if (firstName.isNotEmpty && lastName.isNotEmpty) {
                displayName = '$firstName $lastName';
              } else if (firstName.isNotEmpty) {
                displayName = firstName;
              } else if (lastName.isNotEmpty) {
                displayName = lastName;
              } else if (username.isNotEmpty) {
                displayName = username;
              } else {
                displayName = 'User';
              }

              return ConnectionUserProfile(
                userId: data['user_id'] as String,
                displayName: displayName,
                avatarUrl: data['avatar_url'] as String?,
                username: username.isNotEmpty ? username : null,
              );
            }).toList();
          }
        } catch (simpleError) {
          Logger.error('Simple query also failed', error: simpleError);
        }
        return [];
      }
    } catch (e, stackTrace) {
      Logger.error('Error searching users', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to search users: ${e.toString()}');
    }
  }

  @override
  Future<bool> areConnected(String userId1, String userId2) async {
    try {
      final user1 = userId1.compareTo(userId2) < 0 ? userId1 : userId2;
      final user2 = userId1.compareTo(userId2) < 0 ? userId2 : userId1;

      final response = await _supabase
          .from('connections')
          .select('user_id_1, user_id_2')
          .eq('user_id_1', user1)
          .eq('user_id_2', user2)
          .maybeSingle();

      return response != null;
    } catch (e, stackTrace) {
      Logger.error('Error checking connection', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<void> blockUser(String userId) async {
    try {
      final currentUserId = SupabaseConfig.currentUserId;
      if (currentUserId == null) {
        throw AuthenticationException('Not authenticated');
      }

      await _supabase.from('blocked_users').insert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
      });
    } on PostgrestException catch (e) {
      Logger.error('Supabase error blocking user', error: e);
      throw NetworkException(e.message ?? 'Failed to block user');
    } catch (e, stackTrace) {
      Logger.error('Error blocking user', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to block user: ${e.toString()}');
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    try {
      final currentUserId = SupabaseConfig.currentUserId;
      if (currentUserId == null) {
        throw AuthenticationException('Not authenticated');
      }

      await _supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', currentUserId)
          .eq('blocked_id', userId);
    } catch (e, stackTrace) {
      Logger.error('Error unblocking user', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to unblock user: ${e.toString()}');
    }
  }

  @override
  Stream<List<ConnectionRequest>> watchIncomingRequests() {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('connection_requests')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter in Dart since stream filters may not work as expected
          final filtered = data.where((json) {
            final item = json as Map<String, dynamic>;
            return item['to_user_id'] == currentUserId && 
                   item['status'] == 'pending';
          }).toList();
          
          final requests = filtered
              .map((json) => ConnectionRequest.fromJson(json as Map<String, dynamic>))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  @override
  Stream<List<ConnectionRequest>> watchOutgoingRequests() {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('connection_requests')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter in Dart since stream filters may not work as expected
          final filtered = data.where((json) {
            final item = json as Map<String, dynamic>;
            return item['from_user_id'] == currentUserId;
          }).toList();
          
          final requests = filtered
              .map((json) => ConnectionRequest.fromJson(json as Map<String, dynamic>))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  @override
  Stream<List<Connection>> watchConnections() {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('connections')
        .stream(primaryKey: ['user_id_1', 'user_id_2'])
        .asyncMap((data) async {
          // Filter in Dart since stream filters may not work as expected
          final filtered = data.where((json) {
            final item = json as Map<String, dynamic>;
            return item['user_id_1'] == currentUserId || 
                   item['user_id_2'] == currentUserId;
          }).toList();
          
          // Sort by connected_at descending
          filtered.sort((a, b) {
            final aTime = DateTime.parse((a as Map<String, dynamic>)['connected_at'] as String);
            final bTime = DateTime.parse((b as Map<String, dynamic>)['connected_at'] as String);
            return bTime.compareTo(aTime);
          });
          
          // Fetch user profiles for each connection
          final connections = <Connection>[];
          for (final json in filtered) {
            final connectionData = json as Map<String, dynamic>;
            final userId1 = connectionData['user_id_1'] as String;
            final userId2 = connectionData['user_id_2'] as String;
            final otherUserId = userId1 == currentUserId ? userId2 : userId1;

            // Fetch user profile
            try {
              final profileResponse = await _supabase
                  .from('user_profiles')
                  .select('user_id, first_name, last_name, username, avatar_url')
                  .eq('user_id', otherUserId)
                  .single();

              final profileData = profileResponse as Map<String, dynamic>;
              final firstName = profileData['first_name'] as String? ?? '';
              final lastName = profileData['last_name'] as String? ?? '';
              final username = profileData['username'] as String? ?? '';

              String displayName = '';
              if (firstName.isNotEmpty && lastName.isNotEmpty) {
                displayName = '$firstName $lastName';
              } else if (firstName.isNotEmpty) {
                displayName = firstName;
              } else if (lastName.isNotEmpty) {
                displayName = lastName;
              } else if (username.isNotEmpty) {
                displayName = username;
              } else {
                displayName = 'User';
              }

              connections.add(Connection(
                userId1: userId1,
                userId2: userId2,
                connectedAt: DateTime.parse(connectionData['connected_at'] as String),
                otherUserId: otherUserId,
                otherUserProfile: ConnectionUserProfile(
                  userId: otherUserId,
                  displayName: displayName,
                  avatarUrl: profileData['avatar_url'] as String?,
                  username: username.isNotEmpty ? username : null,
                ),
              ));
            } catch (e) {
              Logger.error('Error fetching profile for connection', error: e);
            }
          }
          return connections;
        });
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
      
      // Try to get current user ID from multiple sources
      // Prefer passed userId, then SupabaseConfig, then Supabase auth
      String? currentUserId = userId;
      
      if (currentUserId == null) {
        currentUserId = SupabaseConfig.currentUserId;
      }
      
      // Fallback: try to get from Supabase auth directly
      if (currentUserId == null) {
        try {
          currentUserId = _supabase.auth.currentUser?.id;
        } catch (e) {
          Logger.warning('Could not get user from Supabase auth', error: e);
        }
      }
      
      if (currentUserId == null) {
        Logger.error('No user ID available for connection detail');
        throw AuthenticationException('Not authenticated. Please log in to view connection details.');
      }

      // Security: Validate currentUserId format
      try {
        Validation.validateUserId(currentUserId);
      } catch (e) {
        Logger.error('Invalid user ID format', error: e);
        throw AuthenticationException('Invalid user authentication');
      }

      Logger.info('Getting connection detail for connectionId: $connectionId, currentUserId: $currentUserId');

      // Query connection directly from database instead of using getConnections() RPC
      // This works better when using FastAPI auth (auth.uid() might be null)
      final user1 = currentUserId.compareTo(connectionId) < 0 ? currentUserId : connectionId;
      final user2 = currentUserId.compareTo(connectionId) < 0 ? connectionId : currentUserId;
      
      Logger.info('Querying connection with user1: $user1, user2: $user2');
      
      // Query the connection directly
      final connectionResponse = await _supabase
          .from('connections')
          .select('user_id_1, user_id_2, connected_at')
          .eq('user_id_1', user1)
          .eq('user_id_2', user2)
          .maybeSingle();
      
      if (connectionResponse == null) {
        Logger.warning('Connection not found in database between $currentUserId and $connectionId');
        throw NetworkException('Connection not found. This user may not be in your connections list.');
      }
      
      final connectedAt = DateTime.parse(connectionResponse['connected_at'] as String);
      
      // Get the other user's profile
      final otherUserProfileResponse = await _supabase
          .from('user_profiles')
          .select('user_id, first_name, last_name, username, avatar_url')
          .eq('user_id', connectionId)
          .maybeSingle();
      
      if (otherUserProfileResponse == null) {
        Logger.warning('User profile not found for connectionId: $connectionId');
        throw NetworkException('User profile not found.');
      }
      
      final firstName = otherUserProfileResponse['first_name'] as String? ?? '';
      final lastName = otherUserProfileResponse['last_name'] as String? ?? '';
      final username = otherUserProfileResponse['username'] as String? ?? '';
      final avatarUrl = otherUserProfileResponse['avatar_url'] as String?;
      
      String displayName = '';
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        displayName = '$firstName $lastName';
      } else if (firstName.isNotEmpty) {
        displayName = firstName;
      } else if (lastName.isNotEmpty) {
        displayName = lastName;
      } else if (username.isNotEmpty) {
        displayName = username;
      } else {
        displayName = 'User';
      }
      
      final otherUserProfile = ConnectionUserProfile(
        userId: connectionId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        username: username.isNotEmpty ? username : null,
      );
      
      final connection = Connection(
        userId1: user1,
        userId2: user2,
        connectedAt: connectedAt,
        otherUserId: connectionId,
        otherUserProfile: otherUserProfile,
      );
      
      Logger.info('Found connection: ${connection.otherUserProfile.displayName}');

      // Find recipient entries for both users
      // Current user's recipient for the other user (connection-based recipients have NULL email)
      final allCurrentUserRecipients = await _supabase
          .from('recipients')
          .select('id, name, email')
          .eq('owner_id', currentUserId);

      String? currentUserRecipientId;
      // Sanitize display name for security
      final sanitizedOtherDisplayName = Validation.sanitizeString(
        connection.otherUserProfile.displayName,
      ).toLowerCase();
      for (final recipient in allCurrentUserRecipients) {
        final name = recipient['name'] as String?;
        final email = recipient['email'] as String?;
        // Match by name if email is null (connection-based recipients)
        // Also try exact match or partial match (sanitized for security)
        if (email == null && name != null) {
          final sanitizedRecipientName = Validation.sanitizeString(name).toLowerCase();
          if (sanitizedRecipientName == sanitizedOtherDisplayName ||
              sanitizedRecipientName.contains(sanitizedOtherDisplayName) ||
              sanitizedOtherDisplayName.contains(sanitizedRecipientName)) {
            currentUserRecipientId = recipient['id'] as String;
            Logger.info('Found recipient for connection: $currentUserRecipientId');
            break;
          }
        }
      }
      
      if (currentUserRecipientId == null) {
        Logger.warning('Could not find recipient for connection ${connection.otherUserId}. Recipients checked: ${allCurrentUserRecipients.length}');
      }

      // Other user's recipient for current user (to find letters received)
      final currentUserProfile = await _supabase
          .from('user_profiles')
          .select('first_name, last_name, username')
          .eq('user_id', currentUserId)
          .maybeSingle();
      
      String? currentUserName;
      if (currentUserProfile != null) {
        final firstName = currentUserProfile['first_name'] as String? ?? '';
        final lastName = currentUserProfile['last_name'] as String? ?? '';
        currentUserName = '$firstName $lastName'.trim();
        if (currentUserName.isEmpty) {
          currentUserName = currentUserProfile['username'] as String?;
        }
      }

      String? otherUserRecipientId;
      if (currentUserName != null && currentUserName.isNotEmpty) {
        final allOtherUserRecipients = await _supabase
            .from('recipients')
            .select('id, name, email')
            .eq('owner_id', connectionId);

        final currentNameLower = currentUserName.toLowerCase();
        for (final recipient in allOtherUserRecipients) {
          final name = recipient['name'] as String?;
          final email = recipient['email'] as String?;
          // Match by name if email is null (connection-based recipients)
          if (email == null && name != null) {
            final recipientName = name.toLowerCase();
            if (recipientName == currentNameLower ||
                recipientName.contains(currentNameLower) ||
                currentNameLower.contains(recipientName)) {
              otherUserRecipientId = recipient['id'] as String;
              Logger.info('Found other user recipient: $otherUserRecipientId');
              break;
            }
          }
        }
        
        if (otherUserRecipientId == null) {
          Logger.warning('Could not find other user recipient. Recipients checked: ${allOtherUserRecipients.length}');
        }
      }

      // Count letters sent (current user -> connection)
      // Query: capsules where sender_id = currentUserId AND recipient_id = currentUserRecipientId
      // Exclude soft-deleted capsules
      int lettersSent = 0;
      if (currentUserRecipientId != null) {
        try {
          final sentResponse = await _supabase
              .from('capsules')
              .select('id, deleted_at')
              .eq('sender_id', currentUserId)
              .eq('recipient_id', currentUserRecipientId)
              .isFilter('deleted_at', null); // Exclude soft-deleted
          lettersSent = sentResponse.length;
          Logger.info('Found $lettersSent letters sent to recipient $currentUserRecipientId');
        } catch (e) {
          Logger.warning('Error counting sent letters', error: e);
        }
      } else {
        Logger.warning('Cannot count sent letters: recipient not found for connection');
      }

      // Count letters received (connection -> current user)
      // Query: capsules where sender_id = connectionId AND recipient_id = otherUserRecipientId
      // The otherUserRecipientId is the recipient owned by the connection user that represents current user
      // Exclude soft-deleted capsules
      int lettersReceived = 0;
      if (otherUserRecipientId != null) {
        try {
          final receivedResponse = await _supabase
              .from('capsules')
              .select('id, deleted_at')
              .eq('sender_id', connectionId)
              .eq('recipient_id', otherUserRecipientId)
              .isFilter('deleted_at', null); // Exclude soft-deleted
          lettersReceived = receivedResponse.length;
          Logger.info('Found $lettersReceived letters received from sender $connectionId');
        } catch (e) {
          Logger.warning('Error counting received letters', error: e);
        }
      } else {
        Logger.warning('Cannot count received letters: other user recipient not found');
      }
      
      Logger.info('Final letter counts - Sent: $lettersSent, Received: $lettersReceived');

      return ConnectionDetail(
        connection: connection,
        lettersSent: lettersSent,
        lettersReceived: lettersReceived,
      );
    } on PostgrestException catch (e) {
      Logger.error('Supabase error getting connection detail', error: e);
      throw NetworkException(e.message ?? 'Failed to get connection detail');
    } catch (e, stackTrace) {
      Logger.error('Error getting connection detail', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to get connection detail: ${e.toString()}');
    }
  }
}
