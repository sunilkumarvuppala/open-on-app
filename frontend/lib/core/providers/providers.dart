import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/data/connection_repository.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/color_scheme_service.dart';
import 'package:openon_app/core/utils/logger.dart';

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

// Auth state providers
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = await authRepo.getCurrentUser();
  yield user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.asData?.value != null;
});

// Capsules providers
final capsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final repo = ref.watch(capsuleRepositoryProvider);
  return repo.getCapsules(userId: userId, asSender: true);
});

final upcomingCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      final threshold = AppConstants.unlockingSoonDaysThreshold;
      return capsules
          .where((c) => c.status == CapsuleStatus.locked && c.timeUntilUnlock.inDays > threshold)
          .toList();
    },
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final unlockingSoonCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) => capsules
        .where((c) => c.status == CapsuleStatus.unlockingSoon)
        .toList(),
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final openedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) => capsules
        .where((c) => c.status == CapsuleStatus.opened)
        .toList(),
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

// Incoming capsules providers (receiver view)
final incomingCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final repo = ref.watch(capsuleRepositoryProvider);
  return repo.getCapsules(userId: userId, asSender: false);
});

final incomingLockedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingCapsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) {
      final threshold = AppConstants.unlockingSoonDaysThreshold;
      return capsules
          .where((c) => c.status == CapsuleStatus.locked && c.timeUntilUnlock.inDays > threshold)
          .toList();
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
        return capsules
            .where((c) => 
                c.status == CapsuleStatus.unlockingSoon || 
                c.status == CapsuleStatus.locked)
            .toList();
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
        return capsules
            .where((c) => c.status == CapsuleStatus.ready)
            .toList();
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
        return capsules
            .where((c) => c.status == CapsuleStatus.opened)
            .toList();
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

// Recipients provider
final recipientsProvider = FutureProvider.family<List<Recipient>, String>((ref, userId) async {
  final repo = ref.watch(recipientRepositoryProvider);
  return repo.getRecipients(userId);
});

// Draft capsule state (for multi-step creation)
class DraftCapsuleNotifier extends StateNotifier<DraftCapsule> {
  DraftCapsuleNotifier() : super(const DraftCapsule());
  
  void setRecipient(Recipient recipient) {
    state = state.copyWith(recipient: recipient);
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

// Drafts provider - in-memory storage (can be replaced with Supabase later)
class DraftsNotifier extends StateNotifier<List<Draft>> {
  DraftsNotifier() : super([]);
  
  void addDraft(Draft draft) {
    state = [...state, draft];
  }
  
  void updateDraft(String id, Draft updatedDraft) {
    state = state.map((draft) => draft.id == id ? updatedDraft : draft).toList();
  }
  
  void deleteDraft(String id) {
    state = state.where((draft) => draft.id != id).toList();
  }
  
  void clearDrafts() {
    state = [];
  }
}

final draftsProvider = StateNotifierProvider<DraftsNotifier, List<Draft>>((ref) {
  return DraftsNotifier();
});

final draftsCountProvider = Provider<int>((ref) {
  return ref.watch(draftsProvider).length;
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
  return repo.watchConnections();
});

final incomingRequestsCountProvider = Provider<int>((ref) {
  final requestsAsync = ref.watch(incomingRequestsProvider);
  return requestsAsync.asData?.value.length ?? 0;
});
