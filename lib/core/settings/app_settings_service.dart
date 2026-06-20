import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class AppSettingsService {
  static const String _speechRateKey = 'speechRate';
  static const String _cardSizeKey = 'cardSize';
  static const String _speakOnCardTapKey = 'speakOnCardTap';
  static const String _ambientMusicEnabledKey = 'ambientMusicEnabled';
  static const String _ambientMusicVolumeKey = 'ambientMusicVolume';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    final defaultSettings = AppSettings.defaults();

    final speechRate =
        prefs.getDouble(_speechRateKey) ?? defaultSettings.speechRate;

    final cardSizeName = prefs.getString(_cardSizeKey);
    final cardSize = _parseCardSize(cardSizeName) ?? defaultSettings.cardSize;

    final speakOnCardTap =
        prefs.getBool(_speakOnCardTapKey) ?? defaultSettings.speakOnCardTap;

    final ambientMusicEnabled =
        prefs.getBool(_ambientMusicEnabledKey) ??
        defaultSettings.ambientMusicEnabled;

    final ambientMusicVolume =
        prefs.getDouble(_ambientMusicVolumeKey) ??
        defaultSettings.ambientMusicVolume;

    return AppSettings(
      speechRate: speechRate,
      cardSize: cardSize,
      speakOnCardTap: speakOnCardTap,
      ambientMusicEnabled: ambientMusicEnabled,
      ambientMusicVolume: ambientMusicVolume,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_speechRateKey, settings.speechRate);
    await prefs.setString(_cardSizeKey, settings.cardSize.name);
    await prefs.setBool(_speakOnCardTapKey, settings.speakOnCardTap);
    await prefs.setBool(_ambientMusicEnabledKey, settings.ambientMusicEnabled);
    await prefs.setDouble(_ambientMusicVolumeKey, settings.ambientMusicVolume);
  }

  CardSize? _parseCardSize(String? value) {
    switch (value) {
      case 'small':
        return CardSize.small;
      case 'medium':
        return CardSize.medium;
      case 'large':
        return CardSize.large;
      default:
        return null;
    }
  }
}
