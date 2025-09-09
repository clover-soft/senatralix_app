### Шаг 9: Assistant — Connectors (моки, формы, валидация, локальное состояние)

- Цель:
  - Реализовать экран управления коннекторами (телефония и пр.) с мок‑данными и валидацией.
  - Сохранять изменения в модель риверпода (провайдер состояния по assistantId).

- Действия:
  0) Структура кода (обязательно)
  - Соблюдать модульную структуру подфичи: `features/assistant/features/connectors/{models,providers,widgets,screens}/`.
  - Экран(ы) — только композиция; редакторы/диалоги/карточки — в `widgets/`; модели — в `models/`; провайдеры — в `providers/`.

  1) Модель и провайдеры
  - Тип коннектора: пока используем ТОЛЬКО `telephony`, но архитектурно поддерживаем поле `type` и добавление через пресеты (как в Tools). Позже возможно расширение: `telegram`, `whatsapp`, `avito` — в этом шаге не реализуем и не описываем UI/настройки для них.
  - По `docs/connector.json` описать тип `Connector`:
    - id: string (UUID)
    - type: string (например: "telephony")
    - name: string
    - is_active: boolean
    - domain_id: string
    - settings (для type = telephony):
      - tts:
        - voice_pool: массив голосов { voice, language, vendor, role, speed }
        - voice_selection_strategy: enum("first", "round_robin")
        - cache_enable: boolean
        - lexicon: массив правил { type: "regex", pattern, replace, enabled, flags[] }
      - asr: { language: string, model: string }
      - dialog: { greeting_texts[], greeting_selection_strategy, reprompt_texts[], reprompt_selection_strategy, allow_barge_in, max_turns, noinput_retries, hangup_on_noinput, max_call_duration_sec, repeat_prompt_on_interrupt, interrupt_max_retries, interrupt_final_text, noinput_final_text, max_turns_final_text, max_call_duration_final_text }
      - callbridge: { answer.beofre_timeout_ms, dial.{ timeout_sec, callerid?, moh_enable, moh_class, allowlist[], denylist[] }, musiconhold.{ moh_class, duration_sec }, nothing.timeout_ms, play.{ can_interrupt, synth_cache_enable, gain_db, normalize_dbfs }, getspeech.{ noise_duration_ms, noise_timeout_ms, silense_duration_ms, max_speech_duration_ms } }
      - assistant: { filler_text_list[], filler_selection_strategy, soft_timeout_ms }
  - Провайдер: список коннекторов по assistantId, CRUD и статус включения/выключения.

  2) Экран UI (Connectors)
  - Список коннекторов карточками: имя, активность, краткий статус.
  - Действия: Добавить, Редактировать, Удалить, Включить/Выключить.
  - Редактор настроек с секциями:
    - TTS: список голосов (таблица), стратегия выбора, кэш, лексикон (таблица regex правил).
    - ASR: язык, модель.
    - Dialog: тексты приветствия/репромптов, стратегии, лимиты, финальные фразы.
    - Callbridge: группировка полей по подсекциям (answer/dial/musiconhold/...)
    - Assistant: filler_text_list и soft_timeout_ms.
  - UX: все секции в ExpansionPanelList, внизу действия Сохранить/Отмена.

  3) Валидация (минимально достаточная)
  - name: 2–80 символов.
  - voice_pool.voice/language/vendor: обязательны; speed ∈ [0.5; 2.0].
  - lexicon.pattern — корректный regex; flags ∈ {ignore_case}.
  - dialog.max_turns ≥ 1; noinput_retries ≥ 0; max_call_duration_sec ≥ 10.
  - callbridge.play.normalize_dbfs ∈ [-30; -6]; gain_db ∈ [-20; 20].

  4) Сохранение
  - Сохранять структуру в провайдер; показывать snackbar.

- Ожидаемый результат:
  - Экран управления коннекторами с CRUD и валидируемыми секциями настроек (моки).

- Критерии готовности (Definition of Done):
  - Рабочие формы по основным секциям, корректная валидация.
  - Данные хранятся в провайдере и отображаются при повторном входе.
  - Документация обновлена, коммит и push выполнены.

- Тесты (не используются):
  - Ручная проверка CRUD, переключателей активности, сохранения.

- Зависимости/примечания:
  - Структура полей взята из `docs/connector.json`.

- Риски:
  - Большой объём полей — разделяем по секциям, лениво монтируем вкладки.

Выполнено: да
