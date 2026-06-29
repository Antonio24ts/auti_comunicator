import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../services/speech_services.dart';
import '../../domain/calm_item.dart';

typedef CalmPhraseSelected =
    void Function({required String text, required String imagePath});

class CalmPanel extends StatefulWidget {
  final SpeechService speechService;
  final CalmPhraseSelected onAddToPhrase;

  const CalmPanel({
    super.key,
    required this.speechService,
    required this.onAddToPhrase,
  });

  @override
  State<CalmPanel> createState() => _CalmPanelState();
}

class _CalmPanelState extends State<CalmPanel> {
  static const int _calmTimerInitialSeconds = 60;

  final List<CalmItem> _mainItems = const [
    CalmItem(
      id: 'calm_nervioso',
      title: 'Estoy nervioso',
      phraseText: 'Estoy nervioso',
      spokenText: 'Estoy nervioso',
      imagePath: 'assets/images/calma/nervioso.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_enfadado',
      title: 'Estoy enfadado',
      phraseText: 'Estoy enfadado',
      spokenText: 'Estoy enfadado',
      imagePath: 'assets/images/calma/enfadado.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_triste',
      title: 'Estoy triste',
      phraseText: 'Estoy triste',
      spokenText: 'Estoy triste',
      imagePath: 'assets/images/calma/triste.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_cansado',
      title: 'Estoy cansado',
      phraseText: 'Estoy cansado',
      spokenText: 'Estoy cansado',
      imagePath: 'assets/images/calma/cansado.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_ruido',
      title: 'Hay mucho ruido',
      phraseText: 'Hay mucho ruido',
      spokenText: 'Hay mucho ruido',
      imagePath: 'assets/images/calma/ruido.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_luz',
      title: 'Me molesta la luz',
      phraseText: 'Me molesta la luz',
      spokenText: 'Me molesta la luz',
      imagePath: 'assets/images/calma/luz.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_ropa',
      title: 'Me molesta la ropa',
      phraseText: 'Me molesta la ropa',
      spokenText: 'Me molesta la ropa',
      imagePath: 'assets/images/calma/ropa.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_duele',
      title: 'Me duele',
      phraseText: 'Me duele',
      spokenText: 'Me duele',
      imagePath: 'assets/images/calma/duele.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_ayuda',
      title: 'Necesito ayuda',
      phraseText: 'Necesito ayuda',
      spokenText: 'Necesito ayuda',
      imagePath: 'assets/images/calma/ayuda.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_descansar',
      title: 'Necesito descansar',
      phraseText: 'Necesito descansar',
      spokenText: 'Necesito descansar',
      imagePath: 'assets/images/calma/descansar.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_solo',
      title: 'Quiero estar solo',
      phraseText: 'Quiero estar solo',
      spokenText: 'Quiero estar solo',
      imagePath: 'assets/images/calma/solo.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_salir',
      title: 'Quiero salir',
      phraseText: 'Quiero salir',
      spokenText: 'Quiero salir',
      imagePath: 'assets/images/calma/salir.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_auriculares',
      title: 'Necesito auriculares',
      phraseText: 'Necesito auriculares',
      spokenText: 'Necesito auriculares',
      imagePath: 'assets/images/calma/auriculares.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_abrazo',
      title: 'Quiero un abrazo',
      phraseText: 'Quiero un abrazo',
      spokenText: 'Quiero un abrazo',
      imagePath: 'assets/images/calma/abrazo.png',
      type: CalmItemType.phrase,
    ),
    CalmItem(
      id: 'calm_no_puedo_mas',
      title: 'No puedo más',
      phraseText: 'No puedo más',
      spokenText: 'No puedo más',
      imagePath: 'assets/images/calma/no_puedo_mas.png',
      type: CalmItemType.phrase,
    ),
  ];

  final List<CalmItem> _actionItems = const [
    CalmItem(
      id: 'calm_respira',
      title: 'Respirar',
      phraseText: 'Necesito respirar',
      spokenText: 'Vamos a respirar',
      imagePath: 'assets/images/calma/respirar.png',
      type: CalmItemType.breathing,
    ),
    CalmItem(
      id: 'calm_sitio_tranquilo',
      title: 'Sitio tranquilo',
      phraseText: 'Necesito ir a un sitio tranquilo',
      spokenText: 'Necesito ir a un sitio tranquilo',
      imagePath: 'assets/images/calma/sitio_tranquilo.png',
      type: CalmItemType.quietPlace,
    ),
    CalmItem(
      id: 'calm_beber_agua',
      title: 'Beber agua',
      phraseText: 'Necesito beber agua',
      spokenText: 'Necesito beber agua',
      imagePath: 'assets/images/calma/beber_agua.png',
      type: CalmItemType.drinkWater,
    ),
    CalmItem(
      id: 'calm_temporizador',
      title: 'Tiempo de calma',
      phraseText: 'Necesito un momento de calma',
      spokenText: 'Necesito un momento de calma',
      imagePath: 'assets/images/calma/temporizador_calma.png',
      type: CalmItemType.calmTimer,
    ),
  ];

  Timer? _breathingTimer;
  bool _isBreathingActive = false;
  int _breathingStepIndex = 0;

  Timer? _calmTimer;
  int _remainingCalmSeconds = _calmTimerInitialSeconds;
  bool _isCalmTimerRunning = false;

  final List<String> _breathingSteps = const ['Inspira', 'Mantén', 'Suelta'];

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _calmTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCalmItemTap(CalmItem item) async {
    switch (item.type) {
      case CalmItemType.phrase:
      case CalmItemType.quietPlace:
      case CalmItemType.drinkWater:
        widget.onAddToPhrase(text: item.phraseText, imagePath: item.imagePath);
        await widget.speechService.speakPhrase(item.spokenText);
        break;

      case CalmItemType.breathing:
        widget.onAddToPhrase(text: item.phraseText, imagePath: item.imagePath);
        await widget.speechService.speakPhrase(item.spokenText);
        _startBreathing();
        break;

      case CalmItemType.calmTimer:
        widget.onAddToPhrase(text: item.phraseText, imagePath: item.imagePath);
        await widget.speechService.speakPhrase(item.spokenText);
        _startCalmTimer();
        break;
    }
  }

  void _startBreathing() {
    _breathingTimer?.cancel();

    setState(() {
      _isBreathingActive = true;
      _breathingStepIndex = 0;
    });

    unawaited(widget.speechService.speakPhrase(_breathingSteps[0]));

    _breathingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _breathingStepIndex =
            (_breathingStepIndex + 1) % _breathingSteps.length;
      });

      unawaited(
        widget.speechService.speakPhrase(_breathingSteps[_breathingStepIndex]),
      );
    });
  }

  void _stopBreathing() {
    _breathingTimer?.cancel();

    setState(() {
      _isBreathingActive = false;
      _breathingStepIndex = 0;
    });
  }

  void _startCalmTimer() {
    if (_isCalmTimerRunning) {
      return;
    }

    _calmTimer?.cancel();

    setState(() {
      _isCalmTimerRunning = true;
      if (_remainingCalmSeconds <= 0) {
        _remainingCalmSeconds = _calmTimerInitialSeconds;
      }
    });

    _calmTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      if (_remainingCalmSeconds <= 1) {
        _finishCalmTimer();
        return;
      }

      setState(() {
        _remainingCalmSeconds--;
      });
    });
  }

  void _pauseCalmTimer() {
    _calmTimer?.cancel();

    setState(() {
      _isCalmTimerRunning = false;
    });
  }

  void _resetCalmTimer() {
    _calmTimer?.cancel();

    setState(() {
      _isCalmTimerRunning = false;
      _remainingCalmSeconds = _calmTimerInitialSeconds;
    });
  }

  void _finishCalmTimer() {
    _calmTimer?.cancel();

    setState(() {
      _isCalmTimerRunning = false;
      _remainingCalmSeconds = 0;
    });

    unawaited(widget.speechService.speakPhrase('Tiempo de calma terminado'));
  }

  String _formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _CalmHeader(
            title: 'Calma',
            subtitle: 'Comunica cómo te sientes o qué necesitas.',
          ),
          const SizedBox(height: 8),
          if (_isBreathingActive) ...[
            _BreathingPanel(
              stepText: _breathingSteps[_breathingStepIndex],
              onStop: _stopBreathing,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _CalmItemsGrid(
              items: _mainItems,
              onItemTap: _handleCalmItemTap,
            ),
          ),
          const SizedBox(height: 9),
          _CalmActionsRow(items: _actionItems, onItemTap: _handleCalmItemTap),
          const SizedBox(height: 9),
          _CalmTimerPanel(
            remainingText: _formatSeconds(_remainingCalmSeconds),
            isRunning: _isCalmTimerRunning,
            onStart: _startCalmTimer,
            onPause: _pauseCalmTimer,
            onReset: _resetCalmTimer,
          ),
        ],
      ),
    );
  }
}

class _CalmHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CalmHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.self_improvement_rounded,
          size: 36,
          color: Colors.teal.shade800,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calma',
                style: TextStyle(
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreathingPanel extends StatelessWidget {
  final String stepText;
  final VoidCallback onStop;

  const _BreathingPanel({required this.stepText, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            width: stepText == 'Inspira' ? 76 : 58,
            height: stepText == 'Inspira' ? 76 : 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal.shade100,
              border: Border.all(color: Colors.teal.shade500, width: 3),
            ),
            child: Icon(
              Icons.air_rounded,
              color: Colors.teal.shade800,
              size: 34,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              stepText,
              style: const TextStyle(
                fontSize: 38,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Parar'),
          ),
        ],
      ),
    );
  }
}

class _CalmItemsGrid extends StatelessWidget {
  final List<CalmItem> items;
  final ValueChanged<CalmItem> onItemTap;

  const _CalmItemsGrid({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return _CalmItemTile(item: item, onTap: () => onItemTap(item));
          },
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1050) {
      return 5;
    }

    if (width >= 760) {
      return 4;
    }

    return 3;
  }

  double _getChildAspectRatio(double width) {
    if (width >= 1050) {
      return 1.15;
    }

    if (width >= 760) {
      return 1.05;
    }

    return 0.95;
  }
}

class _CalmActionsRow extends StatelessWidget {
  final List<CalmItem> items;
  final ValueChanged<CalmItem> onItemTap;

  const _CalmActionsRow({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          for (final item in items) ...[
            Expanded(
              child: _CalmActionTile(item: item, onTap: () => onItemTap(item)),
            ),
            if (item != items.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CalmItemTile extends StatelessWidget {
  final CalmItem item;
  final VoidCallback onTap;

  const _CalmItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.teal.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    item.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) {
                      return Icon(
                        Icons.self_improvement_rounded,
                        color: Colors.teal.shade300,
                        size: 40,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalmActionTile extends StatelessWidget {
  final CalmItem item;
  final VoidCallback onTap;

  const _CalmActionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade300, width: 2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(
                      Icons.touch_app_rounded,
                      color: Colors.teal.shade500,
                      size: 28,
                    );
                  },
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalmTimerPanel extends StatelessWidget {
  final String remainingText;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const _CalmTimerPanel({
    required this.remainingText,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: Colors.teal.shade700, size: 28),
          const SizedBox(width: 8),
          Text(
            remainingText,
            style: const TextStyle(
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Temporizador de calma',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey.shade600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: isRunning ? onPause : onStart,
            icon: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
            ),
            label: Text(isRunning ? 'Pausar' : 'Iniciar'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}
