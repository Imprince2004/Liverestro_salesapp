import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../shared/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => getIt<ProfileRepository>());

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserEntity>>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserEntity>> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    final response = await _repository.getProfile();
    if (response.isSuccess && response.data != null) {
      state = AsyncValue.data(response.data!);
    } else {
      state = AsyncValue.error(response.message, StackTrace.current);
    }
  }

  void updateLocalProfile(UserEntity updatedUser) {
    state = AsyncValue.data(updatedUser);
  }

  Future<bool> updateProfile(UserEntity updatedUser) async {
    state = AsyncValue.data(updatedUser);
    final response = await _repository.updateProfile(updatedUser);
    if (response.isSuccess && response.data != null) {
      state = AsyncValue.data(response.data!);
      return true;
    }
    return false;
  }
}
