# Контекст проекта

- Краткое описание: Web‑приложение на Flutter с авторизацией, общим shell‑интерфейсом (NavigationRail + AppBar), роутингом на `go_router` и состоянием на `flutter_riverpod`.
- Архитектура (high‑level):
  - `lib/main.dart` — инициализация `ProviderContainer`, запуск `MaterialApp.router` с темой `AppTheme` и конфигурацией `GoRouter`.
  - `lib/core/` — роутер (`core/router/app_router.dart`), тема (`core/theme/app_theme.dart`), хранилище (`core/storage/app_storage.dart`), конфиг (`core/config.dart`).
  - `lib/data/` — сеть (`data/api/api_client.dart`), провайдеры (`data/providers/*`).
  - `lib/features/` — экраны и логика фич (dashboard, profile, auth, registration).
  - `lib/shared/` — shell, меню, общие провайдеры.
- Навигация: `ShellRoute` с `AppShell`, страницы `'/'`, `'/profile'`, `'/auth/login'`, `'/registration'`, `'/splash'`; редиректы зависят от `AuthState`.
- Состояние: Riverpod (`ChangeNotifierProvider`) — `authDataProvider`, `contextDataProvider`, `shellRailExpandedProvider`.
- Тема/шрифт: `AppTheme` + Akrobat из `pubspec.yaml`.
  - Включён Material 3 (`useMaterial3: true`).
  - Палитра строится через `ColorScheme.fromSeed` (см. `lib/core/theme/app_theme.dart`).
- Сеть: `ApiClient` (Dio) с cookie‑auth на Web.

## Последние изменения
- Подготовлен и завершён отчет «Шаг 1: Исследование проекта» (`docs/steps/step-1-research.md`).
- Миграция темы на Material 3 и `ColorScheme.fromSeed`; замена жёстких цветов на токены схемы.
- AppShell/NavigationRail: фиксация индексации `selectedIndex` после удаления служебного пункта, синхронизация цвета `leading` с AppBar, выравнивания через `Transform.translate`.
- В `AppShellLeading` по нажатию реализован toggle расширения рейла через `shellRailExpandedProvider`.
- Шаг 2: создан каркас фичи `assistant` с внутренним роутером (`assistant_routes.dart`), экраном (`assistant_screen.dart`), DI (`assistant/di.dart`) и подфичами-заглушками (`settings`, `tools`, `knowledge`, `connectors`, `scripts`, `chat`, `sessions`). Добавлен пункт меню `assistant`.
- Шаг 3: реализован выбор ассистента на `/assistant`, локальное меню подфич (`assistant_home_screen.dart`), маршруты `/assistant/:assistantId/*`, стартовый ассистент «Екатерина», подфичи читают `assistantId` из маршрута.
- Шаг 4: UX‑улучшения ассистента — модель `Assistant.description`, FAB/кнопка создания, диалоги с валидацией, AppBar по имени, подзаголовки карточек, адаптивная сетка (1/2/3), обработка overflow и уменьшение высоты карточек.
 - Шаг 6: Реализована подфича Settings с формой, валидацией и локальным провайдером (`assistant_settings_provider`).
 - Шаг 7: Реализована подфича Tools (Function‑tools): CRUD, пресеты, редактор параметров (JSON Schema); провайдер `assistant_tools_provider`.

## Текущий шаг разработки
- Шаг 6–7: выполнены.
- Следующий: Шаг 8 — Knowledge (CRUD источников, активация, валидация; локальный провайдер).


