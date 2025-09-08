import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';

/// Локальное меню подфич ассистента
class AssistantHomeScreen extends ConsumerWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final id = GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';

    final items = <_SubItem>[
      _SubItem('Settings', 'Модель, температура, токены, промпт…', Icons.tune, '/assistant/$id/settings'),
      _SubItem('Tools', 'Инструменты, которые ассистент может вызывать', Icons.extension, '/assistant/$id/tools'),
      _SubItem('Knowledge', 'База знаний: загрузка и управление', Icons.storage, '/assistant/$id/knowledge'),
      _SubItem('Connectors', 'VOIP, Telegram, Avito, WhatsApp…', Icons.link, '/assistant/$id/connectors'),
      _SubItem('Scripts', 'События и действия: вход/выход, триггеры', Icons.schedule, '/assistant/$id/scripts'),
      _SubItem('Chat', 'Тестовый диалог с ассистентом', Icons.smart_toy, '/assistant/$id/chat'),
      _SubItem('Sessions', 'Сессии/треды, история', Icons.history, '/assistant/$id/sessions'),
    ];

    return Scaffold(
      appBar: AssistantAppBar(assistantId: id),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w <= 480
                ? 1
                : (w <= 900
                    ? 2
                    : 3);
            final textScale = MediaQuery.textScaleFactorOf(context);
            // Больше высоты для узких экранов и увеличенного масштаба текста
            double childAspectRatio = 1.9; // ширина/высота
            if (crossAxisCount == 2) childAspectRatio = 1.6; // выше, чтобы поместились 2 строки
            if (crossAxisCount == 1) childAspectRatio = 1.2; // ещё выше в 1 колонку
            if (textScale > 1.0) {
              childAspectRatio -= 0.3; // делаем карточку выше при крупном шрифте
              if (childAspectRatio < 1.05) childAspectRatio = 1.05;
            }
            // Пользователь просит уменьшить максимальную высоту карточки ~ в 1.5 раза =>
            // увеличиваем aspectRatio на 1.5x (чем больше ratio, тем ниже карточка),
            // но оставляем разумные ограничения.
            childAspectRatio *= 1.5;
            if (childAspectRatio > 3.2) childAspectRatio = 3.2; // верхняя граница (слишком плоские карточки не нужны)
            if (childAspectRatio < 1.1) childAspectRatio = 1.1; // нижняя граница (не слишком высокие)
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                return Card(
                  color: scheme.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go(it.route),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(it.icon, color: scheme.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  it.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  it.subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  _SubItem(this.title, this.subtitle, this.icon, this.route);
}
