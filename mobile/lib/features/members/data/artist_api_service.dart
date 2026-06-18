import '../../../core/api/api_client.dart';
import '../../collaboration/models/artist_profile.dart';
import '../domain/member.dart';

class ArtistApiService {
  ArtistApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ArtistProfile>> listArtists() async {
    final response = await _client.get('/api/artists') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(_artistFromJson)
        .toList(growable: false);
  }

  Future<ArtistProfile> createArtist(Member member) async {
    final response =
        await _client.post('/api/artists', body: _artistRequest(member))
            as Map<String, dynamic>;
    return _artistFromJson(response);
  }

  Map<String, dynamic> _artistRequest(Member member) {
    return {
      'stageName': member.name.trim(),
      'bio': 'Perfil cadastrado pelo app mobile.',
      'mainSpecialty': member.role.trim(),
      'instruments': member.instruments,
      'musicalStyles': member.styles,
      'availability': member.availability.trim(),
      'city': member.city.trim(),
    };
  }
}

ArtistProfile _artistFromJson(Map<String, dynamic> json) {
  final mainSpecialty = (json['mainSpecialty'] ?? '').toString();

  return ArtistProfile(
    id: (json['id'] ?? '').toString(),
    name: (json['stageName'] ?? json['name'] ?? 'Artista').toString(),
    email: (json['email'] ?? '').toString(),
    bio: (json['bio'] ?? '').toString(),
    specialties: mainSpecialty.isEmpty ? const [] : [mainSpecialty],
    availability: (json['availability'] ?? '').toString(),
    instruments: _stringList(json['instruments']),
    styles: _stringList(json['musicalStyles']),
    city: (json['city'] ?? '').toString(),
  );
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }

  return const [];
}
