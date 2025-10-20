import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Провайдер аудиоплеера для экрана таймлайна (один инстанс на internalId)
final timelinePlayerProvider = AutoDisposeProvider.family<AudioPlayer, String>(
  (ref, internalId) {
    final player = AudioPlayer();
    ref.onDispose(() => player.dispose());
    return player;
  },
);

/// Текущая скорость воспроизведения
final timelineSpeedProvider = AutoDisposeStateProvider.family<double, String>(
  (ref, internalId) => 1.0,
);
