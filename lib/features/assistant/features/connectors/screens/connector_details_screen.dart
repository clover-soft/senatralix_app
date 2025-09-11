import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/connector.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/connector_edit_provider.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/connector_provider.dart';
import 'package:sentralix_app/features/assistant/features/connectors/providers/assistant_connectors_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/features/connectors/widgets/param_block_card.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/selection_options.dart';
import 'package:sentralix_app/features/assistant/features/connectors/models/dictor_options.dart';

class ConnectorDetailsScreen extends ConsumerWidget {
  const ConnectorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stRoute = GoRouterState.of(context);
    final assistantId = stRoute.pathParameters['assistantId'] ?? 'unknown';
    final connectorId = stRoute.pathParameters['connectorId'] ?? '';
    // ensure connectors loaded
    final loader = ref.watch(assistantConnectorsProvider(assistantId));
    final items = ref.watch(
      connectorsProvider.select(
        (s) => s.byAssistantId[assistantId] ?? const <Connector>[],
      ),
    );
    final initial = items.firstWhere(
      (e) => e.id == connectorId,
      orElse: () => Connector(
        id: connectorId,
        type: 'telephony',
        name: '',
        isActive: true,
        settings: ConnectorSettings(
          dialog: ConnectorDialogSettings(
            greetingTexts: [],
            greetingSelectionStrategy: 'first',
            repromptTexts: [],
            repromptSelectionStrategy: 'round_robin',
            allowBargeIn: true,
            maxTurns: 20,
            noinputRetries: 3,
            hangupOnNoinput: false,
            maxCallDurationSec: 300,
            repeatPromptOnInterrupt: true,
            interruptMaxRetries: 0,
            interruptFinalText: '',
            noinputFinalText: '',
            maxTurnsFinalText: '',
            maxCallDurationFinalText: '',
          ),
          assistant: ConnectorAssistantSettings(
            fillerTextList: [],
            fillerSelectionStrategy: 'round_robin',
            softTimeoutMs: 2500,
            dictor: 'oksana',
            speed: 1.0,
          ),
        ),
      ),
    );

    if (loader.isLoading && items.isEmpty) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Коннектор',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (loader.hasError && items.isEmpty) {
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Коннектор',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ошибка загрузки коннекторов'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.refresh(assistantConnectorsProvider(assistantId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final st = ref.watch(connectorEditProvider(initial));
    final ctrl = ref.read(connectorEditProvider(initial).notifier);

    void onSave() {
      final updated = ctrl.buildResult(initial);
      ref.read(connectorsProvider.notifier).update(assistantId, updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сохранено')));
      context.go('/assistant/$assistantId/connectors');
    }

    // Локальный вспомогательный билдер больше не нужен — используем ReorderableAddListCard

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle:
            'Коннектор: ${st.name.isEmpty ? 'Без имени' : st.name}',
        backPath: '/assistant/$assistantId/connectors',
        backTooltip: 'К списку коннекторов',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onSave,
        tooltip: 'Сохранить',
        child: const Icon(Icons.save),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Центрирование на широких экранах (контейнерная ширина)
          final double maxContainerWidth = width >= 1200 ? 1040 : width;
          final double containerWidth = maxContainerWidth;
          const double outerPadding = 16; // см. SingleChildScrollView padding
          final double availableWidth = (containerWidth - outerPadding * 2).clamp(0, double.infinity);

          // Адаптив: 1 или 2 колонки. >680 — две колонки, иначе одна.
          // Минимальная ширина карточки: 340. В одиночной колонке ограничиваем до 600.
          final double minCardWidth = 340;
          final double singleMaxWidth = 600;
          final double gap = width < 600 ? 8 : (width < 900 ? 12 : 16);

          int cols = availableWidth > 680 ? 2 : 1;
          double itemWidth;
          if (cols == 2) {
            final twoColWidth = (availableWidth - gap) / 2;
            if (twoColWidth < minCardWidth) {
              cols = 1;
              itemWidth = availableWidth.clamp(minCardWidth, singleMaxWidth);
            } else {
              itemWidth = twoColWidth;
            }
          } else {
            itemWidth = availableWidth.clamp(minCardWidth, singleMaxWidth);
          }

          final EdgeInsets contentPadding = width >= 900
              ? const EdgeInsets.all(16)
              : const EdgeInsets.all(12);

          // Секции формы как карточки (4 группы)
          final sections = <Widget>[
            // 1) Основные настройки (ParamBlockCard с header)
            SizedBox(
              width: itemWidth,
              child: ParamBlockCard(
                title: 'Основные настройки',
                contentPadding: contentPadding,
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: st.name,
                      decoration: const InputDecoration(labelText: 'Имя коннектора'),
                      onChanged: ctrl.setName,
                    ),
                    SwitchListTile(
                      value: st.isActive,
                      onChanged: ctrl.setActive,
                      title: const Text('Включен'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Builder(
                      builder: (context) {
                        final options = DictorOptions.ruOptions();
                        // Поддержка старых значений: если без суффикса стиля — подобрать neutral/первый стиль
                        String? currentValue = st.dictor;
                        if (currentValue.isNotEmpty && !currentValue.contains('_')) {
                          final guess = DictorOptions.firstByCode(currentValue);
                          if (guess != null) currentValue = guess.value;
                        }
                        // Если текущее значение не найдено в списке, взять первое
                        if (options.indexWhere((o) => o.value == currentValue) == -1) {
                          currentValue = options.isNotEmpty ? options.first.value : currentValue;
                        }
                        return DropdownButtonFormField<String>(
                          value: currentValue,
                          items: options
                              .map((o) => DropdownMenuItem<String>(
                                    value: o.value,
                                    child: Text(o.label),
                                  ))
                              .toList(),
                          onChanged: (v) => ctrl.setDictor(v ?? currentValue ?? st.dictor),
                          decoration: const InputDecoration(labelText: 'Голос'),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Скорость: ${st.speed.toStringAsFixed(1)}'),
                    Slider(
                      value: st.speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (v) => ctrl.setSpeed(double.parse(v.toStringAsFixed(1))),
                    ),
                  ],
                ),
              ),
            ),

            // 2) Приветствие (ParamBlockCard со списком + footer)
            SizedBox(
              width: itemWidth,
              child: ParamBlockCard(
                title: 'Приветствие',
                contentPadding: contentPadding,
                enableList: true,
                items: st.greetingTexts,
                onChanged: ctrl.setGreetingTexts,
                footer: DropdownButtonFormField<String>(
                  value: st.greetingSelectionStrategy,
                  items: SelectionStrategyOptions.common
                      .map((o) => DropdownMenuItem<String>(
                            value: o.value,
                            child: Text(o.label),
                          ))
                      .toList(),
                  onChanged: (v) => ctrl.setGreetingStrategy(v ?? 'first'),
                  decoration: const InputDecoration(labelText: 'Стратегия приветствия'),
                ),
              ),
            ),

            // 3) Репромты (ParamBlockCard со списком + footer)
            SizedBox(
              width: itemWidth,
              child: ParamBlockCard(
                title: 'Репромты',
                contentPadding: contentPadding,
                enableList: true,
                items: st.repromptTexts,
                onChanged: ctrl.setRepromptTexts,
                footer: DropdownButtonFormField<String>(
                  value: st.repromptSelectionStrategy,
                  items: SelectionStrategyOptions.common
                      .map((o) => DropdownMenuItem<String>(
                            value: o.value,
                            child: Text(o.label),
                          ))
                      .toList(),
                  onChanged: (v) => ctrl.setRepromptStrategy(v ?? 'round_robin'),
                  decoration: const InputDecoration(labelText: 'Стратегия выбора репромта'),
                ),
              ),
            ),

            // 4) Филлеры (ParamBlockCard со списком + footer)
            SizedBox(
              width: itemWidth,
              child: ParamBlockCard(
                title: 'Филлеры',
                contentPadding: contentPadding,
                enableList: true,
                items: st.fillerTextList,
                onChanged: ctrl.setFillerList,
                footer: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: st.fillerSelectionStrategy,
                        items: SelectionStrategyOptions.common
                            .map((o) => DropdownMenuItem<String>(
                                  value: o.value,
                                  child: Text(o.label),
                                ))
                            .toList(),
                        onChanged: (v) => ctrl.setFillerStrategy(v ?? 'round_robin'),
                        decoration: const InputDecoration(labelText: 'Стратегия выбора филлера'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: st.softTimeoutMs.toString(),
                        decoration: const InputDecoration(labelText: 'Таймаут филлера (мс)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final n = int.tryParse(v.trim());
                          if (n != null) ctrl.setSoftTimeoutMs(n);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContainerWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: sections,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
