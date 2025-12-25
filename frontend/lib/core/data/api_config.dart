import 'dart:io';
import 'package:flutter/foundation.dart';

/// API configuration and endpoints
class ApiConfig {
  ApiConfig._();

  // Base URL - automatically detects platform
  // For local development:
  //   - iOS Simulator / Desktop: http://localhost:8000
  //   - Android Emulator: http://10.0.2.2:8000
  //   - Physical Device: Use your computer's IP address (e.g., http://192.168.1.100:8000)
  // For production: https://your-api-domain.com
  static String get baseUrl {
    // Check if base URL is provided via environment variable
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Auto-detect for Android emulator
    if (!kIsWeb && Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:8000';
    }
    
    // Default for iOS, Desktop, Web
    return 'http://localhost:8000';
  }

  // API endpoints
  static const String authSignup = '/auth/signup';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static String checkUsernameAvailability(String username) {
    final encodedUsername = Uri.encodeComponent(username);
    return '/auth/username/check?username=$encodedUsername';
  }
  static String searchUsers(String query, {int limit = 10}) {
    final encodedQuery = Uri.encodeComponent(query);
    return '/auth/users/search?query=$encodedQuery&limit=$limit';
  }

  static const String capsules = '/capsules';
  static String capsuleById(String id) => '/capsules/$id';
  static String openCapsule(String id) => '/capsules/$id/open';

  static const String recipients = '/recipients';
  static String recipientById(String id) => '/recipients/$id';

  // Connection endpoints
  static const String connectionRequests = '/connections/requests';
  static String connectionRequestById(String id) => '/connections/requests/$id';
  static const String incomingRequests = '/connections/requests/incoming';
  static const String outgoingRequests = '/connections/requests/outgoing';
  static const String connections = '/connections';

  // Self letter endpoints
  static const String selfLetters = '/self-letters';
  static String selfLetterById(String id) => '/self-letters/$id';
  static String openSelfLetter(String id) => '/self-letters/$id/open';
  static String submitReflection(String id) => '/self-letters/$id/reflection';

  // Letter reply endpoints
  static String letterReplyByLetterId(String letterId) => '/letter-replies/letters/$letterId';
  static String createLetterReply(String letterId) => '/letter-replies/letters/$letterId';
  static String markReceiverAnimationSeen(String letterId) => '/letter-replies/letters/$letterId/mark-receiver-animation-seen';
  static String markSenderAnimationSeen(String letterId) => '/letter-replies/letters/$letterId/mark-sender-animation-seen';

  // Helper method to build full URL
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}

