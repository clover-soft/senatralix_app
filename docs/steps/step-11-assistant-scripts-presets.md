### Шаг 11: Пресеты фильтров команд и обратный рендер
- Цель:
  Добавить пресеты для `filter_expression` (Начало звонка, Конец звонка, Сообщение) и обеспечить обратный рендер фильтра из структуры бэкенда в UI.

- Действия:
  1) Добавлены модели и перечисления пресетов и фильтров:
     - `lib/features/assistant/features/scripts/data/script_filter_presets.dart`
     - `lib/features/assistant/features/scripts/models/message_filter_form_state.dart`
  2) Реализованы билдеры JSON фильтра:
     - `lib/features/assistant/features/scripts/utils/filter_expression_builder.dart`
       (buildStartCallFilter, buildEndCallFilter, buildMessageFilter, stringifyFilter)
  3) Реализован парсер фильтра из JSON (обратный рендер):
     - `lib/features/assistant/features/scripts/utils/filter_expression_parser.dart`
       (parseFilterExpression -> ParsedFilter { preset, message? })
  4) Расширены провайдеры редактора команды:
     - `lib/features/assistant/features/scripts/providers/script_command_edit_provider.dart`
       (scriptPresetProvider, messageFilterFormProvider + контроллер, методы формы)
  5) Создан виджет подформы "Сообщение":
     - `lib/features/assistant/features/scripts/widgets/message_filter_form.dart`
       (чекбоксы ролей, тип фильтрации, поле текста/регэкспа; синхронизация с провайдером)
  6) Обновлён экран редактора команды:
     - `lib/features/assistant/features/scripts/screens/script_command_editor_screen.dart`
       (Dropdown пресетов; при выборе "Сообщение" показывается подформа; пересборка filter_expression; обратный рендер при открытии существующей команды)

- Ожидаемый результат:
  - В редакторе команд доступен выпадающий список пресетов: "Начало звонка", "Конец звонка", "Сообщение", "Произвольный (ручной JSON)".
  - Для пресета "Сообщение" доступны чекбоксы ролей, выбор типа фильтрации текста и поле ввода текста/регэкспа. Все изменения автоматически пересобирают `filter_expression`.
  - При открытии существующей команды фильтр парсится и восстанавливает UI (пресет/подформа), если выражение соответствует поддерживаемым шаблонам; иначе пресет = custom.

- Критерии готовности (Definition of Done):
  - Пресеты работают и корректно формируют JSON `filter_expression`.
  - Обратный рендер корректно определяет пресеты и подформу для "Сообщение".
  - В ручном режиме редактирования `filter_expression` пресет переключается на `custom`.

- Выполнено: да
