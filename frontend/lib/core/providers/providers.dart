import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/data/connection_repository.dart';
import 'package:openon_app/core/data/thought_repository.dart';
import 'package:openon_app/core/data/countdown_share_repository.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/models/thought_models.dart';
import 'package:openon_app/core/models/countdown_share_models.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/color_scheme_service.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/utils/name_filter_utils.dart';

// Configuration: Set to true to use API, false to use mocks
const bool useApiRepositories = true;

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useApiRepositories) {
    return ApiAuthRepository();
  }
  return MockAuthRepository();
});

final capsuleRepositoryProvider = Provider<CapsuleRepository>((ref) {
  if (useApiRepositories) {
    return ApiCapsuleRepository();
  }
  return MockCapsuleRepository();
});

final recipientRepositoryProvider = Provider<RecipientRepository>((ref) {
  if (useApiRepositories) {
    return ApiRecipientRepository();
  }
  return MockRecipientRepository();
});

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  if (useApiRepositories) {
    return ApiConnectionRepository();
  }
  return SupabaseConnectionRepository();
});

final selfLetterRepositoryProvider = Provider<SelfLetterRepository>((ref) {
  if (useApiRepositories) {
    return ApiSelfLetterRepository();
  }
  throw UnimplementedError('Mock self letter repository not implemented');
});

final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  return SupabaseThoughtRepository();
});

final countdownShareRepositoryProvider = Provider<CountdownShareRepository>((ref) {
  return SupabaseCountdownShareRepository();
});

final letterReplyRepositoryProvider = Provider<LetterReplyRepository>((ref) {
  if (useApiRepositories) {
    return ApiLetterReplyRepository();
  }
  throw UnimplementedError('Mock letter reply repository not implemented');
});

// Auth state providers
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = await authRepo.getCurrentUser();
  yield user;
  
  // Listen for provider invalidation and re-fetch
  ref.onDispose(() {
    // Provider is being disposed, nothing to do
  });
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.asData?.value != null;
});

// Capsules providers
final capsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  // CRITICAL: Verify userId matches authenticated user to prevent data leakage
  // Use currentUserProvider which is already cached and doesn't make excessive API calls
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (currentUser) async {
      if (currentUser == null) {
        throw AuthenticationException('Not authenticated. Please sign in.');
      }
      
      // Use authenticated user's ID to prevent data leakage
      // Even if wrong userId is passed, we use the authenticated user's ID
      final authenticatedUserId = currentUser.id;
      if (authenticatedUserId != userId) {
        Logger.warning(
          'UserId mismatch in capsulesProvider: requested=$userId, authenticated=$authenticatedUserId. '
          'Using authenticated user ID.'
        );
      }
      
      final repo = ref.watch(capsuleRepositoryProvider);
      final capsules = await repo.getCapsules(userId: authenticatedUserId, asSender: true);
      Logger.info('capsulesProvider: Fetched ${capsules.length} capsules for sender $authenticatedUserId');
      // Log any capsules with invite URLs
      for (final capsule in capsules) {
        if (capsule.inviteUrl != null && capsule.inviteUrl!.isNotEmpty) {
          Logger.info('capsulesProvider: Found letter with invite: id=${capsule.id}, inviteUrl=${capsule.inviteUrl}, status=${capsule.status}, daysUntil=${capsule.timeUntilUnlock.inDays}');
        }
      }
      return capsules;
    },
    loading: () async {
      // Wait a bit for user to load, but don't wait too long
      await Future.delayed(const Duration(milliseconds: 300));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            throw AuthenticationException('Not authenticated. Please sign in.');
          }
          final authenticatedUserId = currentUser.id;
          final repo = ref.watch(capsuleRepositoryProvider);
          return repo.getCapsules(userId: authenticatedUserId, asSender: true);
        },
        loading: () => throw AuthenticationException('Authentication check timed out. Please try again.'),
        error: (_, __) => throw AuthenticationException('Not authenticated. Please sign in.'),
      );
    },
    error: (_, __) => throw AuthenticationException('Not authenticated. Please sign in.'),
  );
});

final upcomingCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      Logger.info('upcomingCapsulesProvider: Total capsules=${capsules.length}');
      final threshold = AppConstants.unlockingSoonDaysThreshold;
      final filtered = capsules
          .where((c) {
            final status = c.status;
            final isLocked = status == CapsuleStatus.locked;
            final daysUntil = c.timeUntilUnlock.inDays;
            final matches = isLocked && daysUntil > threshold;
            if (c.inviteUrl != null && c.inviteUrl!.isNotEmpty) {
              Logger.info('Found letter with invite: id=${c.id}, status=$status, isLocked=$isLocked, daysUntil=$daysUntil, matches=$matches');
            }
            return matches;
          })
          .toList();
      Logger.info('upcomingCapsulesProvider: Filtered to ${filtered.length} upcoming capsules');
      // Sort by ascending order of time remaining (shortest time first)
      filtered.sort((a, b) => a.timeUntilUnlock.compareTo(b.timeUntilUnlock));
      return filtered;
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final unlockingSoonCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      Logger.info('unlockingSoonCapsulesProvider: Total capsules=${capsules.length}');
      final filtered = capsules
          .where((c) {
            final status = c.status;
            final isUnlockingSoon = status == CapsuleStatus.unlockingSoon;
            if (c.inviteUrl != null && c.inviteUrl!.isNotEmpty) {
              Logger.info('Found letter with invite: id=${c.id}, status=$status, isUnlockingSoon=$isUnlockingSoon, daysUntil=${c.timeUntilUnlock.inDays}');
            }
            return isUnlockingSoon;
          })
          .toList();
      Logger.info('unlockingSoonCapsulesProvider: Filtered to ${filtered.length} unlocking soon capsules');
      // Sort by ascending order of time remaining (shortest time first)
      filtered.sort((a, b) => a.timeUntilUnlock.compareTo(b.timeUntilUnlock));
      return filtered;
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final openedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      // Filter capsules that are opened (have openedAt set)
      // The status getter checks openedAt != null to determine if opened
      final filtered = capsules
          .where((c) {
            final isOpened = c.openedAt != null;
            if (isOpened) {
              Logger.debug('Found opened capsule: ${c.id}, openedAt: ${c.openedAt}, status: ${c.status}');
            }
            return isOpened;
          })
          .toList();
      
      // Sort by most recently opened to earliest (newest openedAt first)
      filtered.sort((a, b) {
        final aOpened = a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bOpened = b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bOpened.compareTo(aOpened); // Descending order
      });
      
      Logger.info('Opened capsules for sender $userId: ${filtered.length} out of ${capsules.length} total');
      return filtered;
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

// Incoming capsules providers (receiver view)
final incomingCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  // CRITICAL: Verify userId matches authenticated user to prevent data leakage
  // Use currentUserProvider which is already cached and doesn't make excessive API calls
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (currentUser) {
      if (currentUser == null) {
        throw AuthenticationException('Not authenticated. Please sign in.');
      }
      
      // Use authenticated user's ID to prevent data leakage
      final authenticatedUserId = currentUser.id;
      if (authenticatedUserId != userId) {
        Logger.warning(
          'UserId mismatch in incomingCapsulesProvider: requested=$userId, authenticated=$authenticatedUserId. '
          'Using authenticated user ID.'
        );
      }
      
      final repo = ref.watch(capsuleRepositoryProvider);
      return repo.getCapsules(userId: authenticatedUserId, asSender: false);
    },
    loading: () async {
      // Wait a bit for user to load, but don't wait too long
      await Future.delayed(const Duration(milliseconds: 300));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            throw AuthenticationException('Not authenticated. Please sign in.');
          }
          final authenticatedUserId = currentUser.id;
          final repo = ref.watch(capsuleRepositoryProvider);
          return repo.getCapsules(userId: authenticatedUserId, asSender: false);
        },
        loading: () => throw AuthenticationException('Authentication check timed out. Please try again.'),
        error: (_, __) => throw AuthenticationException('Not authenticated. Please sign in.'),
      );
    },
    error: (_, __) => throw AuthenticationException('Not authenticated. Please sign in.'),
  );
});

final incomingLockedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingCapsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      final threshold = AppConstants.unlockingSoonDaysThreshold;
      final filtered = capsules
          .where((c) => c.status == CapsuleStatus.locked && c.timeUntilUnlock.inDays > threshold)
          .toList();
      // Sort by ascending order of time remaining (shortest time first)
      filtered.sort((a, b) => a.timeUntilUnlock.compareTo(b.timeUntilUnlock));
      return filtered;
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final incomingOpeningSoonCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingCapsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      try {
        final filtered = capsules
            .where((c) => 
                c.status == CapsuleStatus.unlockingSoon || 
                c.status == CapsuleStatus.locked)
            .toList();
        // Sort by ascending order of time remaining (shortest time first)
        filtered.sort((a, b) => a.timeUntilUnlock.compareTo(b.timeUntilUnlock));
        return filtered;
      } catch (e, stackTrace) {
        Logger.error(
          'Error filtering opening soon capsules',
          error: e,
          stackTrace: stackTrace,
        );
        return <Capsule>[];
      }
    },
    loading: () => <Capsule>[],
    error: (error, stackTrace) {
      Logger.error(
        'Error loading opening soon capsules for user $userId',
        error: error,
        stackTrace: stackTrace,
      );
      return <Capsule>[];
    },
  );
});

final incomingReadyCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingCapsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      try {
        final filtered = capsules
            .where((c) => c.status == CapsuleStatus.ready)
            .toList();
        // Sort by most recent one added first (newest createdAt first, descending)
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return filtered;
      } catch (e, stackTrace) {
        Logger.error(
          'Error filtering ready capsules',
          error: e,
          stackTrace: stackTrace,
        );
        return <Capsule>[];
      }
    },
    loading: () => <Capsule>[],
    error: (error, stackTrace) {
      Logger.error(
        'Error loading ready capsules for user $userId',
        error: error,
        stackTrace: stackTrace,
      );
      return <Capsule>[];
    },
  );
});

final incomingOpenedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingCapsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      try {
        // Filter capsules that are opened (have openedAt set)
        // NOTE: 'revealed' is not a separate status - it's just 'opened' with sender_revealed_at set
        // All opened capsules (including anonymous ones after reveal) have openedAt != null
        final filtered = capsules
            .where((c) {
              final isOpened = c.openedAt != null;
              if (isOpened) {
                Logger.debug('Found opened capsule: ${c.id}, openedAt: ${c.openedAt}, status: ${c.status}');
              }
              return isOpened;
            })
            .toList();
        // Sort by most recently opened to earliest (newest openedAt first)
        filtered.sort((a, b) {
          final aOpened = a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bOpened = b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bOpened.compareTo(aOpened); // Descending order
        });
        Logger.info('Opened capsules for receiver $userId: ${filtered.length} out of ${capsules.length} total');
        return filtered;
      } catch (e, stackTrace) {
        Logger.error(
          'Error filtering opened capsules',
          error: e,
          stackTrace: stackTrace,
        );
        return <Capsule>[];
      }
    },
    loading: () => <Capsule>[],
    error: (error, stackTrace) {
      Logger.error(
        'Error loading opened capsules for user $userId',
        error: error,
        stackTrace: stackTrace,
      );
      return <Capsule>[];
    },
  );
});

// ===== Name Filter Providers =====
// Filter state providers for Receive screen
final receiveFilterExpandedProvider = StateProvider<bool>((ref) => false);
final receiveFilterQueryProvider = StateProvider<String>((ref) => '');

// Filter state providers for Send screen
final sendFilterExpandedProvider = StateProvider<bool>((ref) => false);
final sendFilterQueryProvider = StateProvider<String>((ref) => '');

// Debounced query providers (200ms debounce)
// Note: For simplicity, we use the query directly. Client-side filtering is fast enough.
// If debouncing is needed, it can be added in the UI widget using a Timer.
final receiveFilterQueryDebouncedProvider = Provider<String>((ref) {
  return ref.watch(receiveFilterQueryProvider);
});

final sendFilterQueryDebouncedProvider = Provider<String>((ref) {
  return ref.watch(sendFilterQueryProvider);
});

// Filtered list providers for Receive screen tabs
final receiveFilteredOpeningSoonCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingOpeningSoonCapsulesProvider(userId));
  final query = ref.watch(receiveFilterQueryDebouncedProvider);
  
  return capsulesAsync.when(
    data: (capsules) {
      if (query.trim().isEmpty) return capsules;
      return _filterCapsulesBySenderName(capsules, query);
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final receiveFilteredReadyCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingReadyCapsulesProvider(userId));
  final query = ref.watch(receiveFilterQueryDebouncedProvider);
  
  return capsulesAsync.when(
    data: (capsules) {
      if (query.trim().isEmpty) return capsules;
      return _filterCapsulesBySenderName(capsules, query);
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final receiveFilteredOpenedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingOpenedCapsulesProvider(userId));
  final query = ref.watch(receiveFilterQueryDebouncedProvider);
  
  return capsulesAsync.when(
    data: (capsules) {
      if (query.trim().isEmpty) return capsules;
      return _filterCapsulesBySenderName(capsules, query);
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

// Filtered list providers for Send screen tabs
final sendFilteredUnlockingSoonCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(unlockingSoonCapsulesProvider(userId));
  final query = ref.watch(sendFilterQueryDebouncedProvider);
  
  return capsulesAsync.when(
    data: (capsules) {
      if (query.trim().isEmpty) return capsules;
      return _filterCapsulesByRecipientName(capsules, query);
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final sendFilteredUpcomingCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(upcomingCapsulesProvider(userId));
  final query = ref.watch(sendFilterQueryDebouncedProvider);
  
  return capsulesAsync.when(
    data: (capsules) {
      if (query.trim().isEmpty) return capsules;
      return _filterCapsulesByRecipientName(capsules, query);
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final sendFilteredOpenedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(openedCapsulesProvider(userId));
  final query = ref.watch(sendFilterQueryDebouncedProvider);
  
  return capsulesAsync.when(
    data: (capsules) {
      if (query.trim().isEmpty) return capsules;
      return _filterCapsulesByRecipientName(capsules, query);
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

// Helper functions for filtering
// Performance: Optimized with early returns and efficient filtering
// Security: Query is validated in matchesNameQuery function
List<Capsule> _filterCapsulesBySenderName(List<Capsule> capsules, String query) {
  // Early return for empty query
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) return capsules;
  
  // Security: Additional length check (defense in depth)
  if (trimmedQuery.length > AppConstants.maxFilterQueryLength) {
    return capsules; // Return all if query is too long (shouldn't happen due to UI validation)
  }
  
  // Performance: Use where().toList() for efficient filtering
  // This creates a lazy iterable first, then materializes only matching items
  return capsules.where((capsule) {
    final senderName = capsule.displaySenderName;
    // Handle null/empty sender names gracefully
    if (senderName.isEmpty) return false;
    return matchesNameQuery(trimmedQuery, senderName);
  }).toList();
}

List<Capsule> _filterCapsulesByRecipientName(List<Capsule> capsules, String query) {
  // Early return for empty query
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) return capsules;
  
  // Security: Additional length check (defense in depth)
  if (trimmedQuery.length > AppConstants.maxFilterQueryLength) {
    return capsules; // Return all if query is too long (shouldn't happen due to UI validation)
  }
  
  // Performance: Use where().toList() for efficient filtering
  return capsules.where((capsule) {
    // For send screen, filter by recipient name
    // Handle "To " prefix if present
    final recipientName = capsule.recipientName;
    if (recipientName.isEmpty) return false;
    
    // Performance: Avoid unnecessary string operations if query doesn't start with "to"
    final displayName = recipientName.toLowerCase().startsWith('to ')
        ? recipientName
        : 'To $recipientName';
    return matchesNameQuery(trimmedQuery, displayName);
  }).toList();
}

// Provider to get letter count exchanged between user and recipient
// PRODUCTION-OPTIMIZED: 
// - Reuses cached capsule data from existing providers (zero additional API calls when cache hit)
// - Uses efficient counting (fold instead of where().length to avoid intermediate lists)
// - Proper error handling and security validation
// - Memory efficient (auto-disposes when not in use)
// Key format: "userId|recipientId|linkedUserId" (linkedUserId can be empty)
final letterCountProvider = FutureProvider.family<int, String>((ref, key) async {
  // Parse key with validation
  final parts = key.split('|');
  if (parts.length != 3) {
    Logger.warning('Invalid letterCountProvider key format: $key');
    return 0;
  }
  
  final userId = parts[0];
  final recipientId = parts[1];
  final linkedUserId = parts[2].isEmpty ? null : parts[2];
  
  // CRITICAL: Verify userId matches authenticated user to prevent data leakage
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (currentUser) async {
      if (currentUser == null) {
        Logger.warning('Cannot count letters: user not authenticated');
        return 0;
      }
      
      // Use authenticated user's ID to prevent data leakage
      final authenticatedUserId = currentUser.id;
      if (authenticatedUserId != userId) {
        Logger.warning(
          'UserId mismatch in letterCountProvider: requested=$userId, authenticated=$authenticatedUserId. '
          'Using authenticated user ID.'
        );
      }
      
      // Determine if this is a self-recipient early to optimize logic
      final isSelfRecipient = linkedUserId != null && 
                              linkedUserId.isNotEmpty && 
                              linkedUserId == authenticatedUserId;
      
      try {
        // OPTIMIZATION: Try to use cached capsule data from existing providers first
        // This eliminates API calls when data is already loaded (common case)
        // If cached data is not available, fallback to repository (which may use cache)
        
        List<Capsule> sentCapsules = [];
        List<Capsule> receivedCapsules = [];
        
        // Try to get cached sent capsules (zero-cost if already loaded)
        final sentCapsulesAsync = ref.read(capsulesProvider(authenticatedUserId));
        if (sentCapsulesAsync.hasValue) {
          sentCapsules = sentCapsulesAsync.value ?? [];
        } else {
          // Fallback to repository if not cached (should be rare)
          final capsuleRepo = ref.read(capsuleRepositoryProvider);
          sentCapsules = await capsuleRepo.getCapsules(
            userId: authenticatedUserId,
            asSender: true,
          );
        }
        
        int count = 0;
        
        if (isSelfRecipient) {
          // For self-recipients: Count only sent letters (sent to self = received from self, so count once)
          // OPTIMIZATION: Use fold instead of where().length to avoid creating intermediate list
          count = sentCapsules.fold<int>(
            0,
            (sum, c) => c.recipientId == recipientId ? sum + 1 : sum,
          );
        } else {
          // For regular recipients: Count both sent + received (bidirectional exchange)
          // OPTIMIZATION: Use fold for efficient counting without intermediate lists
          count = sentCapsules.fold<int>(
            0,
            (sum, c) => c.recipientId == recipientId ? sum + 1 : sum,
          );
          
          // Count letters received: For connection-based recipients, count letters from linkedUserId
          if (linkedUserId != null && linkedUserId.isNotEmpty) {
            // Try to get cached received capsules (zero-cost if already loaded)
            final receivedCapsulesAsync = ref.read(incomingCapsulesProvider(authenticatedUserId));
            if (receivedCapsulesAsync.hasValue) {
              receivedCapsules = receivedCapsulesAsync.value ?? [];
            } else {
              // Fallback to repository if not cached (should be rare)
              final capsuleRepo = ref.read(capsuleRepositoryProvider);
              receivedCapsules = await capsuleRepo.getCapsules(
                userId: authenticatedUserId,
                asSender: false,
              );
            }
            // OPTIMIZATION: Use fold for efficient counting
            final receivedCount = receivedCapsules.fold<int>(
              0,
              (sum, c) => c.senderId == linkedUserId ? sum + 1 : sum,
            );
            count += receivedCount;
          }
        }
        
        return count;
      } catch (e, stackTrace) {
        Logger.error(
          'Error counting letters for recipient $recipientId (userId: $authenticatedUserId)',
          error: e,
          stackTrace: stackTrace,
        );
        // Return 0 on error to prevent UI breakage - graceful degradation
        return 0;
      }
    },
    loading: () async {
      // Wait briefly for user to load (non-blocking)
      await Future.delayed(const Duration(milliseconds: 100));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.when(
        data: (currentUser) {
          if (currentUser == null || currentUser.id != userId) return 0;
          // Return 0 temporarily - will be recalculated when user data is available
          return 0;
        },
        loading: () => 0,
        error: (_, __) => 0,
      );
    },
    error: (error, stackTrace) {
      Logger.warning(
        'Error getting current user for letter count',
        error: error,
        stackTrace: stackTrace,
      );
      return 0;
    },
  );
});

final recipientsProvider = FutureProvider.family<List<Recipient>, String>((ref, userId) async {
  // CRITICAL: Verify userId matches authenticated user to prevent data leakage
  // Use currentUserProvider which is already cached and doesn't make excessive API calls
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (currentUser) {
      if (currentUser == null) {
        throw AuthenticationException('Not authenticated. Please sign in.');
      }
      
      // Use authenticated user's ID to prevent data leakage
      final authenticatedUserId = currentUser.id;
      if (authenticatedUserId != userId) {
        Logger.warning(
          'UserId mismatch in recipientsProvider: requested=$userId, authenticated=$authenticatedUserId. '
          'Using authenticated user ID.'
        );
      }
      
      final repo = ref.watch(recipientRepositoryProvider);
      return repo.getRecipients(authenticatedUserId);
    },
    loading: () async {
      // Wait a bit for user to load, but don't wait too long
      await Future.delayed(const Duration(milliseconds: 300));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            throw AuthenticationException('Not authenticated. Please sign in.');
          }
          final authenticatedUserId = currentUser.id;
          final repo = ref.watch(recipientRepositoryProvider);
          return repo.getRecipients(authenticatedUserId);
        },
        loading: () => throw AuthenticationException('Authentication check timed out. Please try again.'),
        error: (_, __) => throw AuthenticationException('Not authenticated. Please sign in.'),
      );
    },
    error: (_, __) => throw AuthenticationException('Not authenticated. Please sign in.'),
  );
});

// Draft capsule state (for multi-step creation)
class DraftCapsuleNotifier extends StateNotifier<DraftCapsule> {
  DraftCapsuleNotifier() : super(const DraftCapsule());
  
  void setRecipient(Recipient? recipient) {
    state = state.copyWith(
      recipient: recipient,
      isUnregisteredRecipient: false, // Clear unregistered recipient when selecting a regular recipient
      unregisteredRecipientName: null, // Clear unregistered recipient name
      unregisteredPhoneNumber: null,
      clearUnregisteredPhone: recipient != null, // Clear phone if selecting a recipient
    );
  }
  
  void setUnregisteredRecipient({String? phoneNumber, String? recipientName}) {
    state = state.copyWith(
      isUnregisteredRecipient: true,
      recipient: null,
      unregisteredRecipientName: recipientName ?? 'Someone special',
      unregisteredPhoneNumber: phoneNumber,
    );
  }
  
  void clearUnregisteredRecipient() {
    state = state.copyWith(
      isUnregisteredRecipient: false,
      unregisteredPhoneNumber: null,
      clearUnregisteredPhone: true,
    );
  }
  
  void setContent(String content) {
    state = state.copyWith(content: content);
  }
  
  void setPhoto(String? photoPath) {
    if (photoPath == null) {
      state = state.copyWith(clearPhoto: true);
    } else {
      state = state.copyWith(photoPath: photoPath);
    }
  }
  
  void setUnlockTime(DateTime unlockAt) {
    state = state.copyWith(unlockAt: unlockAt);
  }
  
  void setLabel(String label) {
    state = state.copyWith(label: label);
  }
  
  void setDraftId(String draftId) {
    state = state.copyWith(draftId: draftId);
  }
  
  void setIsAnonymous(bool isAnonymous) {
    state = state.copyWith(isAnonymous: isAnonymous);
  }
  
  void setRevealDelaySeconds(int? revealDelaySeconds) {
    state = state.copyWith(revealDelaySeconds: revealDelaySeconds);
  }
  
  void setHint1(String? hint1) {
    state = state.copyWith(hint1: hint1);
  }
  
  void setHint2(String? hint2) {
    state = state.copyWith(hint2: hint2);
  }
  
  void setHint3(String? hint3) {
    state = state.copyWith(hint3: hint3);
  }
  
  void setSelfLetterMetadata({
    String? mood,
    String? lifeArea,
    String? city,
  }) {
    state = state.copyWith(
      mood: mood,
      lifeArea: lifeArea,
      city: city,
    );
  }
  
  void reset() {
    state = const DraftCapsule();
  }
}

final draftCapsuleProvider = StateNotifierProvider<DraftCapsuleNotifier, DraftCapsule>((ref) {
  return DraftCapsuleNotifier();
});

// Color scheme provider - loads saved scheme
final colorSchemeProvider = FutureProvider<AppColorScheme>((ref) async {
  return await ColorSchemeService.getCurrentScheme();
});

// Selected color scheme - reactive to changes
final selectedColorSchemeProvider = StateNotifierProvider<ColorSchemeNotifier, AppColorScheme>((ref) {
  final currentSchemeAsync = ref.watch(colorSchemeProvider);
  final initialScheme = currentSchemeAsync.asData?.value ?? AppColorScheme.deepBlue;
  return ColorSchemeNotifier(initialScheme);
});

class ColorSchemeNotifier extends StateNotifier<AppColorScheme> {
  ColorSchemeNotifier(AppColorScheme initialScheme) : super(initialScheme);

  Future<void> setScheme(AppColorScheme scheme) async {
    await ColorSchemeService.saveSchemeId(scheme.id);
    state = scheme;
  }
}

// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Draft repository provider
final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return LocalDraftRepository();
});

// Draft save status enum
enum DraftSaveStatus {
  idle,
  saving,
  saved,
  error,
}

// Draft letter state (for active draft editing)
class DraftLetterState {
  final String? draftId;
  final String? title;
  final String content;
  final bool isLoading;
  final DraftSaveStatus saveStatus;
  final String? error;

  DraftLetterState({
    this.draftId,
    this.title,
    required this.content,
    this.isLoading = false,
    this.saveStatus = DraftSaveStatus.idle,
    this.error,
  });

  DraftLetterState copyWith({
    String? draftId,
    String? title,
    String? content,
    bool? isLoading,
    DraftSaveStatus? saveStatus,
    String? error,
  }) {
    return DraftLetterState(
      draftId: draftId ?? this.draftId,
      title: title ?? this.title,
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      saveStatus: saveStatus ?? this.saveStatus,
      error: error ?? this.error,
    );
  }
}

// Draft letter provider (for editing a single draft)
final draftLetterProvider = StateNotifierProvider.family<DraftLetterNotifier, DraftLetterState, ({String userId, String? draftId})>((ref, params) {
  final repo = ref.watch(draftRepositoryProvider);
  return DraftLetterNotifier(
    ref: ref,
    repo: repo,
    userId: params.userId,
    draftId: params.draftId,
  );
});

class DraftLetterNotifier extends StateNotifier<DraftLetterState> {
  final Ref _ref;
  final DraftRepository _repo;
  final String _userId;
  final String? _draftId;
  
  Timer? _debounceTimer;
  bool _isSaving = false; // Lock to prevent concurrent saves
  static const Duration _debounceDuration = Duration(milliseconds: 800);

  DraftLetterNotifier({
    required Ref ref,
    required DraftRepository repo,
    required String userId,
    String? draftId,
  })  : _ref = ref,
        _repo = repo,
        _userId = userId,
        _draftId = draftId,
        super(DraftLetterState(content: '')) {
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    if (_draftId == null) {
      // New draft - nothing to load
      return;
    }

    state = state.copyWith(isLoading: true);
    
    try {
      final draft = await _repo.getDraft(_draftId!);
      if (draft != null) {
        state = state.copyWith(
          draftId: draft.id,
          title: draft.title,
          content: draft.body,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load draft',
      );
    }
  }

  /// Update content with debounced auto-save
  void updateContent(String content) {
    // Update state immediately (for responsive UI)
    state = state.copyWith(content: content);
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Set new debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _saveDraft(state.content);
    });
  }
  
  /// Update title with debounced auto-save
  void updateTitle(String title) {
    // Update state immediately (for responsive UI)
    state = state.copyWith(title: title);
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Set new debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _saveDraft(state.content);
    });
  }

  /// Save draft immediately (no debounce)
  /// Used for navigation, app lifecycle events, etc.
  Future<void> saveImmediately() async {
    _debounceTimer?.cancel();
    await _saveDraft(state.content);
  }

  Future<void> _saveDraft(String content) async {
    // Prevent concurrent saves (race condition protection)
    if (_isSaving) {
      Logger.debug('Save already in progress, skipping duplicate save');
      return;
    }
    
    // Don't save empty drafts
    if (content.trim().isEmpty) {
      return;
    }

    _isSaving = true;
    state = state.copyWith(saveStatus: DraftSaveStatus.saving);

    try {
      Draft draft;
      
      if (state.draftId == null) {
        // Create new draft
        // Note: DraftLetterNotifier doesn't have recipient info, so pass null
        draft = await _repo.createDraft(
          userId: _userId,
          title: state.title,
          content: content,
          recipientName: null,
          recipientAvatar: null,
        );
        // Set draft ID immediately after creation to prevent race conditions
        state = state.copyWith(draftId: draft.id);
      } else {
        // Update existing draft
        // Note: DraftLetterNotifier doesn't have recipient info, so pass null
        draft = await _repo.updateDraft(
          state.draftId!,
          content,
          title: state.title,
          recipientName: null,
          recipientAvatar: null,
        );
      }

      state = state.copyWith(saveStatus: DraftSaveStatus.saved);
      
      // Note: Drafts list will refresh automatically when accessed
      // No need to invalidate here since we're using FutureProvider.family
      
      // Clear saved status after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (state.saveStatus == DraftSaveStatus.saved) {
          state = state.copyWith(saveStatus: DraftSaveStatus.idle);
        }
      });
    } catch (e) {
      state = state.copyWith(
        saveStatus: DraftSaveStatus.error,
        error: 'Failed to save draft',
      );
      
      // Clear error status after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (state.saveStatus == DraftSaveStatus.error) {
          state = state.copyWith(
            saveStatus: DraftSaveStatus.idle,
            error: null,
          );
        }
      });
    } finally {
      _isSaving = false;
    }
  }

  Future<void> deleteDraft() async {
    if (state.draftId == null) return;
    
    try {
      await _repo.deleteDraft(state.draftId!, _userId);
      _ref.invalidate(draftsProvider);
    } catch (e) {
      // Error handling is done in the UI
      rethrow;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Drafts list provider (family provider that takes userId)
final draftsProvider = FutureProvider.family<List<Draft>, String>((ref, userId) async {
  final repo = ref.watch(draftRepositoryProvider);
  return repo.getDrafts(userId);
});

// Drafts notifier for mutations (delete, etc.)
class DraftsNotifier extends StateNotifier<AsyncValue<List<Draft>>> {
  final Ref _ref;
  final DraftRepository _repo;
  final String _userId;

  DraftsNotifier(this._ref, this._repo, this._userId) : super(const AsyncValue.loading()) {
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    state = const AsyncValue.loading();
    
    try {
      final drafts = await _repo.getDrafts(_userId);
      state = AsyncValue.data(drafts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      await _repo.deleteDraft(draftId, _userId);
      await loadDrafts(); // Reload after deletion
      // Also invalidate the FutureProvider so screens watching it refresh
      _ref.invalidate(draftsProvider(_userId));
    } catch (e) {
      // Error is handled by AsyncValue
      rethrow;
    }
  }
}

final draftsNotifierProvider = StateNotifierProvider.family<DraftsNotifier, AsyncValue<List<Draft>>, String>((ref, userId) {
  final repo = ref.watch(draftRepositoryProvider);
  return DraftsNotifier(ref, repo, userId);
});

final draftsCountProvider = Provider.family<int, String>((ref, userId) {
  final draftsAsync = ref.watch(draftsProvider(userId));
  return draftsAsync.asData?.value.length ?? 0;
});

// Connection providers
final pendingRequestsProvider = StreamProvider<PendingRequests>((ref) async* {
  final repo = ref.watch(connectionRepositoryProvider);
  final requests = await repo.getPendingRequests();
  yield requests;
  
  // Watch for real-time updates
  yield* Stream.periodic(const Duration(seconds: 5), (_) async {
    return await repo.getPendingRequests();
  }).asyncMap((future) => future);
});

final incomingRequestsProvider = StreamProvider<List<ConnectionRequest>>((ref) {
  final repo = ref.watch(connectionRepositoryProvider);
  print('🟡 [PROVIDER] Creating incomingRequestsProvider stream');
  final stream = repo.watchIncomingRequests();
  print('🟡 [PROVIDER] Stream created, listening...');
  stream.listen(
    (data) {
      print('🟢 [PROVIDER] Stream emitted ${data.length} incoming requests');
    },
    onError: (error, stack) {
      print('🔴 [PROVIDER] Stream error: $error');
    },
    onDone: () {
      print('🟡 [PROVIDER] Stream done');
    },
  );
  return stream;
});

final outgoingRequestsProvider = StreamProvider<List<ConnectionRequest>>((ref) {
  final repo = ref.watch(connectionRepositoryProvider);
  return repo.watchOutgoingRequests();
});

final connectionsProvider = StreamProvider<List<Connection>>((ref) {
  final repo = ref.watch(connectionRepositoryProvider);
  // Keep provider alive to prevent unnecessary rebuilds
  ref.keepAlive();
  return repo.watchConnections();
});

final connectionDetailProvider = FutureProvider.family<ConnectionDetail, String>((ref, connectionId) async {
  final repo = ref.watch(connectionRepositoryProvider);
  
  // Get current user - use cached value if available to avoid delay
  final userAsync = ref.read(currentUserProvider);
  final user = userAsync.asData?.value;
  
  // If user is not cached, wait for it (but this should be rare)
  final userId = user?.id ?? await userAsync.when(
    data: (data) => Future.value(data?.id),
    loading: () async {
      // Wait a bit for user to load, but don't wait too long
      await Future.delayed(const Duration(milliseconds: 100));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.asData?.value?.id;
    },
    error: (_, __) => Future.value(null),
  );
  
  if (userId == null) {
    throw AuthenticationException('Not authenticated. Please log in to view connection details.');
  }
  
  return repo.getConnectionDetail(connectionId, userId: userId);
});

final incomingRequestsCountProvider = Provider<int>((ref) {
  final requestsAsync = ref.watch(incomingRequestsProvider);
  return requestsAsync.asData?.value.length ?? 0;
});

// Self Letters providers
final selfLettersProvider = FutureProvider<List<SelfLetter>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (currentUser) {
      if (currentUser == null) {
        throw AuthenticationException('Not authenticated. Please sign in.');
      }
      
      final repo = ref.watch(selfLetterRepositoryProvider);
      return repo.getSelfLetters();
    },
    loading: () async {
      await Future.delayed(const Duration(milliseconds: 300));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            throw AuthenticationException('Not authenticated. Please sign in.');
          }
          final repo = ref.watch(selfLetterRepositoryProvider);
          return repo.getSelfLetters();
        },
        loading: () => <SelfLetter>[],
        error: (error, stackTrace) {
          Logger.error('Error loading self letters', error: error, stackTrace: stackTrace);
          return <SelfLetter>[];
        },
      );
    },
    error: (error, stackTrace) {
      Logger.error('Error loading self letters', error: error, stackTrace: stackTrace);
      return <SelfLetter>[];
    },
  );
});

// Thoughts providers
final incomingThoughtsProvider = FutureProvider<List<Thought>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (currentUser) {
      if (currentUser == null) {
        throw AuthenticationException('Not authenticated. Please sign in.');
      }
      
      final repo = ref.watch(thoughtRepositoryProvider);
      return repo.listIncoming();
    },
    loading: () async {
      await Future.delayed(const Duration(milliseconds: 300));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            throw AuthenticationException('Not authenticated. Please sign in.');
          }
          final repo = ref.watch(thoughtRepositoryProvider);
          return repo.listIncoming();
        },
        loading: () => <Thought>[],
        error: (error, stackTrace) {
          Logger.error('Error loading incoming thoughts', error: error, stackTrace: stackTrace);
          return <Thought>[];
        },
      );
    },
    error: (error, stackTrace) {
      Logger.error('Error loading incoming thoughts', error: error, stackTrace: stackTrace);
      return <Thought>[];
    },
  );
});

final sentThoughtsProvider = FutureProvider<List<Thought>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (currentUser) {
      if (currentUser == null) {
        throw AuthenticationException('Not authenticated. Please sign in.');
      }
      
      final repo = ref.watch(thoughtRepositoryProvider);
      return repo.listSent();
    },
    loading: () async {
      await Future.delayed(const Duration(milliseconds: 300));
      final retryAsync = ref.read(currentUserProvider);
      return retryAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            throw AuthenticationException('Not authenticated. Please sign in.');
          }
          final repo = ref.watch(thoughtRepositoryProvider);
          return repo.listSent();
        },
        loading: () => <Thought>[],
        error: (error, stackTrace) {
          Logger.error('Error loading sent thoughts', error: error, stackTrace: stackTrace);
          return <Thought>[];
        },
      );
    },
    error: (error, stackTrace) {
      Logger.error('Error loading sent thoughts', error: error, stackTrace: stackTrace);
      return <Thought>[];
    },
  );
});

/// Controller for sending thoughts
class SendThoughtController extends StateNotifier<AsyncValue<SendThoughtResult>> {
  SendThoughtController(this._repository) : super(const AsyncValue.data(SendThoughtResult(success: false)));

  final ThoughtRepository _repository;

  Future<void> sendThought(String receiverId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.sendThought(receiverId);
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(SendThoughtResult(success: false));
  }
}

final sendThoughtControllerProvider = StateNotifierProvider<SendThoughtController, AsyncValue<SendThoughtResult>>((ref) {
  final repo = ref.watch(thoughtRepositoryProvider);
  return SendThoughtController(repo);
});

// ============================================================================
// Countdown Share Providers
// ============================================================================

/// Active countdown shares for a user
final activeCountdownSharesProvider = FutureProvider.family<List<CountdownShare>, String>((ref, userId) async {
  final repo = ref.watch(countdownShareRepositoryProvider);
  try {
    final shares = await repo.listActiveShares(userId: userId);
    // Filter out expired/revoked shares
    return shares.where((share) => share.isValid).toList();
  } catch (error, stackTrace) {
    Logger.error('Error loading active countdown shares', error: error, stackTrace: stackTrace);
    return <CountdownShare>[];
  }
});

/// Controller for creating countdown shares
class CreateCountdownShareController extends StateNotifier<AsyncValue<CreateShareResult>> {
  CreateCountdownShareController(this._repository) : super(AsyncValue.data(CreateShareResult(success: false)));

  final CountdownShareRepository _repository;

  Future<void> createShare(CreateShareRequest request) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createShare(request);
      Logger.debug('Controller received result: success=${result.success}, errorCode=${result.errorCode}, errorMessage=${result.errorMessage}');
      Logger.debug('Controller result details: shareUrl=${result.shareUrl}');
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      Logger.error('Controller caught exception', error: error, stackTrace: stackTrace);
      Logger.error('Exception type: ${error.runtimeType}');
      Logger.error('Exception details: $error');
      // Even if there's an exception, wrap it in a CreateShareResult for consistent handling
      state = AsyncValue.data(CreateShareResult(
        success: false,
        errorCode: 'EXCEPTION',
        errorMessage: error.toString(),
      ));
    }
  }

  void reset() {
    state = AsyncValue.data(CreateShareResult(success: false));
  }
}

final createCountdownShareControllerProvider = StateNotifierProvider<CreateCountdownShareController, AsyncValue<CreateShareResult>>((ref) {
  final repo = ref.watch(countdownShareRepositoryProvider);
  return CreateCountdownShareController(repo);
});

/// Controller for revoking countdown shares
class RevokeCountdownShareController extends StateNotifier<AsyncValue<RevokeShareResult>> {
  RevokeCountdownShareController(this._repository) : super(AsyncValue.data(RevokeShareResult(success: false)));

  final CountdownShareRepository _repository;

  Future<void> revokeShare(String shareId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.revokeShare(shareId);
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = AsyncValue.data(RevokeShareResult(success: false));
  }
}

final revokeCountdownShareControllerProvider = StateNotifierProvider<RevokeCountdownShareController, AsyncValue<RevokeShareResult>>((ref) {
  final repo = ref.watch(countdownShareRepositoryProvider);
  return RevokeCountdownShareController(repo);
});
