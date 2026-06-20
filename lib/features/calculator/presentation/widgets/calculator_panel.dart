import 'package:flutter/material.dart';

class CalculatorPanel extends StatelessWidget {
  final String expression;
  final String result;
  final ValueChanged<String> onKeyPressed;

  const CalculatorPanel({
    super.key,
    required this.expression,
    required this.result,
    required this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _CalculatorDisplay(expression: expression, result: result),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              children: [
                _CalculatorRow(
                  keys: const ['7', '8', '9', '+'],
                  onKeyPressed: onKeyPressed,
                ),
                const SizedBox(height: 6),
                _CalculatorRow(
                  keys: const ['4', '5', '6', '-'],
                  onKeyPressed: onKeyPressed,
                ),
                const SizedBox(height: 6),
                _CalculatorRow(
                  keys: const ['1', '2', '3', '×'],
                  onKeyPressed: onKeyPressed,
                ),
                const SizedBox(height: 6),
                _CalculatorRow(
                  keys: const ['C', '0', '⌫', '÷'],
                  onKeyPressed: onKeyPressed,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: _CalculatorButton(
                    label: '=',
                    isResultButton: true,
                    onTap: () => onKeyPressed('='),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorDisplay extends StatelessWidget {
  final String expression;
  final String result;

  const _CalculatorDisplay({required this.expression, required this.result});

  @override
  Widget build(BuildContext context) {
    final displayText = _getDisplayText();

    return Container(
      width: double.infinity,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade200, width: 1.6),
      ),
      alignment: Alignment.centerRight,
      child: Text(
        displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: displayText == '0' ? Colors.grey : Colors.black87,
        ),
      ),
    );
  }

  String _getDisplayText() {
    final cleanExpression = expression.trim();
    final cleanResult = result.trim();

    if (cleanExpression.isEmpty) {
      return '0';
    }

    if (cleanResult.isEmpty) {
      return cleanExpression;
    }

    return '$cleanExpression = $cleanResult';
  }
}

class _CalculatorRow extends StatelessWidget {
  final List<String> keys;
  final ValueChanged<String> onKeyPressed;

  const _CalculatorRow({required this.keys, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            Expanded(
              child: _CalculatorButton(
                label: keys[i],
                onTap: () => onKeyPressed(keys[i]),
              ),
            ),
            if (i != keys.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _CalculatorButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isResultButton;

  const _CalculatorButton({
    required this.label,
    required this.onTap,
    this.isResultButton = false,
  });

  @override
  State<_CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<_CalculatorButton> {
  bool _isPressed = false;

  bool get _isOperator {
    return widget.label == '+' ||
        widget.label == '-' ||
        widget.label == '×' ||
        widget.label == '÷';
  }

  bool get _isUtility {
    return widget.label == 'C' || widget.label == '⌫';
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;

    if (widget.isResultButton) {
      backgroundColor = Colors.green.shade100;
      borderColor = Colors.green.shade500;
      textColor = Colors.green.shade900;
    } else if (_isOperator) {
      backgroundColor = Colors.orange.shade100;
      borderColor = Colors.orange.shade400;
      textColor = Colors.deepOrange.shade900;
    } else if (_isUtility) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade800;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.blueGrey.shade200;
      textColor = Colors.black87;
    }

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
        scale: _isPressed ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              setState(() {
                _isPressed = false;
              });

              widget.onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: _isPressed ? 2.3 : 1.6,
                ),
                boxShadow: [
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
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.isResultButton ? 42 : 30,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
