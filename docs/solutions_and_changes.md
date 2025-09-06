# Решения и изменения

## Архитектурные решения (текущее состояние)

- Навигация: `go_router` с `ShellRoute` и централизованными редиректами по `AuthState` (`lib/core/router/app_router.dart`).
- Состояние: `flutter_riverpod` (в основном `ChangeNotifierProvider`) для `authDataProvider`, `contextDataProvider`, `shellRailExpandedProvider`.
- Сеть: `Dio` обёрнут в `ApiClient` (`lib/data/api/api_client.dart`) с cookie‑auth на Web и перехватчиками логов.
- Тема/шрифт: `AppTheme` (`lib/core/theme/app_theme.dart`) с кастомным шрифтом Akrobat из `pubspec.yaml`.
- Меню: статический реестр `kMenuRegistry` (`lib/shared/navigation/menu_registry.dart`) и динамика из серверного контекста (`ContextDataProvider`).

## Обнаруженные риски и долги

- Жесткий `baseUrl` в `ApiClient` → нет разделения окружений.
- Нет `.env`/flavors, `lib/core/config.dart` пуст → сложно конфигурировать без правок кода.
- Логирование через `print` → нет уровней/структурности, лишний шум.
- Обработка ошибок в UI не унифицирована.
- Возможное несоответствие ключей меню между контекстом и `kMenuRegistry`.

## Рекомендуемые изменения (план)

1. Конфигурация окружений: вынести `baseUrl` в `core/config.dart`/`.env`, поддержать `dev/stage/prod`.
2. Логирование: заменить `print` на простой логгер/утилиту, добавить уровни и отключение в проде.
3. Меню/маршруты: валидировать ключи и скрывать неизвестные, документировать расширение `kMenuRegistry`.
4. Ошибки: централизованное отображение ошибок (snackbar/диалоги) и единый формат сообщений.

## Ссылки на изменения/файлы

- Отчёт: `docs/steps/step-1-research.md`.
- Контекст: `docs/project_context.md`.

## Последние изменения (UX/Theme, AppShell, NavigationRail)

- Перевод темы на Material 3 и палитру `ColorScheme.fromSeed` в `lib/core/theme/app_theme.dart`.
  - Включён `useMaterial3: true`.
  - Цвета компонентов берутся из `Theme.of(context).colorScheme` (primary/secondary/surface и др.).
  - Убраны жёсткие константы цветов для AppBar/NavigationRail/Card; теперь используются токены схемы.
- AppBar: фон = `scheme.primary`, тексты/иконки = `scheme.onPrimary`.
- NavigationRail тема: индикатор = `scheme.secondaryContainer`, активные/неактивные стили через `scheme.secondary`/`scheme.onSurfaceVariant`.
- `AppShellLeading` (`lib/shared/widgets/app_shell/app_shell_leading.dart`):
  - Фон синхронизирован с AppBar (`scheme.primary`).
  - Текст/иконка — `scheme.onPrimary` (локальный `NavigationRailTheme`).
  - Выравнивание по вертикали через `Transform.translate(0, -6)`.
  - По нажатию — переключение `shellRailExpandedProvider` (expand/collapse NavigationRail).
- `AppShellRailItem` (`lib/shared/widgets/app_shell/app_shell_rail_item.dart`):
  - Переход на токены `ColorScheme` по умолчанию (без `Colors.*`).
- `AppShell` (`lib/shared/widgets/app_shell/app_shell.dart`):
  - Удалён «служебный» первый пункт в `destinations`; индексация пересчитана без смещений (+1) — исправлен падение `selectedIndex` assert.
  - `leading` смещён вверх на 8px для компенсации внутреннего отступа `NavigationRail`.

Примечание: смена `seedColor` теперь перекрашивает AppBar, NavigationRail и кнопки, кроме мест, где намеренно оставлены явные override‑ы в теме.
