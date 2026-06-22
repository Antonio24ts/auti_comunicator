enum AppRequestType { pictogram, game, category, bug, other }

extension AppRequestTypeUi on AppRequestType {
  String get id {
    switch (this) {
      case AppRequestType.pictogram:
        return 'pictogram';
      case AppRequestType.game:
        return 'game';
      case AppRequestType.category:
        return 'category';
      case AppRequestType.bug:
        return 'bug';
      case AppRequestType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case AppRequestType.pictogram:
        return 'Pictograma';
      case AppRequestType.game:
        return 'Juego';
      case AppRequestType.category:
        return 'Categoría';
      case AppRequestType.bug:
        return 'Error';
      case AppRequestType.other:
        return 'Otro';
    }
  }
}

class AppRequest {
  final AppRequestType type;
  final String message;
  final String childName;
  final String platform;
  final String appVersion;

  const AppRequest({
    required this.type,
    required this.message,
    required this.childName,
    required this.platform,
    required this.appVersion,
  });

  Map<String, dynamic> toPayload() {
    return {
      'type': type.id,
      'message': message.trim(),
      'childName': childName.trim(),
      'platform': platform,
      'appVersion': appVersion,
    };
  }
}
