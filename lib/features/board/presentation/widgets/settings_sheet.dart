import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import 'credits_sheet.dart';

class SettingsSheet extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final VoidCallback onTestVoice;

  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onTestVoice,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });

    widget.onSettingsChanged(newSettings);
  }

  Future<void> _openCredits() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return const CreditsSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsHeader(),
                const SizedBox(height: 20),
                _SpeechRateSetting(
                  value: _settings.speechRate,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(speechRate: value));
                  },
                  onTestVoice: widget.onTestVoice,
                ),
                const SizedBox(height: 18),
                _CardSizeSetting(
                  value: _settings.cardSize,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(cardSize: value));
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Sonido al pulsar palabra',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Si está desactivado, solo hablará al pulsar el botón Hablar.',
                  ),
                  value: _settings.speakOnCardTap,
                  onChanged: (value) {
                    _updateSettings(_settings.copyWith(speakOnCardTap: value));
                  },
                ),
                const SizedBox(height: 12),
                _MusicSetting(
                  enabled: _settings.ambientMusicEnabled,
                  volume: _settings.ambientMusicVolume,
                  onEnabledChanged: (value) {
                    _updateSettings(
                      _settings.copyWith(ambientMusicEnabled: value),
                    );
                  },
                  onVolumeChanged: (value) {
                    _updateSettings(
                      _settings.copyWith(ambientMusicVolume: value),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openCredits,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Créditos y licencia'),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicSetting extends StatelessWidget {
  final bool enabled;
  final double volume;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<double> onVolumeChanged;

  const _MusicSetting({
    required this.enabled,
    required this.volume,
    required this.onEnabledChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (volume * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Música relajante',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Reproduce música suave en bucle mientras se usa la app.',
          ),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        Row(
          children: [
            const SizedBox(
              width: 92,
              child: Text(
                'Volumen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Slider(
                value: volume,
                min: 0.0,
                max: 0.50,
                divisions: 10,
                label: '$percentage%',
                onChanged: enabled ? onVolumeChanged : null,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$percentage%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.settings, size: 30),
        SizedBox(width: 10),
        Text(
          'Ajustes',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SpeechRateSetting extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onTestVoice;

  const _SpeechRateSetting({
    required this.value,
    required this.onChanged,
    required this.onTestVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Velocidad de voz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onTestVoice,
              icon: const Icon(Icons.volume_up),
              label: const Text('Probar'),
            ),
          ],
        ),
        Slider(
          min: 0.35,
          max: 0.65,
          divisions: 6,
          value: value,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CardSizeSetting extends StatelessWidget {
  final CardSize value;
  final ValueChanged<CardSize> onChanged;

  const _CardSizeSetting({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tamaño de cards',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Pequeñas'),
              selected: value == CardSize.small,
              onSelected: (_) => onChanged(CardSize.small),
            ),
            ChoiceChip(
              label: const Text('Medianas'),
              selected: value == CardSize.medium,
              onSelected: (_) => onChanged(CardSize.medium),
            ),
            ChoiceChip(
              label: const Text('Grandes'),
              selected: value == CardSize.large,
              onSelected: (_) => onChanged(CardSize.large),
            ),
          ],
        ),
      ],
    );
  }
}
