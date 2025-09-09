import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/providers/profile_data_provider.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';
import 'package:sentralix_app/features/profile/widgets/theme_section.dart';

// comment: Profile feature screen with form
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // comment: Separate forms
  final _nameFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileDataProvider).state.profile;
    _nameCtrl = TextEditingController(
      text: (profile?['username'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!_nameFormKey.currentState!.validate()) return;
    final ok = await ref.read(profileDataProvider).updateName(_nameCtrl.text.trim(), ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'ФИО обновлено' : 'Не удалось обновить ФИО')),
    );
  }

  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    final ok = await ref.read(profileDataProvider).changePassword(
          oldPassword: _oldPassCtrl.text,
          newPassword: _newPassCtrl.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Пароль изменён' : 'Не удалось изменить пароль')),
    );
    if (ok) {
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authDataProvider).state;
    final profileState = ref.watch(profileDataProvider).state;
    final me = profileState.profile ?? const {};
    final email = (me['email'] ?? '').toString();
    final mobile = (me['phone'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // comment: Display-only fields
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
                const SizedBox(height: 20),

                // comment: Form 1 — Update Name
                Text('Смена ФИО', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Form(
                  key: _nameFormKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ФИО',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Введите ФИО'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: profileState.loading ? null : _saveName,
                        child: profileState.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Сохранить'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Переключатель темы приложения
                const ThemeSection(),

                const SizedBox(height: 28),

                // comment: Form 2 — Change Password
                Text('Смена пароля', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Form(
                  key: _passFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _oldPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Текущий пароль',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Введите текущий пароль' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Новый пароль',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Введите новый пароль' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Повторите новый пароль',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        validator: (v) {
                          if (v != _newPassCtrl.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: profileState.loading ? null : _changePassword,
                          child: profileState.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Изменить пароль'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // comment: Logout button
                OutlinedButton.icon(
                  onPressed: auth.loading ? null : () => ref.read(authDataProvider).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
