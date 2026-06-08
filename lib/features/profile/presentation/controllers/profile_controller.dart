import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_state_provider.dart';

final profileControllerProvider = AsyncNotifierProvider<ProfileController, UserModel?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Watch the auth state so this provider invalidates and rebuilds when the user logs in/out
    ref.watch(authStateProvider);
    return _fetchUser();
  }

  Future<UserModel?> _fetchUser() async {
    final repo = ref.read(authRepositoryProvider);
    final uid = repo.currentUser?.uid;
    if (uid == null) return null;
    return await repo.getUserData(uid);
  }

  Future<void> updateField(String field, dynamic value) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    // Use copyWith to update specific fields locally
    UserModel updatedUser = currentUser;

    switch (field) {
      case 'name':
        updatedUser = currentUser.copyWith(name: value as String);
        break;
      case 'email':
        updatedUser = currentUser.copyWith(email: value as String);
        break;
      case 'phone':
        updatedUser = currentUser.copyWith(phone: value as String);
        break;
      case 'dob':
        updatedUser = currentUser.copyWith(dob: value as String);
        break;
      case 'sex':
        updatedUser = currentUser.copyWith(sex: value as String);
        break;
      case 'height':
        updatedUser = currentUser.copyWith(height: value as String);
        break;
      case 'weight':
        updatedUser = currentUser.copyWith(weight: value as String);
        break;
      case 'profileImage':
        updatedUser = currentUser.copyWith(profileImage: value as String);
        break;
    }

    state = AsyncValue.data(updatedUser);

    // Save to Firestore
    try {
      await ref.read(authRepositoryProvider).saveUserData(updatedUser);
    } catch (e) {
      // Revert on failure
      state = AsyncValue.data(currentUser);
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateUserData(UserModel updatedUser) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = AsyncValue.data(updatedUser);
    try {
      await ref.read(authRepositoryProvider).saveUserData(updatedUser);
    } catch (e) {
      state = AsyncValue.data(currentUser);
      throw Exception('Failed to update profile: $e');
    }
  }
}
