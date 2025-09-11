import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/connector_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';

/// Загрузка списка коннекторов из бэкенда и помещение в состояние ассистента
final assistantConnectorsProvider = FutureProvider.family<void, String>((ref, assistantId) async {
  await ref.watch(assistantBootstrapProvider.future);
  final api = ref.read(assistantApiProvider);
  final List<Connector> items = await api.fetchConnectorsList();
  ref.read(connectorsProvider.notifier).replaceAll(assistantId, items);
});
