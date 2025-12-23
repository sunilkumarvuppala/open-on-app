import 'package:openon_app/core/data/supabase_config.dart';
import 'package:openon_app/core/data/token_storage.dart';
import 'package:openon_app/core/models/thought_models.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

/// Repository for managing thoughts
abstract class ThoughtRepository {
  /// Send a thought to a receiver
  /// Returns SendThoughtResult with success status and error codes
  Future<SendThoughtResult> sendThought(String receiverId);

  /// List incoming thoughts (thoughts received by current user)
  /// [cursor] is the created_at timestamp of the last thought for pagination
  /// [limit] is the maximum number of thoughts to return (uses AppConstants.thoughtsDefaultLimit)
  Future<List<Thought>> listIncoming({
    DateTime? cursor,
    int? limit,
  });

  /// List sent thoughts (thoughts sent by current user)
  /// [cursor] is the created_at timestamp of the last thought for pagination
  /// [limit] is the maximum number of thoughts to return (uses AppConstants.thoughtsDefaultLimit)
  Future<List<Thought>> listSent({
    DateTime? cursor,
    int? limit,
  });
}

/// Supabase implementation of ThoughtRepository
class SupabaseThoughtRepository implements ThoughtRepository {
  /// Get Supabase client
  SupabaseClient get _supabase {
    if (SupabaseConfig.isInitialized) {
      return SupabaseConfig.client;
    }

    try {
      final instance = Supabase.instance;
      if (instance.client.auth.currentSession != null ||
          instance.client.auth.currentUser != null) {
        return instance.client;
      }
    } catch (e) {
      // Supabase.instance is not initialized
    }

    throw Exception(
      'Supabase not initialized. Thought features require Supabase to be initialized. '
      'Please ensure SUPABASE_URL and SUPABASE_ANON_KEY environment variables are set, '
      'or call SupabaseConfig.initialize() with the required parameters.',
    );
  }

  /// Get client source identifier (uses constants, no hardcoded strings)
  String? get _clientSource {
    if (Platform.isIOS) return AppConstants.clientSourceIOS;
    if (Platform.isAndroid) return AppConstants.clientSourceAndroid;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return AppConstants.clientSourceWeb;
    }
    return null;
  }

  /// Ensure Supabase session is set from FastAPI tokens
  /// This is needed for RLS policies to work (auth.uid() in RPC functions)
  /// Always refreshes session to ensure it matches current logged-in user
  Future<void> _ensureSupabaseSession() async {
    try {
      // Get tokens from storage (FastAPI returns Supabase JWT tokens)
      final tokenStorage = TokenStorage();
      final accessToken = await tokenStorage.getAccessToken();
      final refreshToken = await tokenStorage.getRefreshToken();
      
      if (refreshToken == null || refreshToken.isEmpty) {
        Logger.warning('No refresh token available to set Supabase session');
        return;
      }

      // Always refresh session to ensure it matches current user
      // Don't rely on cached session - tokens might have changed
      try {
        // Supabase Flutter setSession takes refresh token string
        await _supabase.auth.setSession(refreshToken);
        final sessionUserId = _supabase.auth.currentUser?.id;
        Logger.debug('Supabase session refreshed: userId=$sessionUserId');
        
        // Verify session was set correctly
        if (sessionUserId == null) {
          Logger.error('CRITICAL: Session set but currentUser is null!');
        }
      } catch (e) {
        Logger.warning('Failed to set Supabase session with refresh token: $e');
        // Try with access token as fallback (though this might not work)
        if (accessToken != null && accessToken.isNotEmpty) {
          try {
            await _supabase.auth.setSession(accessToken);
            Logger.debug('Supabase session set from access token (fallback)');
          } catch (e2) {
            Logger.warning('Failed to set Supabase session with access token: $e2');
          }
        }
      }
    } catch (e) {
      Logger.warning('Failed to ensure Supabase session: $e');
      // Continue anyway - might work if session is already set
    }
  }

  @override
  Future<SendThoughtResult> sendThought(String receiverId) async {
    try {
      if (!SupabaseConfig.isInitialized) {
        try {
          final _ = Supabase.instance.client;
        } catch (e) {
          throw Exception(
            'Supabase is not initialized. Thought features require Supabase to be set up.',
          );
        }
      }

      // Set Supabase session from FastAPI tokens for RLS to work
      await _ensureSupabaseSession();
      
      // Verify session is set correctly (debug)
      final currentUserId = _supabase.auth.currentUser?.id;
      Logger.debug('Sending thought: currentUserId=$currentUserId, receiverId=$receiverId');
      
      if (currentUserId == null) {
        Logger.error('Supabase session not set - auth.uid() will be NULL');
        return const SendThoughtResult(
          success: false,
          errorCode: 'NOT_AUTHENTICATED',
          errorMessage: 'Please sign in to send thoughts',
        );
      }
      
      // CRITICAL: Validate that currentUserId != receiverId
      // If they match, the session is wrong or receiverId is wrong
      if (currentUserId == receiverId) {
        Logger.error('CRITICAL: Session user ID matches receiver ID! This should never happen. currentUserId=$currentUserId, receiverId=$receiverId');
        return SendThoughtResult(
          success: false,
          errorCode: 'INVALID_RECEIVER',
          errorMessage: 'Cannot send thought to yourself. Please check your connection and try again.',
        );
      }

      final response = await _supabase.rpc(
        'rpc_send_thought',
        params: {
          'p_receiver_id': receiverId,
          'p_client_source': _clientSource,
        },
      );

      if (response == null) {
        return const SendThoughtResult(
          success: false,
          errorCode: 'UNEXPECTED_ERROR',
          errorMessage: 'Failed to send thought',
        );
      }

      final result = response as Map<String, dynamic>;
      final thoughtId = result['thought_id'] as String?;

      if (thoughtId != null) {
        return SendThoughtResult(
          success: true,
          thoughtId: thoughtId,
        );
      }

      return const SendThoughtResult(
        success: false,
        errorCode: 'UNEXPECTED_ERROR',
        errorMessage: 'Thought sent but no ID returned',
      );
    } on PostgrestException catch (e) {
      Logger.error('Supabase error sending thought', error: e);
      final message = e.message;
      final errorMessageText = message.isNotEmpty ? message : 'Failed to send thought';
      
      // Parse error code from message
      String? errorCode;
      String errorMessage = errorMessageText;
      
      if (message.contains('THOUGHT_ALREADY_SENT_TODAY')) {
        errorCode = 'THOUGHT_ALREADY_SENT_TODAY';
        errorMessage = 'You already sent a thought to this person today';
      } else if (message.contains('DAILY_LIMIT_REACHED')) {
        errorCode = 'DAILY_LIMIT_REACHED';
        errorMessage = 'You have reached your daily limit of thoughts';
      } else if (message.contains('NOT_CONNECTED')) {
        errorCode = 'NOT_CONNECTED';
        errorMessage = 'You must be connected to send a thought';
      } else if (message.contains('BLOCKED')) {
        errorCode = 'BLOCKED';
        errorMessage = 'Cannot send thought to this user';
      } else if (message.contains('INVALID_RECEIVER')) {
        errorCode = 'INVALID_RECEIVER';
        errorMessage = 'Invalid receiver';
      }

      return SendThoughtResult(
        success: false,
        errorCode: errorCode ?? 'UNEXPECTED_ERROR',
        errorMessage: errorMessage,
      );
    } catch (e, stackTrace) {
      Logger.error('Error sending thought', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      return SendThoughtResult(
        success: false,
        errorCode: 'UNEXPECTED_ERROR',
        errorMessage: 'Failed to send thought: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Thought>> listIncoming({
    DateTime? cursor,
    int? limit,
  }) async {
    try {
      // Set Supabase session for RLS
      await _ensureSupabaseSession();
      
      // Use configured limit or default from constants
      final effectiveLimit = limit ?? AppConstants.thoughtsDefaultLimit;
      final clampedLimit = effectiveLimit.clamp(
        AppConstants.thoughtsMinLimit,
        AppConstants.thoughtsMaxLimit,
      );

      final response = await _supabase.rpc(
        'rpc_list_incoming_thoughts',
        params: {
          'p_cursor_created_at': cursor?.toIso8601String(),
          'p_limit': clampedLimit,
        },
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> thoughtsList = response as List<dynamic>;
      return thoughtsList
          .map((json) {
            try {
              // Parse the JSON response from RPC
              final thoughtData = json as Map<String, dynamic>;
              
              // Convert display_date (date string) to DateTime
              final displayDateStr = thoughtData['display_date'] as String?;
              final displayDate = displayDateStr != null
                  ? DateTime.parse(displayDateStr)
                  : DateTime.parse(thoughtData['created_at'] as String);

              // Parse created_at for sorting
              final createdAt = DateTime.parse(thoughtData['created_at'] as String);

              return Thought(
                id: thoughtData['id'] as String,
                senderId: thoughtData['sender_id'] as String,
                receiverId: '', // Not provided in incoming thoughts
                displayDate: displayDate,
                createdAt: createdAt,
                senderName: thoughtData['sender_name'] as String?,
                senderAvatarUrl: thoughtData['sender_avatar_url'] as String?,
                senderUsername: thoughtData['sender_username'] as String?,
              );
            } catch (e) {
              Logger.error('Error parsing thought JSON', error: e);
              return null;
            }
          })
          .whereType<Thought>()
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Error listing incoming thoughts', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to list incoming thoughts: ${e.toString()}');
    }
  }

  @override
  Future<List<Thought>> listSent({
    DateTime? cursor,
    int? limit,
  }) async {
    try {
      // Set Supabase session for RLS
      await _ensureSupabaseSession();
      
      // Use configured limit or default from constants
      final effectiveLimit = limit ?? AppConstants.thoughtsDefaultLimit;
      final clampedLimit = effectiveLimit.clamp(
        AppConstants.thoughtsMinLimit,
        AppConstants.thoughtsMaxLimit,
      );

      final response = await _supabase.rpc(
        'rpc_list_sent_thoughts',
        params: {
          'p_cursor_created_at': cursor?.toIso8601String(),
          'p_limit': clampedLimit,
        },
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> thoughtsList = response as List<dynamic>;
      return thoughtsList
          .map((json) {
            try {
              // Parse the JSON response from RPC
              final thoughtData = json as Map<String, dynamic>;
              
              // Convert display_date (date string) to DateTime
              final displayDateStr = thoughtData['display_date'] as String?;
              final displayDate = displayDateStr != null
                  ? DateTime.parse(displayDateStr)
                  : DateTime.parse(thoughtData['created_at'] as String);

              // Parse created_at for sorting
              final createdAt = DateTime.parse(thoughtData['created_at'] as String);

              return Thought(
                id: thoughtData['id'] as String,
                senderId: '', // Not provided in sent thoughts (we are sender)
                receiverId: thoughtData['receiver_id'] as String,
                displayDate: displayDate,
                createdAt: createdAt,
                receiverName: thoughtData['receiver_name'] as String?,
                receiverAvatarUrl: thoughtData['receiver_avatar_url'] as String?,
                receiverUsername: thoughtData['receiver_username'] as String?,
              );
            } catch (e) {
              Logger.error('Error parsing thought JSON', error: e);
              return null;
            }
          })
          .whereType<Thought>()
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Error listing sent thoughts', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to list sent thoughts: ${e.toString()}');
    }
  }
}

