import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/app_request.dart';

class RequestService {
  static const String _region = 'europe-west1';
  static const String _functionName = 'sendAppRequest';

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: _region,
  );

  Future<void> sendRequest(AppRequest request) async {
    try {
      final callable = _functions.httpsCallable(
        _functionName,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );

      final result = await callable.call<Map<String, dynamic>>(
        request.toPayload(),
      );

      final data = result.data;
      final isOk = data['ok'] == true;

      if (!isOk) {
        throw const RequestServiceException('No se pudo enviar la solicitud.');
      }
    } on FirebaseFunctionsException catch (error) {
      throw RequestServiceException(_mapFirebaseError(error));
    } on SocketException {
      throw const RequestServiceException('No hay conexión a internet.');
    } catch (_) {
      throw const RequestServiceException(
        'No se pudo enviar la solicitud. Inténtalo de nuevo.',
      );
    }
  }

  String _mapFirebaseError(FirebaseFunctionsException error) {
    final message = error.message?.trim();

    if (message != null && message.isNotEmpty) {
      return message;
    }

    switch (error.code) {
      case 'invalid-argument':
        return 'Revisa el mensaje de la solicitud.';
      case 'unavailable':
        return 'Servicio no disponible. Inténtalo más tarde.';
      case 'deadline-exceeded':
        return 'La solicitud ha tardado demasiado.';
      default:
        return 'No se pudo enviar la solicitud.';
    }
  }
}

class RequestServiceException implements Exception {
  final String message;

  const RequestServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
