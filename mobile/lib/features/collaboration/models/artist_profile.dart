class ArtistProfile {
  const ArtistProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.specialties,
    required this.availability,
    this.instruments = const [],
    this.styles = const [],
    this.city = '',
  });

  final String id;
  final String name;
  final String email;
  final String bio;
  final List<String> specialties;
  final String availability;
  final List<String> instruments;
  final List<String> styles;
  final String city;

  ArtistProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    List<String>? specialties,
    String? availability,
    List<String>? instruments,
    List<String>? styles,
    String? city,
  }) {
    return ArtistProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      availability: availability ?? this.availability,
      instruments: instruments ?? this.instruments,
      styles: styles ?? this.styles,
      city: city ?? this.city,
    );
  }
}
