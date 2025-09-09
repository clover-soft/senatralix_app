import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/connectors/data/connector_presets.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/connector_provider.dart';
import 'package:sentralix_app/features/assistant/features/connectors/widgets/connector_editor_dialog.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

class AssistantConnectorsScreen extends ConsumerStatefulWidget {
  const AssistantConnectorsScreen({super.key});

  @override
  ConsumerState<AssistantConnectorsScreen> createState() => _AssistantConnectorsScreenState();
}

class _AssistantConnectorsScreenState extends ConsumerState<AssistantConnectorsScreen> {
  late String _assistantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistantId = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';
  }

  void _addByPreset(String presetKey) async {
    final json = getConnectorPreset(presetKey) ?? getConnectorPreset('telephony')!;
    final draft = Connector.fromJson({
      ...json,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': json['name'] ?? 'Новый коннектор',
    });
    final res = await showDialog<Connector>(
      context: context,
      builder: (_) => ConnectorEditorDialog(initial: draft),
    );
    if (res != null) {
      ref.read(connectorsProvider.notifier).add(_assistantId, res);
    }
  }

  void _edit(Connector c) async {
    final res = await showDialog<Connector>(
      context: context,
      builder: (_) => ConnectorEditorDialog(initial: c),
    );
    if (res != null) {
      ref.read(connectorsProvider.notifier).update(_assistantId, res);
    }
  }

  void _remove(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить коннектор?'),
        content: const Text('Действие необратимо'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      ref.read(connectorsProvider.notifier).remove(_assistantId, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(connectorsProvider.select((s) => s.byAssistantId[_assistantId] ?? const []));
    return Scaffold(
      appBar: AssistantAppBar(assistantId: _assistantId, subfeatureTitle: 'Connectors'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить коннектор',
        onPressed: () async {
          final choice = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.call_outlined),
                    title: const Text('Telephony'),
                    subtitle: const Text('Телефония (единственный доступный тип на этом шаге)'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () => Navigator.pop(ctx, 'telephony'),
                  ),
                ],
              ),
            ),
          );
          _addByPreset(choice ?? 'telephony');
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final it = items[index];
          return Card(
            child: ListTile(
              leading: Switch(
                value: it.isActive,
                onChanged: (v) => ref.read(connectorsProvider.notifier).toggleActive(_assistantId, it.id, v),
              ),
              title: Text(it.name.isEmpty ? 'Без имени' : it.name),
              subtitle: Text(it.type),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(it),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _remove(it.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
