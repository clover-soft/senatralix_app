### Шаг 10: Assistant — Bootstrap из бэкенда (настройки + список ассистентов)

- Цель: 
  - При входе в надфичу Assistant загрузить настройки надфичи и список ассистентов с бэкенда.
  - Отобразить индикатор загрузки/ошибки, после — UI со свежими данными.

- Действия: 
  - Создать `AssistantApi` с методами:
    - GET https://api.sentralix.ru/assistants/settings/ → `AssistantFeatureSettings`
    - GET https://api.sentralix.ru/assistants/list/ → `List<Assistant>`
  - DI:
    - `assistantApiProvider = Provider<AssistantApi>`
    - `assistantBootstrapProvider = FutureProvider<void>`: грузит `settings` и `assistants` параллельно, кладёт в:
      - `assistantFeatureSettingsProvider.set(settings)`
      - `assistantListProvider.replaceAll(assistants)`
  - UI:
    - На экранах надфичи (`/assistant`, `/assistant/:assistantId/*`) сначала `ref.watch(assistantBootstrapProvider)`:
      - loading — прогресс‑индикатор (например, `Center(child: CircularProgressIndicator())`)
      - error — сообщение и кнопка Retry (`ref.refresh(assistantBootstrapProvider)`)
      - data — текущий UI
  - Кнопка обновления/Retry: рефреш провайдера.
  - Использование настроек:
    - `allowedModels` → dropdown модели в настройках ассистента
    - `connectors.dictors` → dropdown `voice` в коннекторе
    - лимиты: уже применены (ассистенты/скрипты/инструменты)

- Ожидаемый результат: 
  - Данные грузятся при первом входе; пользователь видит прогресс и ошибки; UI использует настройки из бэкенда.

- Критерии готовности (Definition of Done):  
  - Индикатор загрузки и обработка ошибок есть.  
  - Заполнение провайдеров данными из бэкенда.  
  - Кнопка «Обновить» работает.  
  - Документация обновлена, коммит и push выполнены.

- Тесты (не используются): 
  - Ручная проверка: отключение сети, задержка, успешная загрузка.

- Примеры (ручки бэкенда):
  - GET `https://api.sentralix.ru/assistants/settings/` → `AssistantFeatureSettings`
  - GET `https://api.sentralix.ru/assistants/list/` → `Assistant[]`

- Зависимости/примечания: 
  - Авторизация и базовый клиент — существующий `ApiClient`.

- Риски: 
  - Медленная сеть/ошибки — не блокировать навигацию, отображать понятные сообщения.

Выполнено: в процессе
