import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/features/dialogs/models/dialogs.dart';

/// Список конфигов диалогов (кратко)
final dialogConfigsProvider = FutureProvider<List<DialogConfigShort>>((
  ref,
) async {
  final api = ref.read(assistantApiProvider);
  final list = await api.fetchDialogConfigs();
  return list.map((e) => DialogConfigShort.fromJson(e)).toList();
});

/// Выбранная вкладка (config id)
final selectedDialogConfigIdProvider = StateProvider<int?>((ref) => null);

/// Детали конфига по id
final dialogConfigDetailsProvider =
    FutureProvider.family<DialogConfigDetails, int>((ref, id) async {
      final api = ref.read(assistantApiProvider);
      final json = await api.fetchDialogConfig(id);
      return DialogConfigDetails.fromJson(json);
    });
