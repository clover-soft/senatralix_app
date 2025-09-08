### Шаг 5: Assistant — навигация назад, хлебные крошки и корректный deep-link роутинг (Web)

- Цель:
  - Сделать предсказуемую навигацию в надфиче Assistant: возврат к списку ассистентов и возврат к локальному меню ассистента.
  - Добавить хлебные крошки на широких экранах.
  - Обеспечить корректный переход по адресной строке браузера (deep-link) на Web по путям `/#/assistant/:assistantId/...` без редиректа в корень.

- Действия:
  1) Кнопка возврата (leading) в AppBar
  - `AssistantHomeScreen` (`lib/features/assistant/screens/assistant_home_screen.dart`):
    - Добавить `AppBar.leading` со стрелкой назад → `context.go('/assistant')`.
  - Подфичи (`lib/features/assistant/features/*/screens/*_screen.dart`):
    - Добавить `AppBar.leading` со стрелкой назад → `context.go('/assistant/:assistantId')` (подставлять id из `GoRouterState`).
    - В `AppBar.actions` добавить иконку "домой ассистента" (`Icons.home_outlined`) с переходом на `/assistant/:assistantId`.

  2) Хлебные крошки на широких экранах (только Web/ширина ≥ 900)
  - `AssistantHomeScreen` и подфич-экраны:
    - В `AppBar.title` отрисовать breadcrumb:
      - `Assistant` → `/assistant`
      - `<Имя ассистента>` → `/assistant/:assistantId`
      - `Settings|Tools|...` → текущая страница (неактивна)
    - Определять ширину через `LayoutBuilder` или `MediaQuery.sizeOf(context).width`.
    - Крошки делать кликабельными (InkWell/TextButton) с `context.go(...)`.

  3) Корректный deep-link роутинг на Web
  - Задача: адрес вида `https://app.sentralix.ru/#/assistant/stub-1/settings` должен открывать нужный экран, а не редиректить в корень.
  - Проверить и настроить `GoRouter` и стратегию URL:
    - В `main.dart`/инициализации роутера убедиться, что используется `HashUrlStrategy` для Web (или оставить по умолчанию, если уже так).
    - Убедиться, что `createAppRouter` не делает преждевременных редиректов до того, как `GoRouterState` инициализирован (особенно при `auth.ready == false`).
    - В `redirect` (`lib/core/router/app_router.dart`) обеспечить корректное поведение при первом заходе по deep-link:
      - Если `!auth.ready` → временно показывать `/splash`, но после готовности вернуться на изначальный `state.uri` (не теряя выбранный путь). Для этого не затирать `from`, если он уже есть, и не переписывать путь на `/`.
      - Проверить условия для `isAuthRoute`/`isSplash`/`isRegistration` так, чтобы deep-link на `/assistant/...` для залогиненного пользователя не редиректил в корень.
    - Для Web-оболочки (index.html/хостинг) — хэш-маршруты не требуют дополнительной конфигурации сервера, поэтому удерживаемся от `PathUrlStrategy` на данном этапе.

  4) Минорный UX
  - В `AssistantHomeScreen` добавить подсказку (tooltip) на стрелку и кнопку "домой" в подфичах.
  - Для крошек применить приглушённые цвета (`onSurfaceVariant`) и `TextButton.styleFrom(visualDensity: VisualDensity.compact)`.

- Ожидаемый результат:
  - На `/assistant/:assistantId` в AppBar есть стрелка назад к списку.
  - На подфичах — стрелка назад и кнопка "домой ассистента".
  - На ширине ≥ 900px видны хлебные крошки с кликабельными сегментами.
  - Ввод адреса вида `/#/assistant/<id>/settings` в браузере открывает нужный экран без редиректа в корень.

- Критерии готовности (Definition of Done):
  - Leading-кнопки реализованы и работают во всех целевых экранах.
  - Breadcrumb отрисовывается на широких экранах и корректно ведёт по маршрутам.
  - Deep-link по `/#/assistant/:assistantId/...` открывает нужный экран (ручная проверка).
  - Документация обновлена, коммит и push выполнены.

- Тесты (не используются):
  - Ручная проверка ссылок и навигации (Web/мобилки), проверка возвратов и крошек.

- Зависимости/примечания:
  - При работе с `redirect` в `GoRouter` избегать перезаписи `state.uri` на `/` во время начальной загрузки.
  - При желании позже перейти на `PathUrlStrategy` — потребуется серверная настройка для SPA.

- Риски:
  - Неправильный редирект при старте из-за флага `auth.ready` — проверка логики при deep-link обязательна.

Выполнено: в процессе
