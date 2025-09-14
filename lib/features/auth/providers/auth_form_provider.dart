import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

// comment: holds email/password form state
class AuthFormState {
  final String email;
  final String password;
  final bool submitting;
  final String? error;

  const AuthFormState({
    this.email = '',
    this.password = '',
    this.submitting = false,
    this.error,
  });

  AuthFormState copyWith({
    String? email,
    String? password,
    bool? submitting,
    String? error,
  }) => AuthFormState(
    email: email ?? this.email,
    password: password ?? this.password,
    submitting: submitting ?? this.submitting,
    error: error,
  );
}

// comment: StateNotifier to manage auth form and submit via AuthDataProvider
class AuthFormController extends StateNotifier<AuthFormState> {
  AuthFormController(this.ref) : super(const AuthFormState());
  final Ref ref;

  void setEmail(String v) => state = state.copyWith(email: v, error: null);
  void setPassword(String v) =>
      state = state.copyWith(password: v, error: null);

  Future<bool> submit() async {
    final email = state.email.trim();
    final password = state.password;
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Email and password are required');
      return false;
    }
    state = state.copyWith(submitting: true, error: null);
    try {
      final ok = await ref
          .read(authDataProvider)
          .login(email: email, password: password);
      state = state.copyWith(submitting: false);
      if (!ok) {
        state = state.copyWith(error: ref.read(authDataProvider).state.error);
      }
      return ok;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      return false;
    }
  }
}

final authFormProvider =
    StateNotifierProvider<AuthFormController, AuthFormState>(
      (ref) => AuthFormController(ref),
    );
