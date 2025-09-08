### Шаг 7: Assistant — Tools (моки, формы, валидация, локальное состояние)

- Цель:
  - Реализовать экран инструментов ассистента (включение/настройка) с локальными мок‑данными и валидацией.
  - Сохранять изменения в модель риверпода (провайдер состояния ассистента).

- Действия:
  1) Модель и провайдеры
  - По `docs/assistant.json.settings.tools` фиксируем ОДИН тип инструмента — Function tool (настраиваемый):
    - function.name: string (обяз.)
    - function.description: string (обяз.)
    - function.parameters: JSON Schema (object):
      - type: "object" (обяз.)
      - properties: map<string, propertySchema>
      - required: string[] (имена обязательных полей)
  - В провайдере хранить список function‑tools по assistantId, методы: list/add/update/remove, toggleEnabled.
  - Примечание: активация баз знаний (search index) выполняется В ПОДФИЧЕ Knowledge, а не в Tools.

  2) Экран UI (Tools)
  - Табличный/карточный список инструментов с типом и кратким описанием.
  - Кнопки: Добавить Function, Редактировать, Удалить, Включить/Выключить.
  - Редактор Function:
    - Поля: name, description, параметры (минимальный редактор JSON Schema: key, type, description, required[]).
    - Пресеты из примеров: transferCall, hangupCall (см. `assistant.json.settings.tools`).

  3) Валидация
  - name: 2–40 символов.
  - description: до 280 символов (минимум 1 символ).
  - parameters (JSON Schema):
    - type == "object".
    - required ⊆ keys(properties).
    - properties.*.type ∈ {string, number, integer, boolean, object, array}.

  4) Сохранение
  - Все изменения сохранять в провайдер по assistantId.
  - Snackbars об успехе и подтверждения удаления.

- Ожидаемый результат:
  - Экран инструментов с CRUD инструментов (в рамках моков) и валидацией, без интеграции с API.

- Критерии готовности (Definition of Done):
  - Редакторы для SearchIndex и Function работают, защита от невалидных схем.
  - Состояние хранится в риверпод‑провайдере, применяется в UI.
  - Документация обновлена, коммит и push выполнены.

- Тесты (не используются):
  - Ручная проверка добавления/редактирования/удаления и включения/выключения инструментов.

- Зависимости/примечания:
  - Структура взята из `docs/assistant.json` (settings.tools).

- Риски:
  - Сложность UX редактора JSON Schema — начнём с упрощённого редактора (тип, описание, required), вложенные типы отложим.

Выполнено: в процессе
