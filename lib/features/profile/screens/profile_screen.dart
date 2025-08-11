import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/profile/providers/profile_provider.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

// comment: Profile feature screen with form
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authDataProvider).state.user;
    _nameCtrl = TextEditingController(
      text: (user?['name'] ?? user?['fullName'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final fullName = _nameCtrl.text.trim();
    final password = _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text;
    await ref
        .read(profileProvider.notifier)
        .updateProfile(fullName: fullName, password: password);
    final state = ref.read(profileProvider);
    if (state.error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${state.error}')));
    } else if (state.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authDataProvider).state;
    final profile = ref.watch(profileProvider);
    final user = auth.user ?? const {};
    final email = (user['email'] ?? '').toString();
    final mobile = (user['mobile'] ?? user['phone'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ФИО',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Введите ФИО' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: mobile,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Мобильный номер',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Повтор пароля',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (v) {
                      if (_passwordCtrl.text.isEmpty && (v == null || v.isEmpty)) {
                        return null;
                      }
                      if (v != _passwordCtrl.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: profile.loading ? null : _submit,
                          child: profile.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Сохранить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: auth.loading
                            ? null
                            : () => ref.read(authDataProvider).logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Выйти'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
