import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/request_service.dart';
import '../../domain/app_request.dart';

class RequestScreen extends StatefulWidget {
  final String childName;

  const RequestScreen({super.key, required this.childName});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final RequestService _requestService = RequestService();
  final TextEditingController _messageController = TextEditingController();

  AppRequestType _selectedType = AppRequestType.pictogram;
  bool _isSending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final message = _messageController.text.trim();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (message.length < 10) {
      setState(() {
        _errorMessage = 'Escribe una solicitud un poco más detallada.';
      });
      return;
    }

    if (message.length > 800) {
      setState(() {
        _errorMessage = 'La solicitud no puede superar 800 caracteres.';
      });
      return;
    }

    setState(() {
      _isSending = true;
    });

    final request = AppRequest(
      type: _selectedType,
      message: message,
      childName: widget.childName,
      platform: Platform.operatingSystem,
      appVersion: '1.0.0',
    );

    try {
      await _requestService.sendRequest(request);

      if (!mounted) {
        return;
      }

      _messageController.clear();

      setState(() {
        _successMessage = 'Solicitud enviada correctamente.';
      });
    } on RequestServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childName = widget.childName.trim();
    final displayChildName = childName.isEmpty ? 'Sin nombre' : childName;

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text('Solicitudes y sugerencias'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey.shade900,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.blueGrey.shade100,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RequestIntro(childName: displayChildName),
                    const SizedBox(height: 18),
                    _RequestTypeDropdown(
                      selectedType: _selectedType,
                      onChanged: (type) {
                        setState(() {
                          _selectedType = type;
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _RequestMessageField(
                      controller: _messageController,
                      enabled: !_isSending,
                      onChanged: (_) {
                        if (_errorMessage == null && _successMessage == null) {
                          return;
                        }

                        setState(() {
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _PrivacyNotice(),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      _StatusBox(
                        text: _errorMessage!,
                        icon: Icons.error_outline_rounded,
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade800,
                        borderColor: Colors.red.shade200,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_successMessage != null) ...[
                      _StatusBox(
                        text: _successMessage!,
                        icon: Icons.check_circle_outline_rounded,
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade800,
                        borderColor: Colors.green.shade200,
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isSending ? null : _sendRequest,
                        icon: _isSending
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSending ? 'Enviando...' : 'Enviar solicitud',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

class _RequestIntro extends StatelessWidget {
  final String childName;

  const _RequestIntro({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.teal.shade700,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pide pictogramas, juegos o mejoras',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Solicitud asociada a: $childName',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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

class _RequestTypeDropdown extends StatelessWidget {
  final AppRequestType selectedType;
  final ValueChanged<AppRequestType> onChanged;

  const _RequestTypeDropdown({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Tipo de solicitud',
        filled: true,
        fillColor: Colors.blueGrey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppRequestType>(
          value: selectedType,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          items: [
            for (final type in AppRequestType.values)
              DropdownMenuItem<AppRequestType>(
                value: type,
                child: Text(
                  type.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
          onChanged: (type) {
            if (type == null) {
              return;
            }

            onChanged(type);
          },
        ),
      ),
    );
  }
}

class _RequestMessageField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _RequestMessageField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: 7,
      minLines: 5,
      maxLength: 800,
      textInputAction: TextInputAction.newline,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Mensaje',
        alignLabelWithHint: true,
        hintText:
            'Ejemplo: quiero el pictograma dentista o un juego de rutinas.',
        filled: true,
        fillColor: Colors.blueGrey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.privacy_tip_outlined,
          size: 20,
          color: Colors.blueGrey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'No incluyas datos médicos, direcciones ni información sensible. '
            'La solicitud se enviará al equipo de la app para valorar mejoras.',
            style: TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _StatusBox({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
