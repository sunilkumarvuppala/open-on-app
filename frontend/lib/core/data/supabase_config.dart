import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openon_app/core/utils/logger.dart';

/// Supabase configuration and client setup
class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Initialize Supabase client
  /// 
  /// For local development:
  ///   - URL: http://localhost:54321
  ///   - Anon key: Get from `supabase status` command
  /// 
  /// For production:
  ///   - URL: https://your-project.supabase.co
  ///   - Anon key: Get from Supabase Dashboard > Settings > API
  static Future<void> initialize({
    String? url,
    String? anonKey,
  }) async {
    if (_initialized) {
      Logger.warning('Supabase already initialized');
      return;
    }

    // Try to get from parameters first, then from .env file, then from compile-time constants
    final supabaseUrl = url ?? 
      dotenv.env['SUPABASE_URL']?.trim() ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://localhost:54321');
    final supabaseAnonKey = anonKey ?? 
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    
    Logger.info('Supabase initialization - URL: ${supabaseUrl.substring(0, supabaseUrl.length > 30 ? 30 : supabaseUrl.length)}..., AnonKey: ${supabaseAnonKey.isNotEmpty ? '${supabaseAnonKey.substring(0, 20)}...' : 'empty'}');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      final errorMsg = 'Supabase URL or anon key not provided. '
          'Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables, '
          'or pass them to initialize().';
      Logger.error(errorMsg);
      throw Exception(errorMsg);
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      Logger.info('Supabase initialized successfully');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to initialize Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseConfig.initialize() first.'
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _initialized;

  /// Get current user ID
  static String? get currentUserId => _client?.auth.currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated => _client?.auth.currentUser != null;

  /// Set Supabase session from external auth token
  /// This is used when the app uses a different auth system (e.g., FastAPI)
  /// and we need to sync the session to Supabase for RLS policies
  static Future<void> setSessionFromUserId(String userId) async {
    if (!_initialized || _client == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      // For Supabase RLS to work, we need to set the user in the session
      // Since we're using external auth, we'll use a service role token or
      // set the session manually. However, the best approach is to ensure
      // the user exists in auth.users and set the session properly.
      
      // For now, we'll log that we need to set the session
      // In production, you would:
      // 1. Create a JWT token with the user ID
      // 2. Set it using _client.auth.setSession(accessToken, refreshToken)
      // Or use Supabase service role to bypass RLS for specific operations
      
      Logger.info('Setting Supabase session for user: $userId');
      // Note: This is a placeholder - actual implementation depends on your auth setup
      // You may need to generate a JWT token or use service role for queries
    } catch (e, stackTrace) {
      Logger.error('Failed to set Supabase session', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
