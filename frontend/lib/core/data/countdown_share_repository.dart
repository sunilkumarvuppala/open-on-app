import 'dart:convert';
import 'package:openon_app/core/data/supabase_config.dart';
import 'package:openon_app/core/data/token_storage.dart';
import 'package:openon_app/core/models/countdown_share_models.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for managing countdown shares
abstract class CountdownShareRepository {
  /// Create a countdown share for a locked letter
  Future<CreateShareResult> createShare(CreateShareRequest request);

  /// Revoke a countdown share
  Future<RevokeShareResult> revokeShare(String shareId);

  /// List active shares for the current user
  Future<List<CountdownShare>> listActiveShares({String? userId});
}

/// Supabase implementation of CountdownShareRepository
class SupabaseCountdownShareRepository implements CountdownShareRepository {
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
      'Supabase not initialized. Countdown share features require Supabase to be initialized. '
      'Please ensure SUPABASE_URL and SUPABASE_ANON_KEY environment variables are set, '
      'or call SupabaseConfig.initialize() with the required parameters.',
    );
  }

  /// Ensure Supabase session is set from FastAPI tokens
  /// This is needed for RLS policies to work (auth.uid() in RPC functions)
  Future<void> _ensureSupabaseSession() async {
    try {
      final tokenStorage = TokenStorage();
      final refreshToken = await tokenStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        Logger.warning('No refresh token available to set Supabase session');
        return;
      }

      try {
        await _supabase.auth.setSession(refreshToken);
        final sessionUserId = _supabase.auth.currentUser?.id;
        Logger.debug('Supabase session refreshed: userId=$sessionUserId');

        if (sessionUserId == null) {
          Logger.error('CRITICAL: Session set but currentUser is null!');
        }
      } catch (e) {
        Logger.warning('Failed to set Supabase session with refresh token: $e');
      }
    } catch (e) {
      Logger.warning('Failed to ensure Supabase session: $e');
    }
  }


  @override
  Future<CreateShareResult> createShare(CreateShareRequest request) async {
    try {
      if (!SupabaseConfig.isInitialized) {
        try {
          final _ = Supabase.instance.client;
        } catch (e) {
          throw Exception(
            'Supabase is not initialized. Countdown share features require Supabase to be set up.',
          );
        }
      }

      // Set Supabase session from FastAPI tokens for RLS to work
      await _ensureSupabaseSession();

      // Verify session is set correctly
      final currentUserId = _supabase.auth.currentUser?.id;
      Logger.debug('Creating share: currentUserId=$currentUserId, letterId=${request.letterId}');

      if (currentUserId == null) {
        Logger.error('Supabase session not set - auth.uid() will be NULL');
        return CreateShareResult(
          success: false,
          errorCode: 'NOT_AUTHENTICATED',
          errorMessage: 'Please sign in to create a share',
        );
      }

      // Get access token for Edge Function call
      final session = _supabase.auth.currentSession;
      if (session == null || session.accessToken.isEmpty) {
        return CreateShareResult(
          success: false,
          errorCode: 'NOT_AUTHENTICATED',
          errorMessage: 'Please sign in to create a share',
        );
      }

      // Call Edge Function with retry logic for transient failures
      Logger.debug('Calling create-countdown-share Edge Function with: ${request.toJson()}');
      Logger.debug('Access token present: ${session.accessToken.isNotEmpty}');
      
      FunctionResponse? response;
      int retryCount = 0;
      final maxRetries = AppConstants.shareCreationMaxRetries;
      Exception? lastException;
      
      while (retryCount <= maxRetries) {
        try {
          Logger.debug('Invoking Edge Function: create-countdown-share, attempt $retryCount');
          Logger.debug('Request body: ${request.toJson()}');
          response = await _supabase.functions.invoke(
            'create-countdown-share',
            body: request.toJson(),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
            },
          );
          Logger.debug('Edge Function response received: status=${response.status}');
          break; // Success, exit retry loop
        } catch (e) {
          Logger.error('Edge Function invocation error (attempt $retryCount): $e');
          Logger.error('Error type: ${e.runtimeType}');
          lastException = e is Exception ? e : Exception(e.toString());
          retryCount++;
          
          // Don't retry on certain errors
          final errorString = e.toString().toLowerCase();
          final isNonRetryableError = 
            errorString.contains('not found') ||
            errorString.contains('404') ||
            errorString.contains('not authenticated') ||
            errorString.contains('unauthorized') ||
            errorString.contains('letter_not_locked') ||
            errorString.contains('daily_limit');
          
          if (isNonRetryableError || retryCount > maxRetries) {
            // Break and handle error below
            break;
          }
          
          // Exponential backoff: wait before retrying
          final delay = AppConstants.shareCreationRetryDelay * (1 << (retryCount - 1));
          Logger.warning('Share creation attempt $retryCount failed, retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
      }
      
      // If we don't have a response, handle the error
      if (response == null) {
        Logger.error('Share creation failed: No response after $maxRetries retries');
        if (lastException != null) {
          Logger.error('Last exception: $lastException');
          // Try to extract error code from exception message
          final exceptionMessage = lastException.toString().toLowerCase();
          String? errorCode;
          String errorMessage = 'Failed to create share';
          
          if (exceptionMessage.contains('letter_not_found') || exceptionMessage.contains('404')) {
            errorCode = 'LETTER_NOT_FOUND';
            errorMessage = 'Letter not found';
          } else if (exceptionMessage.contains('not authenticated') || exceptionMessage.contains('unauthorized')) {
            errorCode = 'NOT_AUTHENTICATED';
            errorMessage = 'Please sign in to create a share';
          } else if (exceptionMessage.contains('letter_not_locked')) {
            errorCode = 'LETTER_NOT_LOCKED';
            errorMessage = 'This letter cannot be shared at this time';
          } else if (exceptionMessage.contains('letter_already_revealed')) {
            errorCode = 'LETTER_ALREADY_REVEALED';
            errorMessage = 'Anonymous sender has been revealed';
          } else if (exceptionMessage.contains('network') || exceptionMessage.contains('connection')) {
            errorCode = 'NETWORK_ERROR';
            errorMessage = 'Network error. Please check your connection';
          } else {
            errorCode = 'UNEXPECTED_ERROR';
            errorMessage = 'Unable to create share. Please try again';
          }
          
          return CreateShareResult(
            success: false,
            errorCode: errorCode,
            errorMessage: errorMessage,
          );
        }
        return CreateShareResult(
          success: false,
          errorCode: 'UNEXPECTED_ERROR',
          errorMessage: 'Failed to create share after $maxRetries retries',
        );
      }
      
      Logger.debug('Edge Function response status: ${response.status}');
      Logger.debug('Edge Function response data: ${response.data}');
      Logger.debug('Edge Function response data type: ${response.data.runtimeType}');
      
      if (response.status != 200) {
        Logger.error('Edge Function returned non-200 status: ${response.status}');
        Logger.error('Response data: ${response.data}');
        Logger.error('Response data type: ${response.data.runtimeType}');
        
        Map<String, dynamic>? errorData;
        try {
          if (response.data is Map) {
            errorData = response.data as Map<String, dynamic>;
            Logger.debug('Error data is Map: $errorData');
          } else if (response.data is String) {
            // Try to parse JSON string
            Logger.debug('Error data is String, attempting to parse: ${response.data}');
            errorData = jsonDecode(response.data as String) as Map<String, dynamic>?;
            Logger.debug('Parsed error data: $errorData');
          } else if (response.data != null) {
            Logger.warning('Unexpected error data type: ${response.data.runtimeType}');
          }
        } catch (e, stackTrace) {
          Logger.error('Failed to parse error data: $e', stackTrace: stackTrace);
          Logger.error('Raw error data that failed to parse: ${response.data}');
        }
        
        final errorCode = errorData?['error_code'] as String? ?? 
                         errorData?['errorCode'] as String? ??
                         'UNEXPECTED_ERROR';
        final errorMessage = errorData?['error_message'] as String? ?? 
                            errorData?['errorMessage'] as String? ??
                            errorData?['message'] as String? ?? 
                            (errorData?.toString() ?? 'Failed to create share');
        
        Logger.error('Edge Function error: code=$errorCode, message=$errorMessage');
        Logger.error('Full error data: $errorData');
        
        return CreateShareResult(
          success: false,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
      }

      // Parse response
      try {
        final responseData = response.data;
        if (responseData == null) {
          Logger.error('Edge Function returned null data');
          return CreateShareResult(
            success: false,
            errorCode: 'INVALID_RESPONSE',
            errorMessage: 'Edge Function returned empty response',
          );
        }
        
        final result = CreateShareResult.fromJson(responseData as Map<String, dynamic>);
        Logger.debug('Share created successfully: shareUrl=${result.shareUrl}');
        return result;
      } catch (e, stackTrace) {
        Logger.error('Error parsing Edge Function response', error: e, stackTrace: stackTrace);
        Logger.error('Response data was: ${response.data}');
        return CreateShareResult(
          success: false,
          errorCode: 'PARSE_ERROR',
          errorMessage: 'Failed to parse response from server: ${e.toString()}',
        );
      }
    } on PostgrestException catch (e) {
      Logger.error('Supabase error creating share', error: e);
      final message = e.message;
      final errorMessageText = message.isNotEmpty ? message : 'Failed to create share';

      String? errorCode;
      String errorMessage = errorMessageText;

      if (message.contains('LETTER_NOT_FOUND')) {
        errorCode = 'LETTER_NOT_FOUND';
        errorMessage = 'Letter not found';
      } else if (message.contains('LETTER_NOT_LOCKED')) {
        errorCode = 'LETTER_NOT_LOCKED';
        errorMessage = 'Letter is not locked';
      } else if (message.contains('LETTER_ALREADY_OPENED')) {
        errorCode = 'LETTER_ALREADY_OPENED';
        errorMessage = 'Letter has already been opened';
      } else if (message.contains('LETTER_ALREADY_REVEALED')) {
        errorCode = 'LETTER_ALREADY_REVEALED';
        errorMessage = 'Anonymous sender has already been revealed';
      } else if (message.contains('LETTER_DELETED')) {
        errorCode = 'LETTER_DELETED';
        errorMessage = 'Letter has been deleted';
      } else if (message.contains('NOT_AUTHORIZED')) {
        errorCode = 'NOT_AUTHORIZED';
        errorMessage = 'You do not have permission to share this letter';
      } else if (message.contains('DAILY_LIMIT_REACHED')) {
        errorCode = 'DAILY_LIMIT_REACHED';
        errorMessage = 'You have reached your daily limit of shares';
      } else if (message.contains('INVALID_SHARE_TYPE')) {
        errorCode = 'INVALID_SHARE_TYPE';
        errorMessage = 'Invalid share type';
      }

      return CreateShareResult(
        success: false,
        errorCode: errorCode ?? 'UNEXPECTED_ERROR',
        errorMessage: errorMessage,
      );
    } catch (e, stackTrace) {
      Logger.error('Error creating share', error: e, stackTrace: stackTrace);
      Logger.error('Error type: ${e.runtimeType}');
      Logger.error('Error details: $e');
      
      if (e is AppException) {
        rethrow;
      }
      
      // Provide more specific error messages
      String errorMessage = 'Failed to create share';
      if (e.toString().contains('functions') || e.toString().contains('Edge Function')) {
        errorMessage = 'Edge Function not available. Please check if create-countdown-share is deployed.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      } else {
        errorMessage = 'Failed to create share: ${e.toString()}';
      }
      
      return CreateShareResult(
        success: false,
        errorCode: 'UNEXPECTED_ERROR',
        errorMessage: errorMessage,
      );
    }
  }

  @override
  Future<RevokeShareResult> revokeShare(String shareId) async {
    try {
      // Set Supabase session for RLS
      await _ensureSupabaseSession();

      // Verify session is set
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return RevokeShareResult(
          success: false,
          errorCode: 'NOT_AUTHENTICATED',
          errorMessage: 'Please sign in to revoke a share',
        );
      }

      // Call RPC function
      final response = await _supabase.rpc(
        'rpc_revoke_countdown_share',
        params: {
          'p_share_id': shareId,
        },
      );

      if (response == null) {
        return RevokeShareResult(
          success: false,
          errorCode: 'UNEXPECTED_ERROR',
          errorMessage: 'Failed to revoke share',
        );
      }

      final result = RevokeShareResult.fromJson(response as Map<String, dynamic>);
      return result;
    } on PostgrestException catch (e) {
      Logger.error('Supabase error revoking share', error: e);
      final message = e.message;

      String? errorCode;
      String errorMessage = message.isNotEmpty ? message : 'Failed to revoke share';

      if (message.contains('SHARE_NOT_FOUND')) {
        errorCode = 'SHARE_NOT_FOUND';
        errorMessage = 'Share not found';
      } else if (message.contains('NOT_AUTHORIZED')) {
        errorCode = 'NOT_AUTHORIZED';
        errorMessage = 'You do not have permission to revoke this share';
      }

      return RevokeShareResult(
        success: false,
        errorCode: errorCode ?? 'UNEXPECTED_ERROR',
        errorMessage: errorMessage,
      );
    } catch (e, stackTrace) {
      Logger.error('Error revoking share', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      return RevokeShareResult(
        success: false,
        errorCode: 'UNEXPECTED_ERROR',
        errorMessage: 'Failed to revoke share: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CountdownShare>> listActiveShares({String? userId}) async {
    try {
      // Set Supabase session for RLS
      await _ensureSupabaseSession();

      // Query shares (RLS will filter by owner_user_id)
      final response = await _supabase
          .from('countdown_shares')
          .select()
          .eq('owner_user_id', userId ?? _supabase.auth.currentUser?.id ?? '')
          .isFilter('revoked_at', null)
          .order('created_at', ascending: false);

      final List<dynamic> sharesList = response as List<dynamic>;
      return sharesList
          .map((json) {
            try {
              return CountdownShare.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              Logger.error('Error parsing share JSON', error: e);
              return null;
            }
          })
          .whereType<CountdownShare>()
          .toList();
    } catch (e, stackTrace) {
      Logger.error('Error listing shares', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException('Failed to list shares: ${e.toString()}');
    }
  }
}

