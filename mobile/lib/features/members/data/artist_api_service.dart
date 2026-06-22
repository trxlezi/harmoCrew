import '../../../core/api/api_client.dart';
import '../../collaboration/models/artist_profile.dart';
import '../domain/member.dart';

class ArtistApiService {
  /*
   * Service responsavel pelos endpoints de artistas.
   *
   * A tela de talentos/perfil usa ArtistProfile no Flutter, mas a API responde
   * campos com nomes do backend, como stageName, mainSpecialty e musicalStyles.
   * Este arquivo faz a traducao entre os dois formatos.
   */
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
  /*
   * userId liga o Artist ao User autenticado.
   * O mobile usa essa relacao como fallback seguro para descobrir "qual artista
   * pertence ao usuario logado" quando uma sessao antiga ainda nao tem artistId.
   */
  final mainSpecialty = (json['mainSpecialty'] ?? '').toString();

  return ArtistProfile(
    id: (json['id'] ?? '').toString(),
    name: (json['stageName'] ?? json['name'] ?? 'Artista').toString(),
    userId: json['userId']?.toString(),
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
  // Garante que listas vindas do JSON virem List<String> usada pelos widgets.
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }

  return const [];
}
