# ТЗ на разработку раскладки диалогового графа

## Общая цель
- **[цель]** Реализовать в [lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart](cci:7://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:0:0-0:0) функцию [computeCenteredLayout()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:379:0-659:1), которая строит координаты и структуру рёбер графа диалоговых шагов.
- **[направление]** Граф рисуется строго сверху вниз. На верхнем уровне (`row = 0`) находится единственная нода с `id = 1`; на этом же уровне других нод быть не должно. Все остальные ноды располагаются ниже.

## Ожидаемый результат
- **[результат]** [computeCenteredLayout()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:379:0-659:1) возвращает объект [CenteredLayoutResult](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:7:0-19:1) с заполненными:
  - `positions`: позиция каждой ноды (`Offset`).
  - `nextEdges` и `branchEdges`: списки рёбер «последовательность» и «ветвление».
  - `canvasSize`: размеры холста, учитывающие padding.
- **[готовность]** Функция корректно обрабатывает любые графы (включая несколько компонент) и не допускает коллизий между узлами/рёбрами.

## Функциональные требования
- **[входные данные]** `List<DialogStep>` и параметры визуализации (`nodeSize`, `nodeSeparation`, `levelSeparation`, `padding`).
- **[расположение корня]** Нода `id = 1` всегда в верхнем ряду; если граф не содержит такую ноду, нужно предусмотреть проверку/ошибку.
- **[иерархия уровней]** Каждый ребёнок располагается на уровне ниже своего родителя (минимум на 1).
- **[ветвления]** Branch-ноды распределяются так, чтобы на одном уровне была максимум одна такая нода.
- **[центрирование]** Ряды центрируются по максимальной ширине среди всех уровней.

## Архитектурные требования
- **[пошаговая логика]** Каждый этап обработки реализуется отдельной функцией-процедурой:
  - Построение служебных индексов ([_indexById()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:345:0-348:2)).
  - Определение родителей/детей ([_buildParents()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:350:0-369:1), [_buildOutgoing()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:304:0-323:1)).
  - Поиск корней и расширение до всех компонент ([_findInitialRoots()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:288:0-301:1), [_expandRootsByComponents()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:306:0-332:1)).
  - Инициализация уровней и клэмпы (`_computeInitialLevels()`, [_applyEdgeGapUpperBounds()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:95:0-166:1), и т.п.).
  - Нормализация и перераспределение branch-ноды ([_enforceBranchRows()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:251:0-339:1)).
  - Плотная нормализация уровней (`_compressLevels()`).
  - Барицентрическая сортировка и центрирование (`_sortWithinLevels()`, `_computePositions()`).
  - Формирование списков рёбер (`_collectEdges()`).
  - Рассчёт размера холста (`_computeCanvasSize()`).
- **[композиция]** [computeCenteredLayout()](cci:1://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:379:0-659:1) только orchestration: вызывает вспомогательные шаги, возвращает финальный [CenteredLayoutResult](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:7:0-19:1).

## Нефункциональные требования
- **[читаемость]** Разбивка на небольшие функции, подробные комментарии на русском.
- **[расширяемость]** Возможность добавлять альтернативные режимы нормализации уровней без переписывания всего пайплайна.
- **[отладка]** Предусмотреть debug-флаг (возможно через глобальную константу) для вывода промежуточных расчётов.

## Этапы реализации
- **[шаг 1]** Подготовить вспомогательные функции для индексации, родителей, исходящих рёбер, поиска корней.
- **[шаг 2]** Реализовать расчёт уровней: начальные значения, соблюдение `parent < child`, ограничение разрывов, уникальные branch-уровни, нормализация.
- **[шаг 3]** Выполнить сортировку внутри уровней, центрирование и расчёт координат.
- **[шаг 4]** Собрать рёбра, вычислить `canvasSize`, сформировать [CenteredLayoutResult](cci:2://file:///Users/yakov/Documents/clover_soft/sentralix_app/lib/features/assistant/features/dialogs/graph/centered_layered_layout.dart:7:0-19:1).
- **[шаг 5]** Добавить debug-логирование и локальную документацию шагов.

Готов уточнить детали или сразу приступить к реализации по этому ТЗ.