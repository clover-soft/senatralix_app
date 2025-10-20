import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/player_controller.dart';

/// Панель плеера: Play/Pause, Stop, прогресс, скорость, сохранить
class TimelinePlayerBar extends ConsumerWidget {
  final String internalId;
  final String? audioUrl; // Необязательный URL. Если не задан, собирается из internalId
  const TimelinePlayerBar({super.key, required this.internalId, this.audioUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider(internalId));
    final ctrl = ref.read(playerControllerProvider(internalId).notifier);

    if (!state.initialized) {
      scheduleMicrotask(() => ctrl.init(audioUrl: audioUrl));
    }

    Future<void> toggle() => ctrl.toggle();
    Future<void> stop() => ctrl.stop();
    void changeSpeed(double v) => ctrl.setSpeed(v);

    void saveFile() async {
      final url = (audioUrl != null && audioUrl!.isNotEmpty)
          ? audioUrl!
          : 'https://api.sentralix.ru/assistants/threads/$internalId/recording';
      await Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка на запись скопирована в буфер обмена')),
      );
    }

    final total = state.duration.inMilliseconds;
    final displayed = state.isScrubbing ? state.dragPosition : state.position;
    final current = total > 0 ? displayed.inMilliseconds.clamp(0, total) : 0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              tooltip: state.playing ? 'Пауза' : 'Воспроизведение',
              onPressed: toggle,
              icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: 'Стоп',
              onPressed: stop,
              icon: const Icon(Icons.stop),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                min: 0,
                max: total > 0 ? total.toDouble() : 1.0,
                value: total > 0 ? current.toDouble() : 0,
                onChangeStart: (v) => ctrl.startScrub(v),
                onChanged: (v) => ctrl.updateScrub(v),
                onChangeEnd: (v) => ctrl.endScrub(v),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: state.speed,
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                  DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                  DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                  DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                  DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                ],
                onChanged: (v) => v != null ? changeSpeed(v) : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Сохранить файл',
              onPressed: saveFile,
              icon: const Icon(Icons.download),
            ),
          ],
        ),
      ),
    );
  }
}
