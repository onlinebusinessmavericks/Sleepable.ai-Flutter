class SleepQuizResult {
  final String title;
  final String summary;
  final List<String> suggestions;

  SleepQuizResult({
    required this.title,
    required this.summary,
    required this.suggestions,
  });

  factory SleepQuizResult.fromJson(Map<String, dynamic> json) {
    return SleepQuizResult(
      title: json['title'],
      summary: json['summary'],
      suggestions: List<String>.from(json['suggestions']),
    );
  }
}
