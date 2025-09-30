import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/dialog_slot.dart';
import 'package:sentralix_app/features/assistant/features/slots/providers/slots_providers.dart';
import 'package:sentralix_app/features/assistant/features/slots/models/slot_types.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'dart:convert';

/// Панель деталей выбранного слота (редактируемая форма)
class SlotDetailsPanel extends ConsumerStatefulWidget {
  const SlotDetailsPanel({super.key});

  @override
  ConsumerState<SlotDetailsPanel> createState() => _SlotDetailsPanelState();
}

class _JsonEditor extends StatefulWidget {
  const _JsonEditor({
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? hintText;

  @override
  State<_JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<_JsonEditor> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final lines = text.isEmpty ? 1 : text.split('\n').length;
    final gutterText = List.generate(lines, (i) => '${i + 1}').join('\n');

    final mono = const TextStyle(fontFamily: 'monospace', fontSize: 13);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Линейка строк
          Container(
            width: 36,
            padding: const EdgeInsets.fromLTRB(8, 12, 4, 12),
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Text(
                gutterText,
                style: mono.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: TextField(
                controller: widget.controller,
                scrollController: _scrollController,
                maxLines: 12,
                onChanged: (v) {
                  setState(() {}); // обновить количество строк
                  widget.onChanged(v);
                },
                style: mono,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  errorText: widget.errorText,
                  isDense: true,
                  border: InputBorder.none,
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotDetailsPanelState extends ConsumerState<SlotDetailsPanel> {
  final _nameCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _optionCtrl = TextEditingController();
  final _hintCtrl = TextEditingController();
  final _metadataCtrl = TextEditingController();
  String _slotTypeKey = '';
  List<String> _options = [];
  List<String> _hints = [];
  String? _metadataError;
  String? _nameError;
  String? _lastSlotId;
  late final ScrollController _scrollController;
  bool _showMetadata = false;
  bool _saving = false;

  // Оригинальные значения выбранного слота (для сброса)
  String _origName = '';
  String _origLabel = '';
  String _origPrompt = '';
  String _origTypeKey = '';
  List<String> _origOptions = const [];
  List<String> _origHints = const [];
  String _origMetadataText = '{}';

  String? _validateName(String value) {
    final v = value.trim();
    if (v.toUpperCase().startsWith('THREAD_')) {
      return 'Префикс THREAD_ зарезервирован для системных ячеек';
    }
    return null;
  }

  String _normalizeTypeKey(String key) {
    // Совместимость с бэкендом: иногда приходит 'list' вместо 'repeatable'
    if (key == 'list') return 'repeatable';
    return key;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    _promptCtrl.dispose();
    _optionCtrl.dispose();
    _hintCtrl.dispose();
    _metadataCtrl.dispose();
    super.dispose();
  }

  void _populateFrom(DialogSlot slot) {
    _lastSlotId = slot.id.toString();
    _nameCtrl.text = slot.name;
    _labelCtrl.text = slot.label;
    _promptCtrl.text = slot.prompt;
    _slotTypeKey = _normalizeTypeKey(slot.slotType);
    _options = List<String>.from(slot.options);
    _hints = List<String>.from(slot.hints);
    _metadataCtrl.text = slot.metadata.isEmpty
        ? '{}'
        : const JsonEncoder.withIndent('  ').convert(slot.metadata);
    _metadataError = null;
    _nameError = _validateName(_nameCtrl.text);
    _showMetadata = false; // по умолчанию скрываем поле редактирования metadata

    // Сохраняем оригинальные значения для корректного сброса
    _origName = _nameCtrl.text;
    _origLabel = _labelCtrl.text;
    _origPrompt = _promptCtrl.text;
    _origTypeKey = _slotTypeKey;
    _origOptions = List<String>.from(_options);
    _origHints = List<String>.from(_hints);
    _origMetadataText = _metadataCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dialogSlotsProvider);
    final selectedId = ref.watch(selectedSlotIdProvider);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _ErrorState(error: e.toString()),
          data: (slots) {
            if (selectedId == null) {
              return const _HintState(
                title: 'Выберите ячейку памяти из списка',
                subtitle:
                    'Слева отобразите список и выберите ячейку памяти для просмотра деталей',
              );
            }
            final DialogSlot slot = slots.firstWhere(
              (s) => s.id == selectedId,
              orElse: () => slots.first,
            );
            // При смене выбранного слота — переинициализируем контроллеры
            if (_lastSlotId != slot.id.toString()) {
              _populateFrom(slot);
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          primary: false,
                          padding: EdgeInsets.zero,
                          child: _EditForm(
                            nameCtrl: _nameCtrl,
                            nameError: _nameError,
                            labelCtrl: _labelCtrl,
                            promptCtrl: _promptCtrl,
                            optionCtrl: _optionCtrl,
                            hintCtrl: _hintCtrl,
                            metadataCtrl: _metadataCtrl,
                            slotTypeKey: _slotTypeKey,
                            onSlotTypeChanged: (v) {
                              setState(() => _slotTypeKey = v);
                            },
                            onNameChanged: (txt) {
                              setState(() {
                                _nameError = _validateName(txt);
                              });
                            },
                            options: _options,
                            hints: _hints,
                            onAddOption: () {
                              final v = _optionCtrl.text.trim();
                              if (v.isEmpty) return;
                              final exists = _options.any((e) => e.toLowerCase() == v.toLowerCase());
                              if (exists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Такая опция уже существует')),
                                );
                                return;
                              }
                              setState(() {
                                _options.add(v);
                                _optionCtrl.clear();
                              });
                            },
                            onRemoveOption: (v) => setState(() => _options.remove(v)),
                            onAddHint: () {
                              final v = _hintCtrl.text.trim();
                              if (v.isEmpty) return;
                              final exists = _hints.any((e) => e.toLowerCase() == v.toLowerCase());
                              if (exists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Такая подсказка уже существует')),
                                );
                                return;
                              }
                              setState(() {
                                _hints.add(v);
                                _hintCtrl.clear();
                              });
                            },
                            onRemoveHint: (v) => setState(() => _hints.remove(v)),
                            metadataError: _metadataError,
                            onMetadataChanged: (txt) {
                              setState(() {
                                _metadataError = null;
                                if (txt.trim().isEmpty) return;
                                try {
                                  jsonDecode(txt);
                                } catch (e) {
                                  _metadataError = 'Некорректный JSON: $e';
                                }
                              });
                            },
                            showMetadata: _showMetadata,
                            onToggleMetadata: (v) => setState(() => _showMetadata = v),
                            onReset: () {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                  setState(() {
                                    _nameCtrl.text = _origName;
                                    _labelCtrl.text = _origLabel;
                                    _promptCtrl.text = _origPrompt;
                                    _slotTypeKey = _origTypeKey;
                                    _options = List<String>.from(_origOptions);
                                    _hints = List<String>.from(_origHints);
                                    _metadataCtrl.text = _origMetadataText;
                                    _metadataError = null;
                                    _showMetadata = false;
                                  });
                                },
                            child: const Text('Сбросить'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: (_nameError != null || _saving)
                                ? null
                                : () async {
                                    // Валидация метаданных
                                    Map<String, dynamic> metadata = const {};
                                    final raw = _metadataCtrl.text.trim();
                                    if (raw.isNotEmpty && raw != '{}') {
                                      try {
                                        final parsed = jsonDecode(raw);
                                        if (parsed is Map) {
                                          metadata = Map<String, dynamic>.from(parsed);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Metadata должен быть объектом JSON')),
                                          );
                                          return;
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Некорректный JSON metadata: $e')),
                                        );
                                        return;
                                      }
                                    }

                                    // Имя не должно быть пустым и без запрещённого префикса
                                    final name = _nameCtrl.text.trim();
                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Имя (key) не должно быть пустым')),
                                      );
                                      return;
                                    }
                                    final err = _validateName(name);
                                    if (err != null) {
                                      setState(() => _nameError = err);
                                      return;
                                    }

                                    setState(() => _saving = true);
                                    try {
                                      final api = ref.read(assistantApiProvider);
                                      // Найдём текущий слот (он определён выше в замыкании)
                                      final slots = ref.read(dialogSlotsProvider).value ?? [];
                                      final DialogSlot cur = slots.firstWhere(
                                        (s) => s.id.toString() == _lastSlotId,
                                        orElse: () => DialogSlot(
                                          id: int.tryParse(_lastSlotId ?? '') ?? 0,
                                          name: name,
                                          label: _labelCtrl.text.trim(),
                                          prompt: _promptCtrl.text.trim(),
                                          options: _options,
                                          hints: _hints,
                                          metadata: metadata,
                                          slotType: _slotTypeKey,
                                        ),
                                      );
                                      final id = cur.id;

                                      final body = <String, dynamic>{
                                        'name': name,
                                        'label': _labelCtrl.text.trim(),
                                        'prompt': _promptCtrl.text.trim(),
                                        'options': _options,
                                        'hints': _hints,
                                        'metadata': metadata,
                                        'slot_type': _slotTypeKey,
                                      };

                                      final saved = await api.updateDialogSlot(id: id, body: body);

                                      // Обновим локальные оригинальные значения
                                      setState(() {
                                        _origName = saved.name;
                                        _origLabel = saved.label;
                                        _origPrompt = saved.prompt;
                                        _origTypeKey = saved.slotType;
                                        _origOptions = List<String>.from(saved.options);
                                        _origHints = List<String>.from(saved.hints);
                                        _origMetadataText = const JsonEncoder.withIndent('  ').convert(saved.metadata);
                                      });

                                      // Обновим список
                                      ref.invalidate(dialogSlotsProvider);

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Слот сохранён')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ошибка при сохранении: $e')),
                                      );
                                    } finally {
                                      if (mounted) setState(() => _saving = false);
                                    }
                                  },
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Сохранить'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.nameCtrl,
    required this.nameError,
    required this.labelCtrl,
    required this.promptCtrl,
    required this.optionCtrl,
    required this.hintCtrl,
    required this.metadataCtrl,
    required this.slotTypeKey,
    required this.onSlotTypeChanged,
    required this.onNameChanged,
    required this.options,
    required this.hints,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onAddHint,
    required this.onRemoveHint,
    required this.metadataError,
    required this.onMetadataChanged,
    required this.showMetadata,
    required this.onToggleMetadata,
    required this.onReset,
  });

  final TextEditingController nameCtrl;
  final String? nameError;
  final TextEditingController labelCtrl;
  final TextEditingController promptCtrl;
  final TextEditingController optionCtrl;
  final TextEditingController hintCtrl;
  final TextEditingController metadataCtrl;
  final String slotTypeKey;
  final ValueChanged<String> onSlotTypeChanged;
  final ValueChanged<String> onNameChanged;
  final List<String> options;
  final List<String> hints;
  final VoidCallback onAddOption;
  final ValueChanged<String> onRemoveOption;
  final VoidCallback onAddHint;
  final ValueChanged<String> onRemoveHint;
  final String? metadataError;
  final ValueChanged<String> onMetadataChanged;
  final bool showMetadata;
  final ValueChanged<bool> onToggleMetadata;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Параметры ячейки памяти',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Имя (key)',
          child: TextField(
            controller: nameCtrl,
            onChanged: onNameChanged,
            decoration: InputDecoration(
              hintText: 'Например: EMAIL',
              errorText: nameError,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Заголовок',
          child: TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(hintText: 'Человекочитаемое имя'),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Тип',
          child: !isSlotTypeSelectable(slotTypeKey) && slotTypeKey.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: kSlotTypeLabels[slotTypeKey] ?? slotTypeKey,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Текущий тип недоступен для выбора. Вы можете изменить тип, выбрав доступное значение.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : DropdownButtonFormField<String>(
                  initialValue: slotTypeKey.isEmpty ? null : slotTypeKey,
                  items: [
                    for (final t in kSelectableSlotTypes)
                      DropdownMenuItem(value: t.key, child: Text(t.label)),
                  ],
                  onChanged: (v) {
                    if (v != null) onSlotTypeChanged(v);
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Промпт',
          child: TextField(
            controller: promptCtrl,
            decoration: const InputDecoration(
              hintText: 'Подсказка для ассистента',
            ),
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 12),
        if (slotTypeKey == 'enum')
          _Section(
            title: 'Опции',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in options)
                      Chip(label: Text(o), onDeleted: () => onRemoveOption(o)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: optionCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Добавить опцию и нажать +',
                        ),
                        onSubmitted: (_) => onAddOption(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onAddOption,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _Section(
          title: 'Подсказки',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in hints)
                    Chip(label: Text(h), onDeleted: () => onRemoveHint(h)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hintCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Добавить подсказку и нажать +',
                      ),
                      onSubmitted: (_) => onAddHint(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onAddHint,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Metadata (JSON)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Редактировать metadata как JSON'),
                value: showMetadata,
                onChanged: (v) => onToggleMetadata(v ?? false),
              ),
              if (showMetadata)
                _JsonEditor(
                  controller: metadataCtrl,
                  errorText: metadataError,
                  hintText: '{"min_len": 1, "max_len": 10}',
                  onChanged: onMetadataChanged,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (slotTypeKey.isNotEmpty)
          Text(
            kSlotTypeDescriptions[slotTypeKey] ?? '',
            style: theme.textTheme.bodySmall,
          ),
        // Кнопки действий вынесены в статичную нижнюю панель родителя
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _HintState extends StatelessWidget {
  const _HintState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 32),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text('Ошибка: $error'),
        ],
      ),
    );
  }
}
