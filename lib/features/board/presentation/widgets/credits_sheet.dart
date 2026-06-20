import 'package:flutter/material.dart';

class CreditsSheet extends StatelessWidget {
  const CreditsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.70,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CreditsHeader(),
                const SizedBox(height: 22),
                const _CreditsSectionTitle('Pictogramas'),
                const SizedBox(height: 10),
                const Text(
                  'Los símbolos pictográficos utilizados son propiedad del '
                  'Gobierno de Aragón y han sido creados por Sergio Palao '
                  'para ARASAAC, que los distribuye bajo licencia '
                  'Creative Commons BY-NC-SA.',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                const _CreditRow(label: 'Autor', value: 'Sergio Palao'),
                const _CreditRow(label: 'Origen', value: 'ARASAAC'),
                const _CreditRow(
                  label: 'Propiedad',
                  value: 'Gobierno de Aragón',
                ),
                const _CreditRow(
                  label: 'Licencia',
                  value: 'Creative Commons BY-NC-SA',
                ),
                const SizedBox(height: 24),
                const _CreditsSectionTitle('Aplicación'),
                const SizedBox(height: 10),
                const Text(
                  'Aplicación de comunicación aumentativa y alternativa '
                  'desarrollada como proyecto personal.',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),
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

class _CreditsHeader extends StatelessWidget {
  const _CreditsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 34, color: Colors.blueGrey.shade700),
        const SizedBox(width: 12),
        const Text(
          'Créditos',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _CreditsSectionTitle extends StatelessWidget {
  final String text;

  const _CreditsSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        color: Colors.blueGrey.shade800,
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String label;
  final String value;

  const _CreditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
