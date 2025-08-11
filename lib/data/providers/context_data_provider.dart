import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/services/context_service.dart';
import 'package:sentralix_app/data/providers/auth_data_provider.dart';

@immutable
class ContextState {
  final bool loading;
  final Map<String, dynamic>? subscription; // raw subscription
  final List<dynamic>? domains; // raw domains
  final List<Map<String, dynamic>>
  menu; // parsed from subscription.settings.menu
  final String? error;

  const ContextState({
    this.loading = false,
    this.subscription,
    this.domains,
    this.menu = const [],
    this.error,
  });

  ContextState copyWith({
    bool? loading,
    Map<String, dynamic>? subscription,
    List<dynamic>? domains,
    List<Map<String, dynamic>>? menu,
    String? error,
  }) => ContextState(
    loading: loading ?? this.loading,
    subscription: subscription ?? this.subscription,
    domains: domains ?? this.domains,
    menu: menu ?? this.menu,
    error: error,
  );

  static const initial = ContextState();
}

class ContextDataProvider with ChangeNotifier {
  ContextDataProvider({ContextService? service})
    : _service = service ?? ContextService();

  final ContextService _service;
  ContextState _state = ContextState.initial;
  ContextState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();
    try {
      final ctx = await _service.getContext();
      final sub = ctx['subscription'] as Map<String, dynamic>?;
      final dom = ctx['domains'] as List<dynamic>?;

      // parse subscription.settings JSON string
      final settings = _service.parseSubscriptionSettings(sub);
      final rawMenu = settings['menu'];
      List<Map<String, dynamic>> menu = const [];
      if (rawMenu is List) {
        menu =
            rawMenu
                .whereType<Map>()
                .map(
                  (e) => {
                    'key': (e['key'] ?? '').toString(),
                    'order': int.tryParse((e['order'] ?? 0).toString()) ?? 0,
                  },
                )
                .where((e) => (e['key'] as String).isNotEmpty)
                .toList()
              ..sort(
                (a, b) => (a['order'] as int).compareTo(b['order'] as int),
              );
      }

      _state = _state.copyWith(
        loading: false,
        subscription: sub,
        domains: dom,
        menu: menu,
        error: null,
      );
      // 🙂 Debug: print loaded context summary
      // ignore: avoid_print
      print('[CTX] loaded: subscription='
          '${sub != null ? sub['name'] : 'null'}; menuKeys=${menu.map((e) => e['key']).toList()}');
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        loading: false,
        error: e.toString(),
        menu: const [],
      );
      notifyListeners();
    }
  }

  void clear() {
    _state = ContextState.initial;
    notifyListeners();
  }
}

final contextDataProvider = ChangeNotifierProvider<ContextDataProvider>((ref) {
  final p = ContextDataProvider();

  // первичная загрузка, если уже авторизованы
  final auth = ref.read(authDataProvider).state;
  if (auth.loggedIn) {
    // ignore: discarded_futures
    p.load();
  }

  // слушаем изменения состояния авторизации (включая смену пользователя)
  ref.listen<AuthState>(authDataProvider.select((prov) => prov.state), (
    prev,
    next,
  ) {
    final wasIn = prev?.loggedIn ?? false;
    final nowIn = next.loggedIn;

    final prevUser = prev?.user;
    final nextUser = next.user;
    bool identityChanged = false;
    if (wasIn && nowIn) {
      final prevId = prevUser?['id']?.toString();
      final nextId = nextUser?['id']?.toString();
      final prevEmail = prevUser?['email']?.toString();
      final nextEmail = nextUser?['email']?.toString();
      identityChanged = (prevId != nextId) || (prevEmail != nextEmail);
    }

    if (!wasIn && nowIn) {
      // login
      // ignore: discarded_futures
      p.load();
    } else if (wasIn && !nowIn) {
      // logout
      p.clear();
    } else if (identityChanged) {
      // сменился пользователь
      p.clear();
      // ignore: discarded_futures
      p.load();
    }
  });

  return p;
});
