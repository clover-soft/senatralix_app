import 'package:flutter_riverpod/flutter_riverpod.dart';

// comment: Profile state model
class ProfileState {
  final bool loading;
  final String? error;
  final bool success;

  const ProfileState({this.loading = false, this.error, this.success = false});

  ProfileState copyWith({bool? loading, String? error, bool? success}) =>
      ProfileState(
        loading: loading ?? this.loading,
        error: error,
        success: success ?? this.success,
      );

  static const initial = ProfileState();
}

// comment: Profile notifier for update action
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState.initial);

  Future<void> updateProfile({required String fullName, String? password}) async {
    state = state.copyWith(loading: true, error: null, success: false);
    try {
      // TODO: integrate with real API
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(loading: false, success: true, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString(), success: false);
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
