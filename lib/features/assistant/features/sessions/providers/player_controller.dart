import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'player_source_loader.dart';

@immutable
class PlayerViewState {
  final Duration position;
  final Duration duration;
  final bool playing;
  final double speed;
  final bool isScrubbing;
  final Duration dragPosition;
  final bool initialized;
  final bool initAttempted;
  final String? error;

  const PlayerViewState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.speed = 1.0,
    this.isScrubbing = false,
    this.dragPosition = Duration.zero,
    this.initialized = false,
    this.initAttempted = false,
    this.error,
  });

  PlayerViewState copyWith({
    Duration? position,
    Duration? duration,
    bool? playing,
    double? speed,
    bool? isScrubbing,
    Duration? dragPosition,
    bool? initialized,
    bool? initAttempted,
    String? error,
  }) {
    return PlayerViewState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
      speed: speed ?? this.speed,
      isScrubbing: isScrubbing ?? this.isScrubbing,
      dragPosition: dragPosition ?? this.dragPosition,
      initialized: initialized ?? this.initialized,
      initAttempted: initAttempted ?? this.initAttempted,
      error: error,
    );
  }
}

final playerControllerProvider = StateNotifierProvider.family<PlayerController, PlayerViewState, String>((ref, internalId) {
  return PlayerController(internalId);
});

class PlayerController extends StateNotifier<PlayerViewState> {
  final String _internalId;
  late final AudioPlayer _player;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _eventSub;
  StreamSubscription<PositionDiscontinuity>? _discSub;

  UriAudioSource? _source;
  String? _url;
  Future<void> Function()? _cleanup; // для web: revokeObjectUrl

  PlayerController(this._internalId) : super(const PlayerViewState()) {
    _player = AudioPlayer();
    debugPrint('[PC] ctor for id=$_internalId');
    _bindStreams();
  }

  Future<void> init({String? audioUrl}) async {
    if (state.initialized || state.initAttempted) return;
    state = state.copyWith(initAttempted: true, error: null);
    _url = (audioUrl != null && audioUrl.isNotEmpty)
        ? audioUrl
        : 'https://api.sentralix.ru/assistants/threads/$_internalId/recording';
    try {
      debugPrint('[PC] init: prepare source url=${_url}');
      // Передаём куки для авторизованного запроса на Web
      final built = await buildAudioUriSource(
        _url!,
        withCredentials: true,
        // headers: {'Authorization': 'Bearer <token>'}, // при необходимости
      );
      _source = built.source;
      _cleanup = built.cleanup;
      await _player.setAudioSource(_source!, preload: true);
      await _player.load();
      state = state.copyWith(initialized: true);
    } catch (e, st) {
      debugPrint('[PC] init error: $e\n$st');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> retryInit({String? audioUrl}) async {
    // Сброс и повторная попытка по явному вызову
    state = state.copyWith(initAttempted: false, initialized: false, error: null);
    await init(audioUrl: audioUrl);
  }

  void _bindStreams() {
    _posSub = _player.positionStream.listen((pos) {
      if (!state.isScrubbing) {
        debugPrint('[PC] position=$pos');
        state = state.copyWith(position: pos);
      }
    });
    _durSub = _player.durationStream.listen((dur) {
      debugPrint('[PC] duration=${dur ?? Duration.zero}');
      state = state.copyWith(duration: dur ?? Duration.zero);
    });
    _playerStateSub = _player.playerStateStream.listen((s) {
      debugPrint('[PC] playerState processing=${s.processingState} playing=${s.playing}');
      state = state.copyWith(playing: s.playing);
    });
    _eventSub = _player.playbackEventStream.listen((e) {
      debugPrint('[PC] event state=${e.processingState} upd=${e.updatePosition} buf=${e.bufferedPosition} dur=${e.duration} idx=${e.currentIndex}');
    });
    _discSub = _player.positionDiscontinuityStream.listen((d) {
      debugPrint('[PC] discontinuity reason=${d.reason}');
    });
  }

  Future<void> toggle() async {
    if (!state.initialized) {
      debugPrint('[PC] toggle: not initialized');
      return;
    }
    if (_player.playing) {
      debugPrint('[PC] toggle: pause at ${_player.position}');
      await _player.pause();
      return;
    }
    final target = state.isScrubbing ? state.dragPosition : state.position;
    if (target > Duration.zero) {
      debugPrint('[PC] toggle: seek to $target');
      await _player.seek(target);
    } else {
      debugPrint('[PC] toggle: start from 0');
      await _player.seek(Duration.zero);
    }
    debugPrint('[PC] toggle: play()');
    await _player.play();
  }

  Future<void> play() async {
    if (!state.initialized) return;
    await _player.play();
  }

  Future<void> pause() async {
    if (!state.initialized) return;
    await _player.pause();
  }

  Future<void> stop() async {
    if (!state.initialized) return;
    debugPrint('[PC] stop');
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  Future<void> seek(Duration pos) async {
    if (!state.initialized) return;
    debugPrint('[PC] seek to $pos');
    await _player.seek(pos);
  }

  Future<void> setSpeed(double v) async {
    if (!state.initialized) return;
    debugPrint('[PC] speed=$v');
    await _player.setSpeed(v);
    state = state.copyWith(speed: v);
  }

  void startScrub(double ms) {
    final pos = Duration(milliseconds: ms.toInt());
    state = state.copyWith(isScrubbing: true, dragPosition: pos);
    debugPrint('[PC] scrub.start=$pos');
  }

  void updateScrub(double ms) {
    final pos = Duration(milliseconds: ms.toInt());
    state = state.copyWith(dragPosition: pos);
  }

  Future<void> endScrub(double ms) async {
    final pos = Duration(milliseconds: ms.toInt());
    final wasPlaying = state.playing;
    debugPrint('[PC] scrub.end target=$pos wasPlaying=$wasPlaying');
    if (wasPlaying) await _player.pause();
    await _player.seek(pos);
    state = state.copyWith(position: pos, dragPosition: pos, isScrubbing: false);
    if (wasPlaying) await _player.play();
  }

  @override
  void dispose() {
    debugPrint('[PC] dispose');
    _posSub?.cancel();
    _durSub?.cancel();
    _playerStateSub?.cancel();
    _eventSub?.cancel();
    _discSub?.cancel();
    // Освобождаем blob URL на Web, если был создан
    final c = _cleanup;
    if (c != null) {
      // ignore: discarded_futures
      c();
    }
    _player.dispose();
    super.dispose();
  }
}

