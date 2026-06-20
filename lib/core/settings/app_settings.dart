enum CardSize { small, medium, large }

class AppSettings {
  final double speechRate;
  final CardSize cardSize;
  final bool speakOnCardTap;
  final bool ambientMusicEnabled;
  final double ambientMusicVolume;
  final String childName;

  const AppSettings({
    required this.speechRate,
    required this.cardSize,
    required this.speakOnCardTap,
    required this.ambientMusicEnabled,
    required this.ambientMusicVolume,
    required this.childName,
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
    double? speechRate,
    CardSize? cardSize,
    bool? speakOnCardTap,
    bool? ambientMusicEnabled,
    double? ambientMusicVolume,
    String? childName,
  }) {
    return AppSettings(
      speechRate: speechRate ?? this.speechRate,
      cardSize: cardSize ?? this.cardSize,
      speakOnCardTap: speakOnCardTap ?? this.speakOnCardTap,
      ambientMusicEnabled: ambientMusicEnabled ?? this.ambientMusicEnabled,
      ambientMusicVolume: ambientMusicVolume ?? this.ambientMusicVolume,
      childName: childName ?? this.childName,
    );
  }
}
