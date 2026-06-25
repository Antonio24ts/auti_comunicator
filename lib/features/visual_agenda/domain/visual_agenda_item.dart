import '../../../../data/models/pictogram.dart';

class VisualAgendaItem {
  final String pictogramId;
  final String text;
  final String imagePath;

  const VisualAgendaItem({
    required this.pictogramId,
    required this.text,
    required this.imagePath,
  });

  factory VisualAgendaItem.fromPictogram(Pictogram pictogram) {
    return VisualAgendaItem(
      pictogramId: pictogram.id,
      text: pictogram.text,
      imagePath: pictogram.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {'pictogramId': pictogramId, 'text': text, 'imagePath': imagePath};
  }

  factory VisualAgendaItem.fromJson(Map<String, dynamic> json) {
    return VisualAgendaItem(
      pictogramId: json['pictogramId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
    );
  }
}
