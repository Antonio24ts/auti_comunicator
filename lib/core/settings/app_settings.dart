enum CardSize { small, medium, large }

class AppSettings {
  final double speechRate;
  final CardSize cardSize;
  final bool speakOnCardTap;

  const AppSettings({
    required this.speechRate,
    required this.cardSize,
    required this.speakOnCardTap,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      speechRate: 0.55,
      cardSize: CardSize.medium,
      speakOnCardTap: true,
    );
  }

  AppSettings copyWith({
    double? speechRate,
    CardSize? cardSize,
    bool? speakOnCardTap,
  }) {
    return AppSettings(
      speechRate: speechRate ?? this.speechRate,
      cardSize: cardSize ?? this.cardSize,
      speakOnCardTap: speakOnCardTap ?? this.speakOnCardTap,
    );
  }
}
