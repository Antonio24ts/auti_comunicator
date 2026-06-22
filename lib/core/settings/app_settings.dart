enum CardSize { small, medium, large }

enum AmbientMusicPlaybackMode { loopSelected, sequential }

class AmbientMusicTrack {
  final String id;
  final String name;
  final String assetPath;

  const AmbientMusicTrack({
    required this.id,
    required this.name,
    required this.assetPath,
  });
}

class AmbientMusicTracks {
  static const String relaxing1Id = 'relaxing_1';
  static const String relaxing2Id = 'relaxing_2';

  static const List<AmbientMusicTrack> all = [
    AmbientMusicTrack(
      id: relaxing1Id,
      name: 'Relajante 1',
      assetPath: 'assets/audio/musica_relajante.mp3',
    ),
    AmbientMusicTrack(
      id: relaxing2Id,
      name: 'Relajante 2',
      assetPath: 'assets/audio/musica_relajante1.mp3',
    ),
  ];

  static AmbientMusicTrack getById(String id) {
    return all.firstWhere((track) => track.id == id, orElse: () => all.first);
  }

  static int getIndexById(String id) {
    final index = all.indexWhere((track) => track.id == id);

    if (index == -1) {
      return 0;
    }

    return index;
  }
}

class AppSettings {
  final double speechRate;
  final CardSize cardSize;
  final bool speakOnCardTap;
  final bool ambientMusicEnabled;
  final double ambientMusicVolume;
  final String childName;
  final String ambientMusicTrackId;
  final AmbientMusicPlaybackMode ambientMusicPlaybackMode;

  const AppSettings({
    required this.speechRate,
    required this.cardSize,
    required this.speakOnCardTap,
    required this.ambientMusicEnabled,
    required this.ambientMusicVolume,
    required this.childName,
    this.ambientMusicTrackId = AmbientMusicTracks.relaxing1Id,
    this.ambientMusicPlaybackMode = AmbientMusicPlaybackMode.loopSelected,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      speechRate: 0.50,
      cardSize: CardSize.medium,
      speakOnCardTap: true,
      ambientMusicEnabled: false,
      ambientMusicVolume: 0.12,
      childName: '',
    );
  }

  AppSettings copyWith({
    bool? isSpeechEnabled,
    double? speechRate,
    CardSize? cardSize,
    bool? speakOnCardTap,
    bool? ambientMusicEnabled,
    double? ambientMusicVolume,
    String? childName,
    String? ambientMusicTrackId,
    AmbientMusicPlaybackMode? ambientMusicPlaybackMode,
  }) {
    return AppSettings(
      ambientMusicTrackId: ambientMusicTrackId ?? this.ambientMusicTrackId,
      ambientMusicPlaybackMode:
          ambientMusicPlaybackMode ?? this.ambientMusicPlaybackMode,
      speechRate: speechRate ?? this.speechRate,
      cardSize: cardSize ?? this.cardSize,
      speakOnCardTap: speakOnCardTap ?? this.speakOnCardTap,
      ambientMusicEnabled: ambientMusicEnabled ?? this.ambientMusicEnabled,
      ambientMusicVolume: ambientMusicVolume ?? this.ambientMusicVolume,
      childName: childName ?? this.childName,
    );
  }
}
