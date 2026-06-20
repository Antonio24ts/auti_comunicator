class SimpleCalculatorEngine {
  const SimpleCalculatorEngine._();

  static String evaluate(String expression) {
    final cleanExpression = expression.replaceAll(' ', '');

    if (cleanExpression.isEmpty) {
      return '';
    }

    final tokens = _tokenize(cleanExpression);

    if (tokens.isEmpty) {
      return '';
    }

    final result = _evaluateTokens(tokens);

    return _formatResult(result);
  }

  static List<String> _tokenize(String expression) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];

      if (_isDigit(char)) {
        buffer.write(char);
        continue;
      }

      if (_isOperator(char)) {
        if (buffer.isEmpty) {
          throw const FormatException('Expresión no válida');
        }

        tokens.add(buffer.toString());
        buffer.clear();
        tokens.add(char);
        continue;
      }

      throw const FormatException('Carácter no válido');
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    if (tokens.isEmpty || _isOperator(tokens.last)) {
      throw const FormatException('Expresión incompleta');
    }

    return tokens;
  }

  static double _evaluateTokens(List<String> tokens) {
    final numbers = <double>[];
    final operators = <String>[];

    for (final token in tokens) {
      if (_isOperator(token)) {
        operators.add(token);
      } else {
        numbers.add(double.parse(token));
      }
    }

    var index = 0;

    while (index < operators.length) {
      final operator = operators[index];

      if (operator != '×' && operator != '÷') {
        index++;
        continue;
      }

      final left = numbers[index];
      final right = numbers[index + 1];

      double value;

      if (operator == '×') {
        value = left * right;
      } else {
        if (right == 0) {
          throw const FormatException('No se puede dividir entre 0');
        }

        value = left / right;
      }

      numbers[index] = value;
      numbers.removeAt(index + 1);
      operators.removeAt(index);
    }

    var result = numbers.first;

    for (var i = 0; i < operators.length; i++) {
      final operator = operators[i];
      final nextNumber = numbers[i + 1];

      if (operator == '+') {
        result += nextNumber;
      } else if (operator == '-') {
        result -= nextNumber;
      }
    }

    return result;
  }

  static String _formatResult(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static bool _isDigit(String value) {
    return RegExp(r'^[0-9]$').hasMatch(value);
  }

  static bool _isOperator(String value) {
    return value == '+' || value == '-' || value == '×' || value == '÷';
  }
}
