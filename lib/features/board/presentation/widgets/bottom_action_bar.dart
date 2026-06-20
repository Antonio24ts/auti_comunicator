import 'dart:async';

import 'package:flutter/material.dart';

class BottomActionBar extends StatefulWidget {
  final VoidCallback onSettingsLongPressCompleted;

  const BottomActionBar({
    super.key,
    required this.onSettingsLongPressCompleted,
  });

  @override
  State<BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<BottomActionBar> {
  static const Duration _requiredHoldDuration = Duration(seconds: 3);

  Timer? _holdTimer;
  bool _isHoldingSettings = false;
  bool _hasOpenedSettings = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startSettingsHold() {
    _holdTimer?.cancel();

    setState(() {
      _isHoldingSettings = true;
      _hasOpenedSettings = false;
    });

    _holdTimer = Timer(_requiredHoldDuration, () {
      if (!mounted || !_isHoldingSettings || _hasOpenedSettings) {
        return;
      }

      setState(() {
        _hasOpenedSettings = true;
        _isHoldingSettings = false;
      });

      widget.onSettingsLongPressCompleted();
    });
  }

  void _cancelSettingsHold() {
    _holdTimer?.cancel();

    if (!_isHoldingSettings) {
      return;
    }

    setState(() {
      _isHoldingSettings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      color: Colors.black,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Comunicador · Mantén ⚙ 3s para ajustes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _SettingsHoldButton(
            isHolding: _isHoldingSettings,
            onPointerDown: _startSettingsHold,
            onPointerUp: _cancelSettingsHold,
            onPointerCancel: _cancelSettingsHold,
          ),
        ],
      ),
    );
  }
}

class _SettingsHoldButton extends StatelessWidget {
  final bool isHolding;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;

  const _SettingsHoldButton({
    required this.isHolding,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPointerDown(),
      onPointerUp: (_) => onPointerUp(),
      onPointerCancel: (_) => onPointerCancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 48,
        height: 42,
        decoration: BoxDecoration(
          color: isHolding ? Colors.blueGrey.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHolding ? Colors.white : Colors.white24,
            width: isHolding ? 1.8 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.settings,
              color: Colors.white,
              size: isHolding ? 29 : 27,
            ),
            if (isHolding)
              const Positioned(
                right: 4,
                top: 4,
                child: SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
