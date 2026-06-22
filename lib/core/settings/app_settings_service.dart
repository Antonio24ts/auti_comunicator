import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class AppSettingsService {
  static const String _speechRateKey = 'speechRate';
  static const String _cardSizeKey = 'cardSize';
  static const String _speakOnCardTapKey = 'speakOnCardTap';
  static const String _ambientMusicEnabledKey = 'ambientMusicEnabled';
  static const String _ambientMusicVolumeKey = 'ambientMusicVolume';
  static const String _childNameKey = 'childName';
  static const String _ambientMusicTrackIdKey = 'ambientMusicTrackId';
  static const String _ambientMusicPlaybackModeKey = 'ambientMusicPlaybackMode';

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

    final childName =
        prefs.getString(_childNameKey)?.trim() ?? defaultSettings.childName;

    final ambientMusicTrackId =
        prefs.getString(_ambientMusicTrackIdKey) ??
        AmbientMusicTracks.relaxing1Id;

    final playbackModeName =
        prefs.getString(_ambientMusicPlaybackModeKey) ??
        AmbientMusicPlaybackMode.loopSelected.name;

    final ambientMusicPlaybackMode = AmbientMusicPlaybackMode.values.firstWhere(
      (mode) => mode.name == playbackModeName,
      orElse: () => AmbientMusicPlaybackMode.loopSelected,
    );

    return AppSettings(
      speechRate: speechRate,
      cardSize: cardSize,
      speakOnCardTap: speakOnCardTap,
      ambientMusicEnabled: ambientMusicEnabled,
      ambientMusicVolume: ambientMusicVolume,
      childName: childName,
      ambientMusicTrackId: ambientMusicTrackId,
      ambientMusicPlaybackMode: ambientMusicPlaybackMode,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_speechRateKey, settings.speechRate);
    await prefs.setString(_cardSizeKey, settings.cardSize.name);
    await prefs.setBool(_speakOnCardTapKey, settings.speakOnCardTap);
    await prefs.setBool(_ambientMusicEnabledKey, settings.ambientMusicEnabled);
    await prefs.setDouble(_ambientMusicVolumeKey, settings.ambientMusicVolume);
    await prefs.setString(_childNameKey, settings.childName.trim());
    await prefs.setString(
      _ambientMusicTrackIdKey,
      settings.ambientMusicTrackId,
    );
    await prefs.setString(
      _ambientMusicPlaybackModeKey,
      settings.ambientMusicPlaybackMode.name,
    );
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
