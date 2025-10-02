import 'package:flutter/material.dart';

/// Панель инструментов графа диалогов (вправо, вертикальная колонка)
/// - Кнопка "Вписать"
/// - Вертикальный слайдер масштаба
/// - Кнопка "Настройки диалога"
/// - Кнопка "Обновить"
class DialogsToolbarPanel extends StatelessWidget {
  const DialogsToolbarPanel({
    super.key,
    required this.onFitPressed,
    required this.currentScale,
    required this.onScaleChanged,
    required this.onSettingsPressed,
    required this.onRefreshPressed,
    required this.onAddPressed,
  });

  final VoidCallback onFitPressed;
  final double currentScale;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onSettingsPressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: SizedBox(
        width: 64,
        height: 360,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // Добавить шаг
              Tooltip(
                message: 'Добавить шаг',
                child: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onAddPressed,
                ),
              ),
              const SizedBox(height: 6),
              // Настройки диалога
              Tooltip(
                message: 'Настройки диалога',
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: onSettingsPressed,
                ),
              ),
              const SizedBox(height: 6),
              // Обновить
              Tooltip(
                message: 'Обновить',
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefreshPressed,
                ),
              ),
              const SizedBox(height: 6),
              // Вертикальный слайдер масштаба
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                      trackShape: const _FullWidthTrackShape(),
                    ),
                    child: Slider(
                      min: 0.5,
                      max: 2.5,
                      divisions: 20,
                      value: currentScale.clamp(0.5, 2.5),
                      onChanged: onScaleChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Вписать
              Tooltip(
                message: 'Вписать',
                child: IconButton(
                  tooltip: 'Вписать',
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: onFitPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кастомная форма трека слайдера без внутренних отступов — трек на всю ширину
class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2.0;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
