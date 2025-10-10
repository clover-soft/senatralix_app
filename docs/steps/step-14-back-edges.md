# ТЗ: альтернативный стиль обратных рёбер (ортогональные с радиусными поворотами)

## Цель
Добавить второй способ отрисовки обратных рёбер, основанный на ортогональной маршрутизации (углы 90°) с радиусными скруглениями. Рёбра выходят из верхней грани исходного узла и входят в верхнюю грань целевого узла. Переключение стиля — через настройки [RenderSettings](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:3:0-34:1).

## Изменения в структуре и API

- **[файл]** `lib/features/assistant/features/dialogs/widgets/canvas/painters/back_edges_painter.dart`
  - Оставить текущую реализацию (безье) как стиль по умолчанию.

- **[новый файл]** `lib/features/assistant/features/dialogs/widgets/canvas/painters/back_edges_painter_ortho.dart`
  - Реализация ортогонального маршрутизатора с поворотами 90° и радиусными скруглениями (филлеты).
  - Рисует: сегменты (верт/гориз), скругления дугами, треугольный маркер стрелки, стык маркера с линией.

- **[файл]** `lib/features/assistant/features/dialogs/widgets/canvas/layers/back_edges_layer.dart`
  - Принимать [RenderSettings](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:3:0-34:1) и в рантайме выбирать пейнтер:
    - `backEdgeStyle == BackEdgeStyle.bezier` → старый `BackEdgesPainter`.
    - `backEdgeStyle == BackEdgeStyle.ortho` → новый `BackEdgesPainterOrtho`.

- **[файл]** [lib/features/assistant/features/dialogs/settings/render_settings.dart](cci:7://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:0:0-0:0)
  - Добавить перечисление:
    ```dart
    enum BackEdgeStyle { bezier, ortho }
    ```
  - Добавить поля (значения по умолчанию подобраны безопасно):
    - `final BackEdgeStyle backEdgeStyle;` // default: `BackEdgeStyle.bezier`
    - `final double orthoCornerRadius;` // скругление углов, default: 10.0
    - `final double orthoVerticalClearance;` // подъём вверх от исходной вершины, default: 40.0
    - `final double orthoHorizontalClearance;` // отступ по X от узлов, default: 24.0
    - `final double orthoExitOffset;` // смещение точки выхода на верхней грани, default: 0.0 (центр)
    - `final double orthoApproachOffset;` // смещение точки входа на верхней грани, default: 0.0 (центр)
    - `final bool orthoApproachFromTopOnly;` // всегда вход сверху, default: true
    - `final bool arrowTriangleFilled;` // заливка треугольника стрелки, default: true
    - `final double arrowTriangleBase;` // ширина основания стрелки, default: 8.0
    - `final double arrowTriangleHeight;` // высота треугольника, default: 12.0
    - `final double orthoMinSegment;` // минимальная длина сегмента, default: 8.0
    - `final bool orthoPreferRightward;` // при равнозначных маршрутах уходить вправо, default: true

- **[файл]** [lib/features/assistant/features/dialogs/widgets/dialogs_centered_canvas.dart](cci:7://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/widgets/dialogs_centered_canvas.dart:0:0-0:0)
  - Параметр `renderSettings` уже есть. Ничего не менять, кроме прокидывания в `BackEdgesLayer` (уже делается).

## Маршрутизация (алгоритм Ortho)

- **[исходные/целевые порты]**
  - Исходная точка: середина верхней грани исходного узла `srcTop = srcPos + Offset(nodeSize.width / 2 + orthoExitOffset, 0)`.
  - Целевая точка: середина верхней грани целевого узла `dstTop = dstPos + Offset(nodeSize.width / 2 + orthoApproachOffset, 0)`.

- **[базовый маршрут (без обходов)]**
  - Поднять от `srcTop` вертикально вверх на `orthoVerticalClearance`.
  - Горизонтально к `dstTop.dx`.
  - Вниз к `dstTop.dy`.

- **[обходы (минимум на первом релизе)]**
  - На первом этапе допускается игнорировать обнаружение пересечений с узлами/рёбрами.
  - Вторая итерация (после визуальной проверки): если горизонтальный сегмент проходит над узлом, поднимать «полку» выше на n*`orthoVerticalClearance` и повторять.

- **[с## Стрелка

- Треугольник, ориентированный вниз (так как вход сверху), вершина стрелки совмещается с началом вертикального сегмента входа в целевой узел с учётом `arrowTriangleHeight`.
- КРИТИЧЕСКОЕ ТРЕБОВАНИЕ: линия ДОЛЖНА подходить к треугольной стрелке по ЦЕНТРУ соответствующей ГРАНИ треугольника (midpoint), а НЕ к пересечению биссектрис и НЕ к вершине. Для нашего случая (стрелка ориентирована вниз) линия должна стыковаться строго по центру ВЕРХНЕЙ грани треугольника.
- В настройках управлять заливкой/размерами.
- **[новое поле в RenderSettings]**
  - `final bool arrowAttachAtEdgeMid;` // default: true. При true контур линии стыкуется с центром соответствующей грани треугольника (для down-ориентации — центр верхней грани).

- **[стиль отрисовки]**
  - Линии `Paint.strokeWidth = renderSettings.backEdgeStrokeWidth`, `Paint.color = renderSettings.backEdgeColor`, `PaintingStyle.stroke`.
  - Скругления рисовать дугами (четверть окружности) между сегментами, чтобы получались «радиусные повороты 90°».

- **[переключатель стиля]**
  - В местах вызова [DialogsCenteredCanvas](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/widgets/dialogs_centered_canvas.dart:8:0-89:1) менять стиль простым параметром:
    ```dart
    renderSettings: const RenderSettings(
      backEdgeStyle: BackEdgeStyle.ortho,
      orthoCornerRadius: 12,
      // при необходимости подстроить параметры
    ),
    ```

- **[обратная совместимость]**
  - Если `backEdgeStyle` не задан — используется `BackEdgeStyle.bezier` (старый пейнтер).

## Нагрузочные и UX аспекты

- **[производительность]**
  - Использовать `Path` с минимальным количеством операций.
  - Обновление только при изменении входных данных (позиции/ребра/настройки), как и раньше.

- **[UX соответствия]**
  - Выход строго с верхней грани исходника, вход строго в верхнюю грань целевика.
  - Радиусные повороты визуально чистые, без острых углов.

## Тест-кейсы (визуальные)

- **[case 1]** Один back-edge между соседними уровнями: угол 90° со скруглением, вершина стрелки стыкуется к верхней грани цели.
- **[case 2]** Несколько back-edges из одного источника в разные цели: полки расходятся по X, не залезая в узлы (на 1-й итерации допускается пересечение, на 2-й — поднять полку).
- **[case 3]** Длинный маршрут через 2+ уровней: проверка читабельности и корректного размещения стрелки.
- **[case 4]** Переключение стиля bezier/ortho без перерисовки нод и настроек — только слой обратных рёбер меняется.

## Оценка работ

- **[этап 1]** Добавление `BackEdgeStyle`, параметров в [RenderSettings](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:3:0-34:1), создание `BackEdgesPainterOrtho`, переключение в `BackEdgesLayer`. 4–6 часов.
- **[этап 2]** Улучшение обходов (избегание пересечения узлов на горизонтальной «полке»). 4–8 часов.
- **[этап 3]** Тюнинг визуала (толщины, радиусы, стрелка к топ-грани, параметры по умолчанию из [docs/my/todo.txt](cci:7://file:///Users/yakov/Documents/clover_soft/sentralix_app/docs/my/todo.txt:0:0-0:0)). 1–2 часа.

## Вынос настроек в [RenderSettings](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:3:0-34:1)

- Полный список новых полей (см. выше) должен быть добавлен в [RenderSettings](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:3:0-34:1) в [lib/features/assistant/features/dialogs/settings/render_settings.dart](cci:7://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:0:0-0:0) с докстрингами на русском языке.
  - Дополнительно добавить флаг привязки линии к центру грани стрелки:
    - `final bool arrowAttachAtEdgeMid;` // default: true. При true контур линии стыкуется с центром соответствующей грани треугольника (для down-ориентации — центр верхней грани).

# Следующие шаги
- **[1]** Добавить `BackEdgeStyle` и новые поля в [RenderSettings](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:3:0-34:1).
- **[2]** Создать `back_edges_painter_ortho.dart` и реализовать отрисовку.
- **[3]** Обновить `BackEdgesLayer` для выбора пейнтера по `backEdgeStyle`.
- **[4]** Прогнать визуальные кейсы, скорректировать дефолты.

Готов реализовать этап 1–3. Хотите — сразу начну с добавления `BackEdgeStyle` и параметров в [RenderSettings](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/settings/render_settings.dart:3:0-34:1)? Стиль по умолчанию оставлю `bezier`. Визуальные дефолты для `ortho`: `cornerRadius=12`, `verticalClearance=48`, `horizontalClearance=24`, `arrowTriangleBase=8`, `arrowTriangleHeight=12`.