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
- Сеть: `ApiClient` (Dio) с cookie‑auth на Web.

## Последние изменения
- Подготовлен отчет «Шаг 1: Исследование проекта» (`docs/steps/step-1-research.md`).
- Выявлены первоочередные улучшения: конфигурация окружений, логирование/ошибки, валидация меню.

## Текущий шаг разработки
- Шаг 1: Исследование проекта — в процессе.

