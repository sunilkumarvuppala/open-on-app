import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/color_scheme_service.dart';

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
    data: (capsules) => capsules
        .where((c) => c.status == CapsuleStatus.unlockingSoon)
        .toList(),
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
  );
});

final incomingOpenedCapsulesProvider = FutureProvider.family<List<Capsule>, String>((ref, userId) async {
  final capsulesAsync = ref.watch(incomingCapsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) => capsules
        .where((c) => c.status == CapsuleStatus.opened)
        .toList(),
    loading: () => <Capsule>[],
    error: (_, __) => <Capsule>[],
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
  final initialScheme = currentSchemeAsync.asData?.value ?? AppColorScheme.galaxyAurora;
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
