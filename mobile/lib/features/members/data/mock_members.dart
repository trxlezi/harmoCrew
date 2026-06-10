import '../domain/member.dart';

class MockMembers {
  const MockMembers._();

  static List<Member> seed() {
    return const [
      Member(
        name: 'Ana',
        role: 'Vocal',
        availability: 'Segunda e quarta a noite',
        instruments: ['Voz'],
        specialties: ['Vocal principal', 'Harmonia'],
        styles: ['MPB', 'Pop'],
        city: 'Sao Paulo',
      ),
      Member(
        name: 'Bruno',
        role: 'Guitarra',
        availability: 'Sabados pela manha',
        instruments: ['Guitarra', 'Violao'],
        specialties: ['Arranjo', 'Direcao musical'],
        styles: ['Pop Rock', 'Indie'],
        city: 'Campinas',
      ),
    ];
  }
}
