import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/services/profile_service.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

/// Данные профиля пользователя
@immutable
class ProfileDataState {
  final bool loading;
  final Map<String, dynamic>? profile; // {id, email, username, phone}
  final String? error;

  const ProfileDataState({
    this.loading = false,
    this.profile,
    this.error,
  });

  ProfileDataState copyWith({
    bool? loading,
    Map<String, dynamic>? profile,
    String? error,
  }) => ProfileDataState(
        loading: loading ?? this.loading,
        profile: profile ?? this.profile,
        error: error,
      );

  static const initial = ProfileDataState();
}

/// Провайдер данных профиля (загрузка/обновление/смена пароля)
class ProfileDataProvider with ChangeNotifier {
  ProfileDataProvider({ProfileService? service})
      : _service = service ?? ProfileService();

  final ProfileService _service;
  ProfileDataState _state = ProfileDataState.initial;
  ProfileDataState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();
    try {
      final me = await _service.getProfile();
      _state = _state.copyWith(loading: false, profile: me, error: null);
    } catch (e) {
      _state = _state.copyWith(loading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<bool> updateName(String username, WidgetRef ref) async {
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();
    try {
      final me = await _service.updateName(username: username);
      _state = _state.copyWith(loading: false, profile: me, error: null);
      // опционально синхронизируем auth /me
      // ignore: discarded_futures
      ref.read(authDataProvider).refresh();
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(loading: false, error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();
    try {
      await _service.changePassword(oldPassword: oldPassword, newPassword: newPassword);
      _state = _state.copyWith(loading: false, error: null);
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(loading: false, error: e.toString());
      notifyListeners();
      return false;
    }
  }
}

final profileDataProvider = ChangeNotifierProvider<ProfileDataProvider>((ref) {
  final p = ProfileDataProvider();
  // ignore: discarded_futures
  p.load();
  return p;
});
