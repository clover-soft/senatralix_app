import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/models/knowledge_item.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_edit_provider.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/features/knowledge/providers/assistant_knowledge_provider.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_bootstrap_provider.dart';
import 'package:sentralix_app/features/assistant/providers/assistant_list_provider.dart';
import 'package:sentralix_app/features/assistant/shared/widgets/assistant_fab.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/markdown.dart' as hl;

/// Экран редактирования источника знаний (вместо модалки)
class KnowledgeEditorScreen extends ConsumerStatefulWidget {
  const KnowledgeEditorScreen({super.key});

  @override
  ConsumerState<KnowledgeEditorScreen> createState() =>
      _KnowledgeEditorScreenState();
}

class _KnowledgeEditorScreenState extends ConsumerState<KnowledgeEditorScreen> {
  bool _saving = false;
  bool _preview = true;
  CodeController? _codeCtrl;

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;
  String? _vInt(String? v, {int? min, int? max}) {
    if (v == null || v.trim().isEmpty) return 'Укажите значение';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Введите целое число';
    if (min != null && n < min) return 'Минимум $min';
    if (max != null && n > max) return 'Максимум $max';
    return null;
  }

  Future<void> _onSave(KnowledgeBaseItem initial, String assistantId) async {
    final st = ref.read(knowledgeEditProvider(initial));
    if (st.chunkOverlapTokens >= st.maxChunkSizeTokens) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'chunk_overlap_tokens должен быть меньше max_chunk_size_tokens',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final draft = ref
        .read(knowledgeEditProvider(initial).notifier)
        .buildResult(initial);
    try {
      final api = ref.read(assistantApiProvider);
      final resp = await api.updateKnowledge(draft);
      // Преобразуем ответ обратно в модель и обновим провайдер
      final updatedItem = KnowledgeBaseItem.fromJson(resp);
      ref.read(knowledgeProvider.notifier).update(assistantId, updatedItem);

      // Если пришёл список ассистентов для обновления — перезагрузим их список
      final au = resp['assistants_updated'];
      if (au is List && au.isNotEmpty) {
        final assistants = await api.fetchAssistants();
        ref.read(assistantListProvider.notifier).replaceAll(assistants);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Сохранено')));
        context.go('/assistant/$assistantId/knowledge');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context);
    final assistantId = route.pathParameters['assistantId'] ?? 'unknown';
    final knowledgeIdStr = route.pathParameters['knowledgeId'];
    // Убедимся, что список знаний загружен при прямом входе по URL
    final loader = ref.watch(assistantKnowledgeProvider(assistantId));
    KnowledgeBaseItem? initial = route.extra is KnowledgeBaseItem
        ? route.extra as KnowledgeBaseItem
        : null;
    if (initial == null && knowledgeIdStr != null) {
      final id = int.tryParse(knowledgeIdStr);
      if (id != null) {
        final items = ref.watch(
          knowledgeProvider.select(
            (s) => s.byAssistantId[assistantId] ?? const <KnowledgeBaseItem>[],
          ),
        );
        final idx = items.indexWhere((e) => e.id == id);
        if (idx >= 0) initial = items[idx];
      }
    }

    if (initial == null) {
      // Если ещё идёт загрузка — показываем индикатор
      if (loader.isLoading) {
        return Scaffold(
          appBar: AssistantAppBar(
            assistantId: assistantId,
            subfeatureTitle: 'Источник знаний',
            backPath: '/assistant/$assistantId/knowledge',
            backTooltip: 'К списку источников',
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AssistantAppBar(
          assistantId: assistantId,
          subfeatureTitle: 'Источник знаний',
          backPath: '/assistant/$assistantId/knowledge',
          backTooltip: 'К списку источников',
        ),
        body: const Center(child: Text('Источник не найден')),
      );
    }

    final item = initial; // not null после проверки выше
    final st = ref.watch(knowledgeEditProvider(item));
    final ctrl = ref.read(knowledgeEditProvider(item).notifier);

    // Инициализируем/синхронизируем CodeController для markdown
    _codeCtrl ??= CodeController(
      text: st.markdown,
      language: hl.markdown,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_codeCtrl!.text != st.markdown) {
        _codeCtrl!.value = _codeCtrl!.value.copyWith(
          text: st.markdown,
          selection: TextSelection.collapsed(offset: st.markdown.length),
        );
      }
    });

    // Цвет фона редактора в соответствии с темой (приближен к дефолтным темам редакторов)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F8FA);
    final editorTextColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AssistantAppBar(
        assistantId: assistantId,
        subfeatureTitle: 'Источник знаний',
        backPath: '/assistant/$assistantId/knowledge',
        backTooltip: 'К списку источников',
        backPopFirst: false,
      ),
      floatingActionButton: AssistantActionFab(
        icon: Icons.save,
        tooltip: _saving ? 'Сохранение…' : 'Сохранить',
        onPressed: _saving ? null : () => _onSave(item, assistantId),
        customChild: _saving
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
            // Нередактируемый external_id
            Row(
              children: [
                Text(
                  'external_id: ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SelectableText(
                  st.externalId,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Имя (обязательно)
            TextFormField(
              initialValue: st.name,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: _req,
              onChanged: ctrl.setName,
            ),
            const SizedBox(height: 8),
            // Описание (необязательно)
            TextFormField(
              initialValue: st.description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Краткое описание источника',
              ),
              onChanged: ctrl.setDescription,
            ),
            const SizedBox(height: 8),
            // Настройки чанков (перемещены выше, ближе к описанию)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: st.maxChunkSizeTokens.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Максимальный размер чанка (токены)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => _vInt(v, min: 100, max: 2000),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      if (n != null) ctrl.setMaxChunk(n);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: st.chunkOverlapTokens.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Перекрытие чанков (токены)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => _vInt(v, min: 0, max: 1000),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      if (n != null) ctrl.setOverlap(n);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Переключатель предпросмотра Markdown
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _preview,
              onChanged: (v) => setState(() => _preview = v),
              title: const Text('Предпросмотр Markdown'),
            ),
            const SizedBox(height: 8),
            if (_preview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: editorBg,
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.6),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectionArea(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: editorTextColor,
                    ),
                    child: GptMarkdown(
                      st.markdown,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: editorTextColor,
                      ),
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Текст в формате Markdown'),
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: editorBg,
                      border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.6),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CodeTheme(
                      data: CodeThemeData(styles: {
                        'root': TextStyle(backgroundColor: editorBg),
                      }),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: CodeField(
                            controller: _codeCtrl!,
                            textStyle: TextStyle(
                              fontFamily: 'monospace',
                              color: editorTextColor,
                            ),
                            expands: true,
                            wrap: true,
                            lineNumberStyle: const LineNumberStyle(width: 0),
                            onChanged: ctrl.setMarkdown,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Текст в формате Markdown. Рекомендуется не слишком большие тексты.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
