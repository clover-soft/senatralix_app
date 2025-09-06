### Шаг 1: Исследование проекта

- Цель: понять архитектуру, ключевые сущности, риски, точки развития
- Действия: анализ `lib/`, `pubspec.yaml`, конфигурации, зависимостей и навигации/состояния
- Ожидаемый результат: структурированный отчет (см. разделы ниже)
- Критерии готовности (Definition of Done):
  * Подготовлен отчет с разделами из "Формат вывода"
  * Обновлен docs/project_context.md
  * Обновлен docs/solutions_and_changes.md (раздел “Решения и изменения”)
- Выполнено: да

---

## Краткое резюме

- Используется Flutter 3.8+, состояние на `flutter_riverpod`, навигация на `go_router`.
- Точка входа `lib/main.dart` и единый роутер `lib/core/router/app_router.dart` с `ShellRoute` и редиректами по auth-state.
- Тема оформлена через `lib/core/theme/app_theme.dart` с кастомным шрифтом Akrobat из `pubspec.yaml`.
- Сеть: лёгкий клиент `lib/data/api/api_client.dart` на `dio` + web cookies (`withCredentials`).
- Авторизация и контекст: `lib/data/providers/auth_data_provider.dart` и `lib/data/providers/context_data_provider.dart` (инициализация, реакции на login/logout, загрузка меню из контекста).
- Меню: статический реестр `lib/shared/navigation/menu_registry.dart`; динамика из контекста собирает список ключей и сортировку.
- Провайдер shell-UI: `lib/shared/providers/shell_provider.dart` (состояние разворота левой навигации).
- Качество: `analysis_options.yaml` подключает `flutter_lints`; в логировании используются `print`; codegen/i18n не обнаружены.
- Риски: жестко задан `baseUrl` API, слабая обработка ошибок/ретраев, отсутствуют environment-конфиги и централизованный логгер.
- Роадмап: вынести конфиг, улучшить логирование/ошибки, связать меню контекста с `kMenuRegistry`, документировать архитектуру.

## Диаграмма архитектуры (high‑level) и карта модулей

- Приложение (`lib/main.dart`) → инициализация `ProviderContainer`, создание роутера → `MaterialApp.router`.
- Ядро (`lib/core/`):
  - Роутер: `lib/core/router/app_router.dart` → `createAppRouter()` строит `GoRouter` с `ShellRoute` (общий `AppShell`).
  - Тема: `lib/core/theme/app_theme.dart` → `AppTheme` и `AppThemeMode`.
  - Хранилище: `lib/core/storage/app_storage.dart` (заготовка под инициализацию).
- Данные (`lib/data/`):
  - Сеть: `lib/data/api/api_client.dart` (`Dio`, interceptors, `setAuthToken`).
  - Провайдеры: `lib/data/providers/auth_data_provider.dart`, `lib/data/providers/context_data_provider.dart` (работают через сервисы `auth_service.dart`, `context_service.dart`).
- Фичи (`lib/features/`):
  - Дашборд: `lib/features/dashboard/screens/dashboard_screen.dart`.
  - Профиль: `lib/features/profile/...` (есть провайдер профиля с TODO).
  - Auth/Registration/Splash: подключены в роутере.
- Общие компоненты (`lib/shared/`):
  - Меню: `lib/shared/navigation/menu_registry.dart`.
  - Провайдеры shell: `lib/shared/providers/shell_provider.dart`.
  - Оболочка: `lib/shared/widgets/app_shell/app_shell.dart` (используется в роутере).

Текстовая схема:

Core(router, theme, storage)
  → Data(api_client, providers)
    → Features(dashboard, profile, auth, registration)
      → Shared(app_shell, menu_registry, shell_provider)
        → UI (MaterialApp.router)

## Список ключевых файлов и классов

- `lib/main.dart` → класс `SentralixApp`, функция `main()`; подключает тему `AppTheme` и роутер `GoRouter`.
- `lib/core/router/app_router.dart` → функция `createAppRouter(ProviderContainer)`, `ShellRoute` с `AppShell`, маршруты `'/'`, `'/profile'`, `'/auth/login'`, `'/registration'`, `'/splash'`; редиректы по `AuthState`.
- `lib/core/theme/app_theme.dart` → класс `AppTheme` и `ThemeExtension` `CustomColors`; установка шрифта Akrobat, стили для `NavigationRail`, `AppBar`.
- `lib/core/storage/app_storage.dart` → класс `AppStorage` (заготовка, метод `onAppInit()`).
- `lib/data/api/api_client.dart` → класс `ApiClient` (`get/post/patch`, interceptors, `setAuthToken`, логирование, `BrowserHttpClientAdapter` для Web).
- `lib/data/providers/auth_data_provider.dart` → `AuthDataProvider` (инициализация через `/me`, `login`, `logout`, `refresh`) и провайдер `authDataProvider`.
- `lib/data/providers/context_data_provider.dart` → `ContextDataProvider` (загрузка `subscription`, `domains`, парсинг `subscription.settings.menu`, реакции на смену пользователя) и провайдер `contextDataProvider`.
- `lib/features/dashboard/screens/dashboard_screen.dart` → `DashboardScreen` (читает `authDataProvider`, вызывает `logout`).
- `lib/shared/navigation/menu_registry.dart` → `MenuDef` и `kMenuRegistry` (ключ→маршрут/иконки/лейбл для `dashboard`, `reports`, `profile`).
- `lib/shared/providers/shell_provider.dart` → `shellRailExpandedProvider` (`StateProvider<bool>`; отвечает за разворот NavigationRail).

## Навигация и модульность

- Роутер: `lib/core/router/app_router.dart` строит `GoRouter` с `ShellRoute` (общий каркас `AppShell` в `lib/shared/widgets/app_shell/app_shell.dart`), дочерние пути `'/'`, `'/profile'`.
- Редиректы завязаны на `authDataProvider` (через `refreshListenable`) и учитывают `'/splash'`, `'/auth/login'`, `'/registration'` + параметр `from` для возврата после логина.
- Меню: статическая регистрация `kMenuRegistry` (`lib/shared/navigation/menu_registry.dart`) и динамический список ключей из контекста (`ContextDataProvider.state.menu`). Связка предполагается по `key`.
- Контракты экранов: параметры не используются (страницы без аргументов); deeplink-стратегия — стандартные пути `GoRouter`.

## Сеть, данные и конфигурация

- Клиент: `lib/data/api/api_client.dart` → `Dio` с `baseUrl: https://api.sentralix.ru`, таймауты, заголовки, cookies для Web, перехватчики с измерением времени и укороченным выводом тела.
- Токен: `setAuthToken(String?)` обновляет заголовок `Authorization`.
- Сервисы: провайдеры зависят от `lib/data/api/services/auth_service.dart` и `lib/data/api/services/context_service.dart` (по импортам). Маппинг DTO→состояние делается вручную в провайдерах.
- Локальное хранилище: `lib/core/storage/app_storage.dart` — пока заготовка.
- Конфиги окружений: `lib/core/config.dart` пуст, `.env`/flavors не обнаружены.

Слои: Client(Dio) → Service(auth/context) → Provider(ChangeNotifier) → UI(ConsumerWidget/Shell/Routes).

## Качество: линтеры, ошибки, логирование, perf

- Линтеры: `analysis_options.yaml` подключает `flutter_lints` (настройки по умолчанию).
- Логирование: в API-клиенте и `ContextDataProvider`/роутере используются `print`. Централизованного логгера/уровней логов нет.
- Ошибки: перехват в `ApiClient` маппит `DioException` в `ApiException`, однако в UI нет унифицированного отображения ошибок.
- Производительность: потенциальные точки — многократные `print`, отсутствие мемоизации в провайдерах. Тяжелых синхронных операций в UI не обнаружено.

## Зависимости и риски

- Важные пакеты: `go_router`, `flutter_riverpod`, `dio`, `dio_web_adapter`, `flutter_secure_storage`, `flutter_screenutil`, `share_plus`, `path_provider`.
- Риски:
  - Жесткий `baseUrl` в `ApiClient` → сложность смены окружения.
  - Отсутствие `.env`/flavors/`core/config.dart` (пуст) → конфиги неразделены по средам.
  - Логирование через `print` → шум/падение производительности, нет уровней/структуры логов.
  - Обработка ошибок не унифицирована в UI.
  - Связка меню контекста и `kMenuRegistry` не валидируется (несоответствие ключей приведет к "мертвым" пунктам).

## Рекомендации и roadmap (15–60 мин на шаг)

1) Конфигурация окружений (30–45 мин)
- Вынести `baseUrl` в `core/config.dart` и/или `.env`; добавить чтение в рантайме.
- Подготовить заглушки для `dev/stage/prod`.

2) Логирование и ошибки (30–45 мин)
- Заменить `print` на простой логгер (например, `logger` или свой `Log.d/i/w/e`).
- Центрально перехватывать ошибки в провайдерах и отображать snackbars/диалоги.

3) Меню и маршруты (30–60 мин)
- Валидировать ключи меню из контекста против `kMenuRegistry`; добавить fallback/скрытие.
- Документировать соответствие `key → route` и расширение `kMenuRegistry`.

4) Документация (15–30 мин)
- Заполнить `docs/project_context.md` (краткое описание, архитектура, текущий шаг) и `docs/solutions_and_changes.md` (решения, риски).

## Приложения

### Глоссарий
- AppShell — общий каркас приложения (верх/лево), см. `lib/shared/widgets/app_shell/app_shell.dart`.
- ProviderContainer — контейнер состояний Riverpod, инициализируется в `lib/main.dart`.
- Context — серверный контекст подписки/доменов/меню, загружается в `ContextDataProvider`.

### Список TODO/FIXME
- `lib/features/profile/providers/profile_provider.dart:28` — `// TODO: integrate with real API`.

---

Источники/цитаты (примеры):
- `lib/shared/navigation/menu_registry.dart` → константа `kMenuRegistry`, класс `MenuDef`.
- `lib/shared/providers/shell_provider.dart` → провайдер `shellRailExpandedProvider`.
- `lib/core/router/app_router.dart` → функция `createAppRouter`, `ShellRoute`, редиректы.
- `lib/data/api/api_client.dart` → класс `ApiClient`, методы `get/post/patch`, `setAuthToken`.
- `lib/features/dashboard/screens/dashboard_screen.dart` → класс `DashboardScreen`.
