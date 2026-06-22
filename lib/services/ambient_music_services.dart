import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../core/settings/app_settings.dart';

class AmbientMusicService {
  final AudioPlayer _player = AudioPlayer();

  String? _loadedTrackId;
  AmbientMusicPlaybackMode? _loadedPlaybackMode;
  bool _wasPlayingBeforeSpeech = false;

  Future<void> init(AppSettings settings) async {
    await _loadPlaylistIfNeeded(settings: settings, forceReload: true);

    await applySettings(settings);
  }

  Future<void> applySettings(AppSettings settings) async {
    await _loadPlaylistIfNeeded(settings: settings);

    await _player.setVolume(settings.ambientMusicVolume);

    if (!settings.ambientMusicEnabled) {
      await _player.pause();
      return;
    }

    if (!_player.playing) {
      unawaited(_player.play());
    }
  }

  Future<void> pauseForSpeech() async {
    _wasPlayingBeforeSpeech = _player.playing;

    if (_player.playing) {
      await _player.pause();
    }
  }

  Future<void> resumeAfterSpeech(AppSettings settings) async {
    if (!settings.ambientMusicEnabled) {
      return;
    }

    if (!_wasPlayingBeforeSpeech) {
      return;
    }

    await _loadPlaylistIfNeeded(settings: settings);

    if (!_player.playing) {
      unawaited(_player.play());
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  Future<void> _loadPlaylistIfNeeded({
    required AppSettings settings,
    bool forceReload = false,
  }) async {
    final shouldReload =
        forceReload ||
        _loadedTrackId != settings.ambientMusicTrackId ||
        _loadedPlaybackMode != settings.ambientMusicPlaybackMode;

    if (!shouldReload) {
      await _player.setLoopMode(
        _getLoopMode(settings.ambientMusicPlaybackMode),
      );
      return;
    }

    final wasPlaying = _player.playing;

    final selectedTrackIndex = AmbientMusicTracks.getIndexById(
      settings.ambientMusicTrackId,
    );

    final playlist = ConcatenatingAudioSource(
      children: [
        for (final track in AmbientMusicTracks.all)
          AudioSource.asset(track.assetPath),
      ],
    );

    await _player.setAudioSource(
      playlist,
      initialIndex: selectedTrackIndex,
      initialPosition: Duration.zero,
    );

    await _player.setLoopMode(_getLoopMode(settings.ambientMusicPlaybackMode));

    _loadedTrackId = settings.ambientMusicTrackId;
    _loadedPlaybackMode = settings.ambientMusicPlaybackMode;

    if (wasPlaying && settings.ambientMusicEnabled) {
      unawaited(_player.play());
    }
  }

  LoopMode _getLoopMode(AmbientMusicPlaybackMode playbackMode) {
    switch (playbackMode) {
      case AmbientMusicPlaybackMode.loopSelected:
        return LoopMode.one;
      case AmbientMusicPlaybackMode.sequential:
        return LoopMode.all;
    }
  }
}
