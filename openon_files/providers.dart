import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/data/repositories.dart';
import 'package:openon_app/core/models/models.dart';

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final capsuleRepositoryProvider = Provider<CapsuleRepository>((ref) {
  return MockCapsuleRepository();
});

final recipientRepositoryProvider = Provider<RecipientRepository>((ref) {
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

final upcomingCapsulesProvider = Provider.family<List<Capsule>, String>((ref, userId) {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) => capsules
        .where((c) => c.status == CapsuleStatus.locked && c.timeUntilUnlock.inDays > 7)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final unlockingSoonCapsulesProvider = Provider.family<List<Capsule>, String>((ref, userId) {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) => capsules
        .where((c) => c.status == CapsuleStatus.unlockingSoon)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final openedCapsulesProvider = Provider.family<List<Capsule>, String>((ref, userId) {
  final capsulesAsync = ref.watch(capsulesProvider(userId));
  
  return capsulesAsync.when(
    data: (capsules) => capsules
        .where((c) => c.status == CapsuleStatus.opened)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
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

// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);
