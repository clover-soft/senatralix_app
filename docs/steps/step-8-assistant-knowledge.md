### Шаг 8: Assistant — Knowledge (моки, формы, валидация, локальное состояние)

- Цель:
  - Реализовать экран базы знаний ассистента: список источников, добавление/редактирование, статусы — с мок‑данными и валидацией.
  - Сохранять изменения в модель риверпода (провайдер состояния по assistantId).

- Действия:
  1) Модель и провайдеры
  - По `docs/knowledge_base.json` описать тип `KnowledgeBaseItem`:
    - id: number
    - external_id: string (используется для связи с инструментом SearchIndex)
    - markdown: string (контент)
    - settings:
      - max_chunk_size_tokens: number
      - chunk_overlap_tokens: number
      - ttl_days: number
      - expiration_policy: enum("since_last_active", "fixed_date" — на будущее)
    - created_at, updated_at: string (ISO)
  - Провайдер: список источников по assistantId, CRUD: list/add/update/remove, и флаги состояния: isLoading/isSaving.

  2) Экран UI (Knowledge)
  - Карточки источников: заголовок (отрезок из markdown), external_id, дата.
  - Кнопки: Добавить источник, Редактировать, Удалить.
  - Диалог/экран редактирования:
    - Поля: external_id, markdown (многострочный редактор), max_chunk_size_tokens, chunk_overlap_tokens, ttl_days, expiration_policy (select).
    - Подсказки/хелперы по ограничениям.
  - Индикаторы статуса (моки): В обработке, Готов, Ошибка. Управление статусом локально.

  3) Валидация
  - external_id: 2–64 символа, латиница/цифры/дефис/нижнее подчёркивание.
  - markdown: не пустой, до ~200k символов; показывать счётчик.
  - max_chunk_size_tokens: 100–2000.
  - chunk_overlap_tokens: 0–1000 и < max_chunk_size_tokens.
  - ttl_days: >= 1.

  4) Сохранение
  - Сохранять в провайдер по assistantId; отображать snackbar об успехе.
  - Для связи с Tools предоставить селектор external_id (на шаге 7 — читаем из этого провайдера).

- Ожидаемый результат:
  - Экран базы знаний с CRUD, валидацией и локальным состоянием.

- Критерии готовности (Definition of Done):
  - Рабочие формы, корректная валидация и статусы.
  - Данные хранятся в провайдере и подхватываются в Tools (SearchIndex).
  - Документация обновлена, коммит и push выполнены.

- Тесты (не используются):
  - Ручная проверка CRUD и интеграции с селектором в Tools.

- Зависимости/примечания:
  - Структура взята из `docs/knowledge_base.json`.

- Риски:
  - Большие markdown‑тексты — следить за производительностью редактора, использовать lazy/render‑only preview при необходимости.

Выполнено: в процессе
