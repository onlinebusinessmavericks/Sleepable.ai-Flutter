class SleeppediaItem {
  final String title;
  final String image;
  final List<SleeppediaSection> sections;

  SleeppediaItem({
    required this.title,
    required this.image,
    required this.sections,
  });
}

class SleeppediaSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  SleeppediaSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}
