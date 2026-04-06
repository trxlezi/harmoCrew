import '../domain/member.dart';

class MockMembers {
  const MockMembers._();

  static List<Member> seed() {
    return const [
      Member(
        name: 'Ana',
        role: 'Vocal',
        availability: 'Segunda e quarta a noite',
      ),
      Member(
        name: 'Bruno',
        role: 'Guitarra',
        availability: 'Sabados pela manha',
      ),
    ];
  }
}
