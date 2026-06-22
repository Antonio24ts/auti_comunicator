import 'package:flutter/material.dart';

class GamesMenuPanel extends StatelessWidget {
  final VoidCallback onOpenListenAndTouch;

  const GamesMenuPanel({super.key, required this.onOpenListenAndTouch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'Juegos',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 420,
                height: 170,
                child: _GameButton(
                  title: 'Toca lo que escuchas',
                  subtitle: 'Escucha y toca el pictograma correcto',
                  icon: Icons.hearing_rounded,
                  onTap: onOpenListenAndTouch,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onPointerUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onPointerCancel: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () {
              setState(() {
                _isPressed = false;
              });

              widget.onTap();
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.indigo.shade300,
                  width: _isPressed ? 2.8 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isPressed ? 0.16 : 0.08,
                    ),
                    blurRadius: _isPressed ? 12 : 6,
                    offset: Offset(0, _isPressed ? 5 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 48,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
