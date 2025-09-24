import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_command_edit_state.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script_list_item.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/message_filter_form_state.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/assistant_scripts_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_command_edit_provider.dart';
import 'package:sentralix_app/features/assistant/features/scripts/providers/script_list_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_fab.dart';
import 'package:sentralix_app/features/assistant/features/scripts/utils/filter_expression_builder.dart';
import 'package:sentralix_app/features/assistant/features/scripts/utils/filter_expression_parser.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/filter_preset_section.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/script_steps_list.dart';
import 'package:sentralix_app/features/assistant/features/scripts/widgets/script_action_presets_panel.dart';

/// Экран создания/редактирования команды (thread-command)
/// По нажатию Сохранить вызывает POST и добавляет элемент в список ассистента
class ScriptCommandEditorScreen extends ConsumerWidget {
  const ScriptCommandEditorScreen({super.key});

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context);
    final assistantId = route.pathParameters['assistantId'] ?? 'unknown';
    final scriptIdStr = route.pathParameters['scriptId'];
    final int? scriptId = int.tryParse(scriptIdStr ?? '');

    // Стабильный ключ для family-провайдеров: assistantId:scriptId|new
    final familyKey = scriptId != null && scriptId != 0
        ? '$assistantId:$scriptId'
        : '$assistantId:new';

    // Убедимся, что список загружен (на случай прямого перехода по URL)
    final loader = ref.watch(assistantScriptsProvider(assistantId));
    final existing = ref.watch(
      scriptListProvider.select(
        (s) => s.byAssistantId[assistantId] ?? const [],
      ),
    );
    final nextOrder = (existing.isEmpty)
        ? 1
        : (existing.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1);
    final existingItem = (scriptId != null)
        ? existing.firstWhere(
            (e) => e.id == scriptId,
            orElse: () => const ScriptListItem(
              id: 0,
              assistantId: 0,
              order: 0,
              name: '',
              description: '',
              filterExpression: '',
              isActive: true,
            ),
          )
        : null;

    // Если это режим редактирования (есть scriptId), но элемент ещё не загружен —
    // не показываем пустую форму. Ждём загрузку или показываем ошибку.
    if (scriptId != null && (existingItem == null || existingItem.id == 0)) {
      if (loader.isLoading) {
        return Scaffold(
          appBar: AssistantAppBar(
            assistantId: assistantId,
            subfeatureTitle: 'Скрипт',
            backPath: '/assistant/$assistantId/scripts',
            backTooltip: 'К списку команд',
            backPopFirst: false,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      } else {
        return Scaffold(
          appBar: AssistantAppBar(
            assistantId: assistantId,
            subfeatureTitle: 'Скрипт',
            backPath: '/assistant/$assistantId/scripts',
            backTooltip: 'К списку команд',
            backPopFirst: false,
          ),
          body: const Center(child: Text('Скрипт не найден')),
        );
      }
    }

    // Инициализационное состояние формы
    final initial = (existingItem != null && existingItem.id != 0)
        ? ScriptCommandEditState(
            order: existingItem.order,
            name: existingItem.name,
            description: existingItem.description,
            filterExpression: existingItem.filterExpression,
            isActive: existingItem.isActive,
          )
        : ScriptCommandEditState.initial().copy(order: nextOrder);
    // Используем familyKey для провайдера состояния формы
    final ctrl = ref.read(scriptCommandEditProvider(familyKey).notifier);
    // Инициализация состояния формы:
    // - Для новой команды — сразу из initial
    // - Для режима редактирования — только когда existingItem фактически найден
    final st = ref.watch(scriptCommandEditProvider(familyKey));
    if (existingItem == null || existingItem.id == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ctrl.initIfNeeded(initial);
      });
    }

    final initDone = ref.watch(scriptEditorInitProvider(familyKey));
    final msgProv = messageFilterFormProvider(familyKey);
    if (!initDone && existingItem != null && existingItem.id != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Инициализация формы значениями из backend
        ctrl.initIfNeeded(initial);
        final parsed = parseFilterExpression(existingItem.filterExpression);
        // Установим пресет
        ref.read(scriptPresetProvider(familyKey).notifier).state = parsed.preset;
        // Если сообщение — заполним подформу
        if (parsed.message != null) {
          ref.read(msgProv.notifier).loadFromParsed(
                MessageFilterFormState(
                  roles: parsed.message!.roles,
                  type: parsed.message!.type,
                  textOrPattern: parsed.message!.textOrPattern,
                  flags: parsed.message!.flags,
                ),
              );
          // Пересоберём выражение, чтобы оно соответствовало текущим контролам
          final map = buildMessageFilter(ref.read(msgProv));
          ctrl.setFilter(stringifyFilter(map));
        }
        ref.read(scriptEditorInitProvider(familyKey).notifier).state = true;
      });
    }

    final savingProv = StateProvider.autoDispose<bool>((ref) => false);
    final saving = ref.watch(savingProv);

    if (loader.isLoading) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Новый скрипт',
          backPath: '/assistant/$assistantId/scripts',
          backTooltip: 'К списку команд',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: (existingItem != null && existingItem.id != 0)
            ? 'Скрипт'
            : 'Новый скрипт',
        backPath: '/assistant/$assistantId/scripts',
        backTooltip: 'К списку команд',
        backPopFirst: false,
      ),
      floatingActionButton: AssistantActionFab(
        icon: Icons.save,
        tooltip: saving ? 'Сохранение…' : 'Сохранить',
        onPressed: saving
            ? null
            : () async {
                // Валидация простая: name и filter_expression обязательны, order >=1
                if (st.name.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название')),
                  );
                  return;
                }
                if (st.filterExpression.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Укажите filter_expression')),
                  );
                  return;
                }
                ref.read(savingProv.notifier).state = true;
                try {
                  if (existingItem != null && existingItem.id != 0) {
                    // Редактирование: PATCH к бэкенду
                    final api = ref.read(assistantApiProvider);
                    final resp = await api.updateThreadCommandRaw(
                      id: existingItem.id,
                      assistantId: int.tryParse(assistantId) ?? existingItem.assistantId,
                      order: st.order,
                      name: st.name.trim(),
                      description: st.description.trim(),
                      filterExpression: st.filterExpression.trim(),
                      isActive: st.isActive,
                    );
                    // Обновим локально элемент из ответа
                    final updated = ScriptListItem.fromJson(resp);
                    ref.read(scriptListProvider.notifier).update(assistantId, updated);
                  } else {
                    // Создание: POST
                    final api = ref.read(assistantApiProvider);
                    final resp = await api.createThreadCommand(
                      assistantId: int.tryParse(assistantId) ?? 0,
                      order: st.order,
                      name: st.name.trim(),
                      description: st.description.trim(),
                      filterExpression: st.filterExpression.trim(),
                      isActive: st.isActive,
                    );
                    // Преобразуем и добавим в список
                    final created = ScriptListItem.fromJson(resp);
                    ref
                        .read(scriptListProvider.notifier)
                        .add(assistantId, created);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          (existingItem != null && existingItem.id != 0)
                              ? 'Скрипт сохранён'
                              : 'Скрипт создан',
                        ),
                      ),
                    );
                    context.go('/assistant/$assistantId/scripts');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка сохранения: $e')),
                    );
                  }
                } finally {
                  ref.read(savingProv.notifier).state = false;
                }
              },
        customChild: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Row(
                  children: [
                    const Text('Активен'),
                    const SizedBox(width: 8),
                    Switch(
                      value: st.isActive,
                      onChanged: (v) async {
                        // Всегда меняем локально состояние формы
                        ctrl.setActive(v);
                        // Если это существующий скрипт — шлём PATCH сразу
                        if (existingItem != null && existingItem.id != 0) {
                          final api = ref.read(assistantApiProvider);
                          try {
                            final resp = await api.updateThreadCommandRaw(
                              id: existingItem.id,
                              assistantId:
                                  int.tryParse(assistantId) ?? existingItem.assistantId,
                              order: st.order,
                              name: st.name.trim(),
                              description: st.description.trim(),
                              filterExpression: st.filterExpression.trim(),
                              isActive: v,
                            );
                            // Обновим глобальный список по ответу
                            final updated = ScriptListItem.fromJson(resp);
                            ref
                                .read(scriptListProvider.notifier)
                                .update(assistantId, updated);
                          } catch (e) {
                            // Откат локального состояния при ошибке
                            ctrl.setActive(!v);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Не удалось обновить статус: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final nameCtrl = ref.watch(nameControllerProvider(familyKey));
              // Синхронизация текста контроллера с состоянием
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (nameCtrl.text != st.name) {
                  nameCtrl.text = st.name;
                }
              });
              return TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: _required,
                onChanged: ctrl.setName,
              );
            }),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final descCtrl = ref.watch(descriptionControllerProvider(familyKey));
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (descCtrl.text != st.description) {
                  descCtrl.text = st.description;
                }
              });
              return TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 2,
                onChanged: ctrl.setDescription,
              );
            }),
            const SizedBox(height: 8),
            FilterPresetSection(familyKey: familyKey),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final stepsWidget = ScriptStepsList(existingItem: existingItem);
                final presetsWidget = ScriptActionPresetsPanel(
                  enabled: existingItem != null && existingItem.id != 0,
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: stepsWidget),
                      const SizedBox(width: 16),
                      SizedBox(width: 300, child: presetsWidget),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stepsWidget,
                    const SizedBox(height: 16),
                    presetsWidget,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
