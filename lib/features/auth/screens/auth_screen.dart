import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/auth/providers/auth_form_provider.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(authFormProvider);
    final auth = ref.watch(authDataProvider).state;

    return Scaffold(
      appBar: AppBar(title: const Text('Вход в sentralix')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) =>
                      ref.read(authFormProvider.notifier).setEmail(v),
                ),
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onChanged: (v) =>
                      ref.read(authFormProvider.notifier).setPassword(v),
                ),
                const SizedBox(height: 16),
                if (form.error != null)
                  Text(form.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: form.submitting
                        ? null
                        : () async {
                            final ok = await ref
                                .read(authFormProvider.notifier)
                                .submit();
                            if (ok) {
                              // After successful login, go to home. Router redirect can handle 'from' if needed.
                              // ignore: use_build_context_synchronously
                              context.go('/');
                            }
                          },
                    child: form.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Войти'),
                  ),
                ),
                const SizedBox(height: 12),
                if (auth.loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
