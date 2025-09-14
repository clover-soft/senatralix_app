import 'package:flutter/material.dart';

/// Универсальный блок параметров с рамкой и заголовком.
/// Опционально: header-виджет под заголовком, список строк с drag'n'drop и добавлением,
/// и footer-виджет под списком.
class ParamBlockCard extends StatefulWidget {
  const ParamBlockCard({
    super.key,
    required this.title,
    this.showTitle = true,
    this.margin,
    this.header,
    this.enableList = false,
    this.items = const <String>[],
    this.onChanged,
    this.footer,
    this.contentPadding,
  });

  final String title;
  final bool showTitle;
  final EdgeInsets? margin;
  final Widget? header;

  // Секция списка
  final bool enableList;
  final List<String> items;
  final ValueChanged<List<String>>? onChanged;

  // Подвал (например, выбор стратегии, таймаут и т.п.)
  final Widget? footer;
  final EdgeInsets? contentPadding;

  @override
  State<ParamBlockCard> createState() => _ParamBlockCardState();
}

class _ParamBlockCardState extends State<ParamBlockCard> {
  late List<String> _list;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _list = List<String>.from(widget.items);
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ParamBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _list = List<String>.from(widget.items);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged?.call(List<String>.from(_list));

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: widget.margin ?? const EdgeInsets.only(top: 8),
      child: Padding(
        padding: widget.contentPadding ?? const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) ...[
              Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            if (widget.header != null) ...[
              if (widget.showTitle)
                const SizedBox(height: 8)
              else
                const SizedBox(height: 0),
              widget.header!,
            ],
            if (widget.enableList) ...[
              const SizedBox(height: 8),
              ReorderableListView(
                buildDefaultDragHandles: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final it = _list.removeAt(oldIndex);
                    _list.insert(newIndex, it);
                  });
                  _notify();
                },
                children: [
                  for (int i = 0; i < _list.length; i++)
                    ListTile(
                      key: ValueKey('${widget.title}-$i-${_list[i]}'),
                      title: Text(_list[i]),
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => _list.removeAt(i));
                          _notify();
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('${widget.title}-add'),
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Новая фраза',
                      ),
                      onFieldSubmitted: (v) {
                        final t = v.trim();
                        if (t.isNotEmpty) {
                          setState(() => _list.add(t));
                          _notify();
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final t = _controller.text.trim();
                      if (t.isEmpty) return;
                      setState(() => _list.add(t));
                      _notify();
                      _controller.clear();
                    },
                    child: const Text('Добавить'),
                  ),
                ],
              ),
            ],
            if (widget.footer != null) ...[
              const SizedBox(height: 12),
              widget.footer!,
            ],
          ],
        ),
      ),
    );
  }
}
