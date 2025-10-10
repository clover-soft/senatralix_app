import 'package:flutter/material.dart';

/// Стиль отрисовки обратных рёбер
enum BackEdgeStyle { bezier, ortho }

/// Настройки рендера (цвета, толщины, параметры стрелок/кривых)
class RenderSettings {
  // Цвета рёбер
  final Color nextEdgeColor;
  final Color branchEdgeColor;
  final Color backEdgeColor;

  // Толщины
  final double nextEdgeStrokeWidth;
  final double branchEdgeStrokeWidth;
  final double backEdgeStrokeWidth;

  // Геометрия стрелок/кривых
  final double arrowLength;
  final double arrowDegrees;
  final double curvature;
  final double parallelSeparation;
  final double portPadding;

  // Стиль обратных рёбер
  final BackEdgeStyle backEdgeStyle;

  // Ортогональные back-edges (углы 90° со скруглениями)
  /// Радиус скругления углов на поворотах 90°
  final double orthoCornerRadius;

  /// Подъём вертикального сегмента от исходной точки вверх
  final double orthoVerticalClearance;

  /// Горизонтальный отступ «полки» от узлов
  final double orthoHorizontalClearance;

  /// Смещение точки выхода на верхней грани исходной ноды по X (от центра)
  final double orthoExitOffset;

  /// Смещение точки входа на верхней грани целевой ноды по X (от центра)
  final double orthoApproachOffset;

  /// Нормированная позиция точки выхода на верхней грани источника (0..1 от левого края). По умолчанию 0.75
  final double orthoExitFactor;

  /// Нормированная позиция точки входа на верхней грани приёмника (0..1 от левого края). По умолчанию 0.75
  final double orthoApproachFactor;

  /// Всегда входить в целевой узел сверху
  final bool orthoApproachFromTopOnly;

  /// Минимальная длина сегмента (верт/гориз), чтобы избежать артефактов
  final double orthoMinSegment;

  /// Предпочитать правый обход при равнозначных маршрутах
  final bool orthoPreferRightward;

  /// Вертикальный подъём от источника (lift) в пикселях — базовый уровень полки
  final double orthoLift;

  /// Вынос полки за край ряда в пикселях
  final double orthoOvershoot;

  /// Шаг между параллельными полками (эшелонами) по Y
  final double orthoShelfSpacing;

  /// Максимальное число эшелонов (lane) для одной стороны
  final int orthoShelfMaxLanes;

  /// Шаг разведения горизонталей подхода по X на одном уровне Y (без изменения Y)
  final double orthoApproachSpacingX;

  /// Максимальное число "шагов" смещения p2.x при разведении подходов
  final int orthoApproachMaxPush;

  /// Шаг микро-эшелона по Y для подходов (локальный сдвиг без смены уровня входа)
  final double orthoApproachEchelonSpacingY;

  /// Максимальное число микро-эшелонов по Y для подходов
  final int orthoApproachMaxLanesY;

  /// Привязка линии к центру соответствующей грани треугольника стрелки
  final bool arrowAttachAtEdgeMid;

  /// Настройки треугольной стрелки (ортогональный стиль)
  final bool arrowTriangleFilled;
  final double arrowTriangleBase; // ширина основания
  final double arrowTriangleHeight; // высота

  /// Логирование утилиты поворотов ортогональных рёбер
  final bool logOrthoTurns;

  const RenderSettings({
    this.nextEdgeColor = Colors.black,
    this.branchEdgeColor = const Color(0xFFFF9800), // цвет ветвления
    this.backEdgeColor = const Color(0xFFEA4335), // цвет обратных рёбер
    this.nextEdgeStrokeWidth = 2.0, // толщина линии ветвления
    this.branchEdgeStrokeWidth = 1.6, // толщина линии ветвления
    this.backEdgeStrokeWidth = 1.8, // толщина линии обратных рёбер
    this.arrowLength = 10.0, // длина стрелки
    this.arrowDegrees = 22.0, // угол стрелки
    this.curvature = 60.0, // радиус скругления
    this.parallelSeparation = 12.0, // расстояние между параллельными рёбрами
    this.portPadding = 6.0, // отступ от порта
    this.backEdgeStyle = BackEdgeStyle.ortho, // стиль обратных рёбер
    this.orthoCornerRadius = 12.0, // радиус скругления
    this.orthoVerticalClearance = 48.0, // вертикальный подъём от источника
    this.orthoHorizontalClearance =
        24.0, // горизонтальный отступ «полки» от узлов
    this.orthoExitOffset =
        0.0, // смещение точки выхода на верхней грани исходной ноды по X (от центра)
    this.orthoApproachOffset =
        0.0, // смещение точки входа на верхней грани приёмника по X (от центра)
    this.orthoExitFactor =
        0.60, // нормированная позиция точки выхода на верхней грани источника (0..1 от левого края). По умолчанию 0.75
    this.orthoApproachFactor =
        0.80, // нормированная позиция точки входа на верхней грани приёмника (0..1 от левого края). По умолчанию 0.75
    this.orthoApproachFromTopOnly =
        true, // всегда входить в целевой узел сверху
    this.orthoMinSegment =
        8.0, // минимальная длина сегмента (верт/гориз), чтобы избежать артефактов
    this.orthoPreferRightward =
        true, // предпочтение правого обхода при равнозначных маршрутах
    this.orthoLift =
        20.0, // вертикальный подъём от источника (lift) в пикселях — базовый уровень полки
    this.orthoOvershoot = 20.0, // вынос полки за край ряда в пикселях
    this.orthoShelfSpacing =
        20.0, // шаг между параллельными полками (эшелонами) по Y
    this.orthoShelfMaxLanes =
        4, // максимальное число эшелонов (lane) для одной стороны
    this.arrowAttachAtEdgeMid =
        true, // привязка линии к центру соответствующей грани
    this.arrowTriangleFilled = true,
    this.arrowTriangleBase = 8.0,
    this.arrowTriangleHeight = 12.0,
    this.orthoApproachSpacingX =
        24.0, // шаг разведения горизонталей подхода по X на одном уровне Y (без изменения Y)
    this.orthoApproachMaxPush =
        3, // максимальное число "шагов" смещения p2.x при разведении подходов
    this.orthoApproachEchelonSpacingY = 6.0, // микро-сдвиг подходов по Y
    this.orthoApproachMaxLanesY = 3, // количество уровней микро-эшелона по Y
    this.logOrthoTurns =
        true, // логирование утилиты поворотов ортогональных рёбер
  });
}
