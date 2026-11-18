class Member {
  const Member({
    required this.name,
    required this.role,
    required this.availability,
    this.instruments = const [],
    this.specialties = const [],
    this.styles = const [],
    this.city = '',
  });

  final String name;
  final String role;
  final String availability;
  final List<String> instruments;
  final List<String> specialties;
  final List<String> styles;
  final String city;
}
