import 'package:flutter/material.dart';
import 'package:sentralix_app/features/assistant/features/scripts/models/script.dart';

/// Диалог редактирования скрипта: name, trigger, params (map) и список шагов
class ScriptEditorDialog extends StatefulWidget {
  const ScriptEditorDialog({super.key, required this.initial});
  final Script initial;

  @override
  State<ScriptEditorDialog> createState() => _ScriptEditorDialogState();
}

class _ScriptEditorDialogState extends State<ScriptEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late bool _enabled;
  ScriptTrigger _trigger = ScriptTrigger.onDialogStart;
  late List<MapEntry<String, String>> _params; // редактируемый список пар key/value
  late List<ScriptStep> _steps;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s.name);
    _enabled = s.enabled;
    _trigger = s.trigger;
    _params = s.params.entries.map((e) => MapEntry(e.key, e.value)).toList();
    _steps = List<ScriptStep>.from(s.steps);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _vName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите имя';
    if (v.trim().length < 2 || v.trim().length > 60) return 'Длина 2–60';
    return null;
  }

  void _addParam() {
    setState(() => _params.add(const MapEntry('', '')));
  }

  void _removeParam(int i) {
    setState(() => _params.removeAt(i));
  }

  void _addStep() async {
    final step = await showDialog<ScriptStep>(
      context: context,
      builder: (_) => StepEditorDialog(
        initial: ScriptStep(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          jsonpath: '',
          action: ActionDef(
            type: ActionType.httpGet,
            http: const ActionHttp(url: ''),
          ),
        ),
      ),
    );
    if (step != null) setState(() => _steps.add(step));
  }

  void _editStep(int index) async {
    final step = await showDialog<ScriptStep>(
      context: context,
      builder: (_) => StepEditorDialog(initial: _steps[index]),
    );
    if (step != null) setState(() => _steps[index] = step);
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index));
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    // Валидация params: ключи 1–40, значения — строки
    for (final p in _params) {
      if (p.key.trim().isEmpty || p.key.trim().length > 40) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ключ параметра должен быть 1–40 символов')),
        );
        return;
      }
    }
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте как минимум один шаг')),
      );
      return;
    }
    final mapParams = <String, String>{
      for (final p in _params) p.key.trim(): p.value,
    };
    final updated = widget.initial.copyWith(
      name: _name.text.trim(),
      enabled: _enabled,
      trigger: _trigger,
      params: mapParams,
      steps: _steps,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Скрипт'),
      content: SizedBox(
        width: 860,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Название'),
                        validator: _vName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ScriptTrigger>(
                        value: _trigger,
                        items: const [
                          DropdownMenuItem(
                            value: ScriptTrigger.onDialogStart,
                            child: Text('on_dialog_start'),
                          ),
                          DropdownMenuItem(
                            value: ScriptTrigger.onDialogEnd,
                            child: Text('on_dialog_end'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _trigger = v ?? ScriptTrigger.onDialogStart),
                        decoration: const InputDecoration(labelText: 'Trigger'),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  title: const Text('Включен'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Параметры', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _params.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _params[index].key,
                            decoration: const InputDecoration(labelText: 'key'),
                            onChanged: (v) => _params[index] = MapEntry(v, _params[index].value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: _params[index].value,
                            decoration: const InputDecoration(labelText: 'value'),
                            onChanged: (v) => _params[index] = MapEntry(_params[index].key, v),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Удалить параметр',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeParam(index),
                        ),
                      ],
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addParam,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить параметр'),
                  ),
                ),
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Шаги', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final st = _steps[index];
                    final actionLabel = st.action.type == ActionType.httpPost ? 'POST' : 'GET';
                    return Card(
                      child: ListTile(
                        title: Text(st.jsonpath.isEmpty ? '(jsonpath не задан)' : st.jsonpath),
                        subtitle: Text('$actionLabel ${st.action.http.url.isEmpty ? '(url не задан)' : st.action.http.url}')
                            ,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Редактировать шаг',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editStep(index),
                            ),
                            IconButton(
                              tooltip: 'Удалить шаг',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeStep(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить шаг'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _onSave, child: const Text('Сохранить')),
      ],
    );
  }
}

class StepEditorDialog extends StatefulWidget {
  const StepEditorDialog({super.key, required this.initial});
  final ScriptStep initial;

  @override
  State<StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<StepEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jsonpath;
  ActionType _type = ActionType.httpGet;
  late TextEditingController _url;
  late TextEditingController _headersJson;
  late TextEditingController _queryJson;
  late TextEditingController _bodyTemplate;

  @override
  void initState() {
    super.initState();
    _jsonpath = TextEditingController(text: widget.initial.jsonpath);
    _type = widget.initial.action.type;
    _url = TextEditingController(text: widget.initial.action.http.url);
    _headersJson = TextEditingController();
    _queryJson = TextEditingController();
    _bodyTemplate = TextEditingController(text: widget.initial.action.http.bodyTemplate ?? '');
  }

  @override
  void dispose() {
    _jsonpath.dispose();
    _url.dispose();
    _headersJson.dispose();
    _queryJson.dispose();
    _bodyTemplate.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.initial.copyWith(
      jsonpath: _jsonpath.text.trim(),
      action: ActionDef(
        type: _type,
        http: ActionHttp(
          url: _url.text.trim(),
          // Упрощение: редакторы headers/query оставлены как задел, пока не парсим JSON для шага
          // Можно расширить позже: парсить JSON и формировать Map<String,String>
          headers: const {},
          query: const {},
          bodyTemplate: _type == ActionType.httpPost ? _bodyTemplate.text : null,
        ),
      ),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Шаг скрипта'),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _jsonpath,
                  decoration: const InputDecoration(labelText: 'when.jsonpath'),
                  validator: _req,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ActionType>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: ActionType.httpGet, child: Text('http_get')),
                    DropdownMenuItem(value: ActionType.httpPost, child: Text('http_post')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? ActionType.httpGet),
                  decoration: const InputDecoration(labelText: 'action.type'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _url,
                  decoration: const InputDecoration(labelText: 'http.url'),
                  validator: _req,
                ),
                const SizedBox(height: 8),
                if (_type == ActionType.httpPost)
                  TextFormField(
                    controller: _bodyTemplate,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'http.body_template'),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _onSave, child: const Text('Сохранить')),
      ],
    );
  }
}
