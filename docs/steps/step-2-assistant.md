### Шаг 2: Фича Assistant — каркас фичи и подфич (роутер, меню, заглушки)

- Цель: создать фичу `assistant` со своим внутренним роутером и меню (заглушки), обеспечить переходы на подфичи и подготовить каркас (экраны, провайдеры, модели) для каждой подфичи.
- Действия:
  - Создать структуру `lib/features/assistant/` с поддиректорией `features/{settings,tools,knowledge,connectors,scripts,chat,sessions}`.
  - Добавить внутренний роутер `assistant_routes.dart` и подключить его в `ShellRoute` (`lib/core/router/app_router.dart`).
  - Добавить пункт меню-заглушку в `kMenuRegistry` (`lib/shared/navigation/menu_registry.dart`) с маршрутом `/assistant`.
  - Создать экран и каркас для надфичи: `screens/assistant_screen.dart`, каталоги `widgets/` (пока пусто), `providers/`, `models/`.
  - Создать заглушечные экраны и каркас (`providers/`, `models/`, `widgets/` пустые) для подфич: `settings`, `tools`, `knowledge`, `connectors`, `scripts`, `chat`, `sessions`.
  - Связать провайдеры подфич с надфичей (через провайдеры в `assistant/di.dart`) и предусмотреть прокидывание `ApiClient` через глобальный `apiClientProvider`.
- Ожидаемый результат: в приложении появляется фича `assistant`: есть экран фичи, внутренний роутер, пункт меню-заглушка, переходы на экраны подфич (заглушки), созданы провайдеры и модели (заготовки) для фичи и подфич.
- Критерии готовности (Definition of Done):
  * Встроен внутренний роутер `assistant_routes.dart` и подключён к `AppRouter` (внутри `ShellRoute`).
  * Добавлен пункт меню `assistant` в `kMenuRegistry`.
  * Создан экран фичи и заглушечные экраны подфич; переходы работают.
  * Созданы заготовки `providers/` и `models/` для фичи и каждой подфичи.
  * Документация обновлена (этот файл) и при необходимости `docs/project_context.md`, `docs/solutions_and_changes.md`.
- Выполнено: в процессе

---

## Детализация подфич

- Настройки (`settings`): основные настройки (промпт, температура, модель, ограничение по токенам).
- Инструменты (`tools`): пользовательские названия инструментов ассистента (что ассистент может вызывать).
- База знаний (`knowledge`): загрузка и управление базой знаний администратором.
- Коннекторы (`connectors`): интеграции (VOIP, в перспективе Telegram/Avito/WhatsApp и др.).
- Скрипты (`scripts`): сценарии на события (вход/выход из диалога, триггеры по словам/параметрам и т.п.).
- Чат (`chat`): чат с ассистентом для тестирования работы.
- Сессии (`sessions`): пользовательские названия тредов.

## Навигация

- Маршруты фичи `assistant`:
  - `/assistant`
  - `/assistant/settings`
  - `/assistant/tools`
  - `/assistant/knowledge`
  - `/assistant/connectors`
  - `/assistant/scripts`
  - `/assistant/chat`
  - `/assistant/sessions`
- Меню: добавить пункт `assistant` (иконка `smart_toy`) в `kMenuRegistry` → ведёт на `/assistant`.
- Внутри экрана `assistant` предусмотреть список переходов на подфичи (пока как заглушки-кнопки).

## Провайдеры и DI

- Глобальный провайдер API: `lib/data/api/api_client_provider.dart` с `apiClientProvider` (если отсутствует — создать).
- Надфича `assistant`: `lib/features/assistant/di.dart` — общие провайдеры (сервисы/репозитории) на базе `apiClientProvider`.
- Подфичи: в `features/<sub>/providers/` провайдеры читают зависимости надфичи (или непосредственно `apiClientProvider` при необходимости).

## Структура каталогов (пример)

```
lib/features/assistant/
  assistant_feature.dart
  assistant_routes.dart
  di.dart
  screens/assistant_screen.dart
  widgets/
  providers/
  models/
  features/
    settings/
      screens/settings_screen.dart
      providers/settings_provider.dart
      models/
      widgets/
    tools/
      screens/tools_screen.dart
      providers/tools_provider.dart
      models/
      widgets/
    knowledge/
      screens/knowledge_screen.dart
      providers/knowledge_provider.dart
      models/
      widgets/
    connectors/
      screens/connectors_screen.dart
      providers/connectors_provider.dart
      models/
      widgets/
    scripts/
      screens/scripts_screen.dart
      providers/scripts_provider.dart
      models/
      widgets/
    chat/
      screens/chat_screen.dart
      providers/chat_provider.dart
      models/
      widgets/
    sessions/
      screens/sessions_screen.dart
      providers/sessions_provider.dart
      models/
      widgets/
```

## Пример (JSON) — список маршрутов и пункт меню

```json
{
  "routes": [
    "/assistant",
    "/assistant/settings",
    "/assistant/tools",
    "/assistant/knowledge",
    "/assistant/connectors",
    "/assistant/scripts",
    "/assistant/chat",
    "/assistant/sessions"
  ],
  "menu_stub": { "key": "assistant", "route": "/assistant" }
}
```

## Тесты (не используются)
- Пользователь самостоятельно проводит тестирование.

## Зависимости/примечания
- Использовать существующий `ApiClient` (`lib/data/api/api_client.dart`) через `apiClientProvider`.
- Конфиги окружений не трогаем (будут в отдельном шаге).
- Цвета/стили — через `Theme.of(context).colorScheme` (Material 3).

## Риски
- Рост связности между подфичами — смягчать через провайдеры надфичи и barrel-файлы; избегать прямых импортов подфич друг в друга.
- Временные заглушки — оставить без сетевых вызовов, чтобы не блокировать интеграцию.
