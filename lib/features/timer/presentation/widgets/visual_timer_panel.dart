import 'package:flutter/material.dart';

class VisualTimerPanel extends StatelessWidget {
  final int selectedSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final ValueChanged<int> onDurationSelected;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onAddMinute;

  const VisualTimerPanel({
    super.key,
    required this.selectedSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.onDurationSelected,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onAddMinute,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _TimerDisplay(remainingSeconds: remainingSeconds, progress: progress),
          const SizedBox(height: 10),
          _DurationSelector(
            selectedSeconds: selectedSeconds,
            enabled: !isRunning,
            onDurationSelected: onDurationSelected,
            onAddMinute: onAddMinute,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _TimerButton(
                    label: isPaused ? 'Continuar' : 'Empezar',
                    icon: isPaused ? Icons.play_arrow : Icons.timer,
                    backgroundColor: Colors.green.shade100,
                    borderColor: Colors.green.shade500,
                    textColor: Colors.green.shade900,
                    onTap: onStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimerButton(
                    label: 'Pausar',
                    icon: Icons.pause,
                    backgroundColor: Colors.orange.shade100,
                    borderColor: Colors.orange.shade500,
                    textColor: Colors.deepOrange.shade900,
                    onTap: isRunning ? onPause : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimerButton(
                    label: 'Reiniciar',
                    icon: Icons.replay,
                    backgroundColor: Colors.red.shade50,
                    borderColor: Colors.red.shade300,
                    textColor: Colors.red.shade800,
                    onTap: onReset,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (selectedSeconds <= 0) {
      return 0;
    }

    final rawProgress = remainingSeconds / selectedSeconds;

    return rawProgress.clamp(0.0, 1.0);
  }
}

class _TimerDisplay extends StatelessWidget {
  final int remainingSeconds;
  final double progress;

  const _TimerDisplay({required this.remainingSeconds, required this.progress});

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    final timeText =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.purple.shade200, width: 1.8),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 18,
                          backgroundColor: Colors.purple.shade50,
                          color: Colors.purple.shade500,
                        ),
                      ),
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.purple.shade50,
              color: Colors.purple.shade500,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final int selectedSeconds;
  final bool enabled;
  final ValueChanged<int> onDurationSelected;
  final VoidCallback onAddMinute;

  const _DurationSelector({
    required this.selectedSeconds,
    required this.enabled,
    required this.onDurationSelected,
    required this.onAddMinute,
  });

  static const durations = [
    _TimerDuration(seconds: 60, label: '1 min'),
    _TimerDuration(seconds: 120, label: '2 min'),
    _TimerDuration(seconds: 300, label: '5 min'),
    _TimerDuration(seconds: 600, label: '10 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          for (var i = 0; i < durations.length; i++) ...[
            Expanded(
              child: _DurationButton(
                label: durations[i].label,
                isSelected: selectedSeconds == durations[i].seconds,
                enabled: enabled,
                onTap: () => onDurationSelected(durations[i].seconds),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _DurationButton(
              label: '+',
              isSelected: false,
              enabled: enabled,
              onTap: onAddMinute,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerDuration {
  final int seconds;
  final String label;

  const _TimerDuration({required this.seconds, required this.label});
}

class _DurationButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _DurationButton({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? Colors.purple.shade100 : Colors.white;
    final borderColor = isSelected
        ? Colors.purple.shade600
        : Colors.purple.shade200;
    final textColor = enabled
        ? Colors.purple.shade900
        : Colors.blueGrey.shade300;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.4 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _TimerButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_TimerButton> createState() => _TimerButtonState();
}

class _TimerButtonState extends State<_TimerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return Listener(
      onPointerDown: enabled
          ? (_) {
              setState(() {
                _isPressed = true;
              });
            }
          : null,
      onPointerUp: enabled
          ? (_) {
              setState(() {
                _isPressed = false;
              });
            }
          : null,
      onPointerCancel: enabled
          ? (_) {
              setState(() {
                _isPressed = false;
              });
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Material(
          color: enabled ? widget.backgroundColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: enabled
                ? () {
                    setState(() {
                      _isPressed = false;
                    });

                    widget.onTap?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: enabled ? widget.borderColor : Colors.grey.shade300,
                  width: _isPressed ? 2.4 : 1.7,
                ),
                boxShadow: [
                  if (enabled)
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isPressed ? 0.13 : 0.06,
                      ),
                      blurRadius: _isPressed ? 8 : 4,
                      offset: Offset(0, _isPressed ? 3 : 1),
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: 28,
                      color: enabled ? widget.textColor : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: enabled
                            ? widget.textColor
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
