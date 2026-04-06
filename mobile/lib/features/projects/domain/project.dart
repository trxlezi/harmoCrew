class Project {
  const Project({
    required this.title,
    required this.style,
    required this.summary,
    required this.status,
    required this.needs,
  });

  final String title;
  final String style;
  final String summary;
  final String status;
  final List<String> needs;
}
