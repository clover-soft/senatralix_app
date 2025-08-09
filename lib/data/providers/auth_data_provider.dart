import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/services/auth_service.dart';

/// Auth state holder
class AuthState {
  final bool ready; // finished initial check
  final bool loading;
  final bool loggedIn;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    required this.ready,
    required this.loading,
    required this.loggedIn,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? ready,
    bool? loading,
    bool? loggedIn,
    Map<String, dynamic>? user,
    String? error,
  }) => AuthState(
        ready: ready ?? this.ready,
        loading: loading ?? this.loading,
        loggedIn: loggedIn ?? this.loggedIn,
        user: user ?? this.user,
        error: error,
      );

  static const initial = AuthState(ready: false, loading: false, loggedIn: false);
}

/// Provides authentication operations and state.
class AuthDataProvider with ChangeNotifier {
  final AuthService _service;

  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  AuthDataProvider({AuthService? service}) : _service = service ?? AuthService();

  /// Initialize: check current session via /me
  Future<void> init() async {
    try {
      final me = await _service.me();
      _state = _state.copyWith(ready: true, loggedIn: true, user: me, error: null);
    } catch (e) {
      _state = _state.copyWith(ready: true, loggedIn: false, user: null, error: null);
    }
    notifyListeners();
  }

  /// Explicit refresh of /me
  Future<void> refresh() => init();

  /// Email/password login
  Future<bool> login({required String email, required String password}) async {
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();
    try {
      final user = await _service.login(email: email, password: password);
      _state = _state.copyWith(loading: false, loggedIn: true, user: user, error: null);
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(loading: false, loggedIn: false, error: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Logout current session
  Future<void> logout() async {
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();
    try {
      await _service.logout();
    } catch (_) {}
    _state = _state.copyWith(loading: false, loggedIn: false, user: null);
    notifyListeners();
  }
}

/// Riverpod provider
final authDataProvider = ChangeNotifierProvider<AuthDataProvider>((ref) {
  final p = AuthDataProvider();
  // kick off initial /me check
  // ignore: discarded_futures
  p.init();
  return p;
});

