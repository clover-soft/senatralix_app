### Шаг 10: Assistant — Scripts (моки, формы, валидация, локальное состояние)

- Цель:
  - Реализовать CRUD скриптов ассистента с локальными мок‑данными и валидацией.
  - Поддержать запуск скриптов по двум событиям: `on_dialog_start`, `on_dialog_end`.
  - Поддержать параметры скрипта (редактирование через UI список ключ/значение).
  - Скрипт представляет собой последовательность шагов: каждый шаг имеет JSONPath‑паттерн (условие) и действие (минимум HTTP GET/POST).

- Действия:
  0) Структура кода (обязательно)
  - Соблюдать модульную структуру подфичи: `features/assistant/features/scripts/{models,providers,widgets,screens}/`.
  - Экран(ы) — только композиция; редакторы/диалоги/конструктор шагов — в `widgets/`; модели — в `models/`; провайдеры — в `providers/`.

  1) Модель и провайдеры
  - Тип `Script`:
    - id: string (UUID)
    - name: string
    - enabled: boolean
    - trigger: enum("on_dialog_start", "on_dialog_end")
    - params: map<string, string> — пользовательские параметры, редактируемые через UI
    - steps: ScriptStep[]
  - Тип `ScriptStep`:
    - id: string (UUID)
    - when.jsonpath: string — JSONPath выражение (минимум — проверка на существование пути)
    - action: Action
  - Тип `Action`:
    - type: enum("http_get", "http_post")
    - http:
      - url: string
      - headers?: map<string, string>
      - query?: map<string, string> (для GET)
      - body_template?: string (для POST; шаблон JSON/текста)
  - Провайдер:
    - хранит список `Script` по assistantId
    - методы: list/add/update/remove, toggleEnabled(scriptId, enabled)
    - методы для шагов: addStep(scriptId, step), updateStep(scriptId, step), removeStep(scriptId, stepId)

  2) Экран UI (Scripts)
  - Список скриптов:
    - Показывать `name`, `trigger`, количество `steps`, переключатель `enabled`, кнопки Редактировать/Удалить.
  - Редактор скрипта (диалог или отдельный экран):
    - Поля: `name`, `trigger` (select: on_dialog_start|on_dialog_end), `params` (редактируемый список key/value)
    - Конструктор шагов:
      - Редактор `ScriptStep`: поля JSONPath и Action
      - Кнопки: Добавить шаг, Редактировать шаг, Удалить шаг
      - Редактор Action по типу:
        - http_get: url, headers (map), query (map)
        - http_post: url, headers (map), body_template (multiline)
    - Превью: краткое человеко‑читаемое описание (например: `on_dialog_start: 2 шага (GET /warmup, POST /summary)`).

  3) Валидация
  - name: 2–60 символов
  - trigger: обязателен (только on_dialog_start|on_dialog_end)
  - params: ключ 1–40, значение — строка
  - steps: ≥ 1
  - when.jsonpath: обязателен (строка)
  - action:
    - http_get: url обязателен; headers/query — словари строк
    - http_post: url обязателен; body_template — строка; headers — словарь строк

  4) Пресеты (опционально)
  - Для ускорения UX добавить пресеты в `features/assistant/features/scripts/data/script_presets.dart`, например:
    - «Старт: GET /warmup» (trigger = on_dialog_start, 1 шаг: http_get)
    - «Завершение: POST /summary» (trigger = on_dialog_end, 1 шаг: http_post)

- Ожидаемый результат:
  - Подфича Scripts с CRUD и редактором последовательностей шагов, локальное хранение (моки).
  - Модульная структура, диалоги/редакторы вынесены в `widgets/`.
  - Без интеграции с backend — только локальное состояние в провайдере.

  4) Сохранение
  - Сохранять правило в провайдер; показывать snackbar об успехе.

- Ожидаемый результат:
  - Конструктор правил с базовыми действиями, локальным сохранением и валидаторами.

- Критерии готовности (Definition of Done):
  - CRUD правил и включение/выключение.
  - Валидация форм действий и событий.
  - Документация обновлена, коммит и push выполнены.

- Тесты (не используются):
  - Ручная проверка сценариев on_enter/on_leave/on_trigger и выполнения последовательности действий (на уровне мока — логировать в консоль/стейт).

- Зависимости/примечания:
  - Полезно согласовать с инструментами из шага 7 (transferCall/hangup).

- Риски:
  - Рост сложности конструктора — на первом шаге ограничиваемся простыми действиями и плоскими параметрами.

Выполнено: в процессе
