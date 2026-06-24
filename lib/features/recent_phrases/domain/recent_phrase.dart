import '../../board/domain/phrase_item.dart';

class RecentPhrase {
  final String id;
  final String text;
  final List<PhraseItem> items;
  final DateTime createdAt;

  const RecentPhrase({
    required this.id,
    required this.text,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'items': items
          .map(
            (item) => {
              'text': item.text,
              'imagePath': item.imagePath,
              'isTypedText': item.isTypedText,
            },
          )
          .toList(),
    };
  }

  factory RecentPhrase.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return RecentPhrase(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (itemJson) => PhraseItem(
                    text: itemJson['text']?.toString() ?? '',
                    imagePath: itemJson['imagePath']?.toString() ?? '',
                    isTypedText: itemJson['isTypedText'] == true,
                  ),
                )
                .where((item) => item.text.trim().isNotEmpty)
                .toList()
          : <PhraseItem>[],
    );
  }
}
