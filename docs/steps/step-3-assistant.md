### Шаг 3: Assistant — выбор ассистента и маршруты с :assistantId (вариант A)

- Цель: 
  - Ввести экран выбора ассистента на маршруте `/assistant`.
  - Перейти на маршруты подфич с параметром: `/assistant/:assistantId/<sub>`.

- Действия:
  - Обновить роутинг:
    - В `lib/features/assistant/assistant_routes.dart` добавить маршруты:
      - `/assistant` — хаб выбора ассистента (список, добавить/удалить).
      - `/assistant/:assistantId` — экран ассистента (локальное меню подфич или редирект на дефолтную).
      - `/assistant/:assistantId/{settings|tools|knowledge|connectors|scripts|chat|sessions}` — экраны подфич.
  - Экран выбора ассистента:
    - Обновить `lib/features/assistant/screens/assistant_screen.dart` на список ассистентов (заглушка) + кнопки “Добавить”, “Удалить”.
    - При выборе ассистента — переход на `/assistant/:assistantId` (или сразу на дефолтную подфичу, например `settings`).
  - Провайдеры и модели:
    - Создать модель `Assistant { id, name }` в `lib/features/assistant/models/assistant.dart`.
    - Создать `assistantListProvider` (StateNotifier) для CRUD (заглушки локально).
    - В `assistant/di.dart` расширить `AssistantService` заглушками: `listAssistants()`, `createAssistant()`, `deleteAssistant(id)`, `renameAssistant(id, name)` с использованием `apiClientProvider` (позже интеграция с backend).
  - Подфичи:
    - Обновить экраны подфич на чтение `assistantId` из `GoRouterState` (`state.pathParameters['assistantId']`).
    - Временный вывод `assistantId` на экранах для проверки.
  - Меню:
    - Пункт `assistant` в `kMenuRegistry` оставляем ведущим на `/assistant` (хаб выбора).
    - Внутри `AssistantScreen` — навигация по подфичам выбранного ассистента.

- Ожидаемый результат:
  - На `/assistant` пользователь видит список ассистентов, может добавить/удалить (локально, без API).
  - Переходы на подфичи с адресами `/assistant/:assistantId/<sub>` работают без ошибок.

- Критерии готовности (Definition of Done):  
  - Роутинг обновлён, переходы по всем маршрутам работают.
  - Экран выбора ассистента отображает список и выполняет CRUD локально (заглушки).
  - Подфичи принимают и используют `assistantId`.
  - Документация обновлена, коммит и push выполнены.

- Тесты (не используются):  
  - Пользователь самостоятельно проводит тестирование.

- Зависимости/примечания:
  - Используем текущий `ApiClient` через `apiClientProvider`.
  - Реальный backend CRUD — в следующем шаге, сейчас локальные заглушки.

- Риски:
  - Несогласованность URL и состояния — минимизируем, делая `assistantId` частью URL и читая его в провайдерах/экранах.

Выполнено: да
