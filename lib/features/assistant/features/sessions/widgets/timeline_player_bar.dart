import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/features/assistant/features/sessions/providers/player_controller.dart';
import 'package:sentralix_app/features/assistant/features/sessions/utils/download_saver.dart';

/// Панель плеера: Play/Pause, Stop, прогресс, скорость, сохранить
class TimelinePlayerBar extends ConsumerStatefulWidget {
  final String internalId;
  final String?
  audioUrl; // Необязательный URL. Если не задан, собирается из internalId
  const TimelinePlayerBar({super.key, required this.internalId, this.audioUrl});

  @override
  ConsumerState<TimelinePlayerBar> createState() => _TimelinePlayerBarState();
}

class _TimelinePlayerBarState extends ConsumerState<TimelinePlayerBar> {
  bool _initScheduled = false;
  @override
  void initState() {
    super.initState();
    if (_initScheduled) return;
    _initScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(playerControllerProvider(widget.internalId));
      final ctrl = ref.read(
        playerControllerProvider(widget.internalId).notifier,
      );
      if (!state.initialized && !state.initAttempted) {
        // Один вызов init после первого кадра
        unawaited(ctrl.init(audioUrl: widget.audioUrl));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider(widget.internalId));
    final ctrl = ref.read(playerControllerProvider(widget.internalId).notifier);

    Future<void> toggle() => ctrl.toggle();
    Future<void> stop() => ctrl.stop();
    void changeSpeed(double v) => ctrl.setSpeed(v);

    void saveFile() async {
      final messenger = ScaffoldMessenger.of(context);
      final url = (widget.audioUrl != null && widget.audioUrl!.isNotEmpty)
          ? widget.audioUrl!
          : 'https://api.sentralix.ru/assistants/threads/${widget.internalId}/recording';
      try {
        final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
        final fname = 'recording_${widget.internalId}_$ts.mp3';
        await saveRecording(url, suggestedFileName: fname);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Файл сохранён')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Не удалось сохранить файл: $e')),
        );
      }
    }

    final total = state.duration.inMilliseconds;
    final displayed = state.isScrubbing ? state.dragPosition : state.position;
    final current = total > 0 ? displayed.inMilliseconds.clamp(0, total) : 0;
    String fmt(Duration d) {
      int h = d.inHours;
      int m = d.inMinutes.remainder(60);
      int s = d.inSeconds.remainder(60);
      String two(int v) => v.toString().padLeft(2, '0');
      return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: state.error != null && !state.initialized
            ? Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ошибка загрузки аудио: ${state.error}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => ctrl.retryInit(audioUrl: widget.audioUrl),
                    child: const Text('Повторить'),
                  ),
                ],
              )
            : Row(
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
                  // Текущее время
                  SizedBox(
                    width: 64,
                    child: Text(
                      fmt(Duration(milliseconds: current)),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                  // Общее время
                  SizedBox(
                    width: 64,
                    child: Text(
                      fmt(Duration(milliseconds: total > 0 ? total : 0)),
                      style: Theme.of(context).textTheme.bodySmall,
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
