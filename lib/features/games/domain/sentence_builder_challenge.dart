enum SentenceBuilderMode { audioPrompt, textPrompt, imagePrompt }

class SentenceBuilderChallenge {
  final String id;
  final int level;
  final SentenceBuilderMode mode;
  final String spokenSentence;
  final String? promptImagePath;
  final List<String> targetPictogramIds;
  final List<String> optionPictogramIds;

  const SentenceBuilderChallenge({
    required this.id,
    required this.level,
    required this.mode,
    required this.spokenSentence,
    this.promptImagePath,
    required this.targetPictogramIds,
    required this.optionPictogramIds,
  });
}
