import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentralix_app/features/assistant/widgets/assistant_app_bar.dart';
import 'package:remixicon/remixicon.dart';

/// Локальное меню подфич ассистента
class AssistantHomeScreen extends ConsumerWidget {
  const AssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final id =
        GoRouterState.of(context).pathParameters['assistantId'] ?? 'unknown';

    final items = <_SubItem>[
      _SubItem(
        'Настройки',
        'Выберите модель, настройте температуру, лимиты токенов и системный промпт. Управляйте параметрами генерации и поведением ассистента.',
        RemixIcons.settings_3_line,
        '/assistant/$id/settings',
      ),
      _SubItem(
        'Навыки',
        'Подключайте и настраивайте инструменты, которые ассистент вызывает во время диалога: HTTP‑запросы, базы данных, интеграции и т. п.',
        RemixIcons.tools_line,
        '/assistant/$id/tools',
      ),
      _SubItem(
        'Базы знаний',
        'Загружайте файлы и статьи, настраивайте индексацию и доступ. Управляйте источниками знаний, которыми ассистент пользуется при ответах.',
        RemixIcons.database_2_line,
        '/assistant/$id/knowledge',
      ),
      _SubItem(
        'Коннекторы',
        'Подключайте каналы коммуникаций: VoIP, Telegram, Avito, WhatsApp и другие. Настройте вебхуки, авторизацию и маршрутизацию.',
        RemixIcons.link_m,
        '/assistant/$id/connectors',
      ),
      _SubItem(
        'Скрипты',
        'Определяйте сценарные события и действия: вход/выход, триггеры, обработчики. Описывайте логику автоматизации без изменения кода.',
        RemixIcons.file_code_line,
        '/assistant/$id/scripts',
      ),
      _SubItem(
        'Сценарии',
        'Здесь создаются и настраиваются сценарии общения с клиентом: шаги, вопросы, варианты ответов и логика переходов. Вы определяете, как именно ассистент будет вести диалог — от приветствия до оформления заявки.',
        RemixIcons.flow_chart,
        '/assistant/$id/dialogs',
      ),
      _SubItem(
        'Память ассистента',
        'Здесь вы задаёте, какую информацию должен собирать ассистент во время разговора: имя, адрес, тип услуги, описание проблемы и т. д. Эти данные заполняются автоматически в процессе диалога и используются для заявок и отчётов.',
        RemixIcons.brain_line,
        '/assistant/$id/slots',
      ),
      _SubItem(
        'Плэйграунд',
        'Плэйграунд для быстрой проверки работы ассистента: после изменения настроек можно смоделировать нужный диалог и посмотреть, как ассистент отрабатывает шаги, вопросы и логику.',
        RemixIcons.flask_line,
        '/assistant/$id/playground',
      ),
      _SubItem(
        'История чатов',
        'Здесь вы можете просматривать и анализировать прошедшие диалоги: искать по истории, фильтровать по статусу и дате, открывать детали переписки, прослушивать записи и быстро переходить к таймлайну для разбора.',
        RemixIcons.history_line,
        '/assistant/$id/sessions',
      ),
    ];

    return Scaffold(
      appBar: AssistantAppBar(assistantId: id),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w <= 480 ? 1 : (w <= 900 ? 2 : 3);
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            // Больше высоты для узких экранов и увеличенного масштаба текста
            double childAspectRatio = 1.9; // ширина/высота
            if (crossAxisCount == 2) {
              childAspectRatio = 1.6; // выше, чтобы поместились 2 строки
            }
            if (crossAxisCount == 1) {
              childAspectRatio = 1.2; // ещё выше в 1 колонку
            }
            if (textScale > 1.0) {
              childAspectRatio -=
                  0.3; // делаем карточку выше при крупном шрифте
              if (childAspectRatio < 1.05) childAspectRatio = 1.05;
            }
            // Пользователь просит уменьшить максимальную высоту карточки ~ в 1.5 раза =>
            // увеличиваем aspectRatio на 1.5x (чем больше ratio, тем ниже карточка),
            // но оставляем разумные ограничения.
            childAspectRatio *= 1.5;
            // Для 2 колонок добавим небольшой запас по высоте, чтобы не было переполнения
            if (crossAxisCount == 2) {
              childAspectRatio -= 0.08;
            }
            if (childAspectRatio > 3.2) {
              childAspectRatio =
                  3.2; // верхняя граница (слишком плоские карточки не нужны)
            }
            if (childAspectRatio < 1.1) {
              childAspectRatio = 1.1; // нижняя граница (не слишком высокие)
            }
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  it.subtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 3,
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
