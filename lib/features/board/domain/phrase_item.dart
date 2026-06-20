class PhraseItem {
  final String text;
  final String imagePath;
  final bool isTypedText;

  const PhraseItem({
    required this.text,
    this.imagePath = '',
    this.isTypedText = false,
  });

  PhraseItem copyWith({String? text, String? imagePath, bool? isTypedText}) {
    return PhraseItem(
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      isTypedText: isTypedText ?? this.isTypedText,
    );
  }
}
