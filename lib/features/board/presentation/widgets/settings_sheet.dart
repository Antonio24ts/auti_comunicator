import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../board/presentation/widgets/child_name_dialog.dart';

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

  Future<void> _openChildNameEditor() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ChildNameDialog(
          initialName: _settings.childName,
          canCancel: true,
        );
      },
    );

    if (!mounted) {
      return;
    }

    final name = result?.trim();

    if (name == null || name.isEmpty) {
      return;
    }

    _updateSettings(_settings.copyWith(childName: name));
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
                _ChildNameSetting(
                  childName: _settings.childName,
                  onTap: _openChildNameEditor,
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
                  onEnabledChanged: (value) {
                    _updateSettings(
                      _settings.copyWith(
                        ambientMusicEnabled: value,
                      ),
                    );
                  },
                  volume: _settings.ambientMusicVolume,
                  onVolumeChanged: (value) {
                    _updateSettings(
                      _settings.copyWith(
                        ambientMusicVolume: value,
                      ),
                    );
                  },
                  selectedTrackId: _settings.ambientMusicTrackId,
                  selectedPlaybackMode: _settings.ambientMusicPlaybackMode,
                  onTrackChanged: (trackId) {
                    _updateSettings(
                      _settings.copyWith(
                        ambientMusicTrackId: trackId,
                      ),
                    );
                  },
                  onPlaybackModeChanged: (mode) {
                    _updateSettings(
                      _settings.copyWith(
                        ambientMusicPlaybackMode: mode,
                      ),
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
  final ValueChanged<bool> onEnabledChanged;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final String selectedTrackId;
  final AmbientMusicPlaybackMode selectedPlaybackMode;
  final ValueChanged<String> onTrackChanged;
  final ValueChanged<AmbientMusicPlaybackMode> onPlaybackModeChanged;

  const _MusicSetting({
    required this.enabled,
    required this.volume,
    required this.onEnabledChanged,
    required this.onVolumeChanged,
    required this.selectedTrackId,
    required this.selectedPlaybackMode,
    required this.onTrackChanged,
    required this.onPlaybackModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Música ambiental',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: const Text(
            'Reproduce música suave mientras se usa la app.',
          ),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MusicDropdown<String>(
                label: 'Canción',
                value: selectedTrackId,
                items: [
                  for (final track in AmbientMusicTracks.all)
                    DropdownMenuItem<String>(
                      value: track.id,
                      child: Text(track.name),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  onTrackChanged(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MusicDropdown<AmbientMusicPlaybackMode>(
                label: 'Reproducción',
                value: selectedPlaybackMode,
                items: const [
                  DropdownMenuItem<AmbientMusicPlaybackMode>(
                    value: AmbientMusicPlaybackMode.loopSelected,
                    child: Text('Bucle'),
                  ),
                  DropdownMenuItem<AmbientMusicPlaybackMode>(
                    value: AmbientMusicPlaybackMode.sequential,
                    child: Text('Seguida'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  onPlaybackModeChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Volumen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade800,
          ),
        ),
        Slider(
          value: volume,
          min: 0,
          max: 1,
          divisions: 10,
          label: '${(volume * 100).round()}%',
          onChanged: onVolumeChanged,
        ),
        const SizedBox(height: 4),
        _MusicModeHelpText(
          selectedPlaybackMode: selectedPlaybackMode,
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

class _ChildNameSetting extends StatelessWidget {
  final String childName;
  final VoidCallback onTap;

  const _ChildNameSetting({required this.childName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cleanName = childName.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.shade200, width: 1.4),
        ),
        child: Row(
          children: [
            Icon(Icons.child_care, size: 30, color: Colors.blueGrey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre del niño/a',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cleanName.isEmpty ? 'Sin nombre' : cleanName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit),
          ],
        ),
      ),
    );
  }
}


class _MusicDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _MusicDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.blueGrey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.blueGrey.shade100,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.blueGrey.shade100,
            width: 1.2,
          ),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MusicModeHelpText extends StatelessWidget {
  final AmbientMusicPlaybackMode selectedPlaybackMode;

  const _MusicModeHelpText({
    required this.selectedPlaybackMode,
  });

  @override
  Widget build(BuildContext context) {
    final text = switch (selectedPlaybackMode) {
      AmbientMusicPlaybackMode.loopSelected =>
        'Bucle: repite siempre la canción seleccionada.',
      AmbientMusicPlaybackMode.sequential =>
        'Seguida: cuando termina una canción, pasa a la siguiente.',
    };

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.blueGrey.shade600,
      ),
    );
  }
}