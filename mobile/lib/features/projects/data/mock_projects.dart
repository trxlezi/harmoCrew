import '../domain/project.dart';

class MockProjects {
  const MockProjects._();

  static List<Project> all() {
    return const [
      Project(
        title: 'Sessao Neo Soul',
        style: 'Neo Soul',
        summary: 'Busca baixista e tecladista para ensaio gravado.',
        status: 'Aberto para colaboracao',
        needs: ['Baixo', 'Teclado', 'Backing vocal'],
      ),
      Project(
        title: 'Beat Tape Colaborativa',
        style: 'Lo-fi / Hip Hop',
        summary: 'Coletanea autoral com trocas remotas entre produtores.',
        status: 'Em selecao',
        needs: ['Beatmaker', 'Mixagem', 'Capa visual'],
      ),
      Project(
        title: 'Show Universitario',
        style: 'Pop Rock',
        summary: 'Set de 40 minutos para evento do centro academico.',
        status: 'Confirmado',
        needs: ['Bateria', 'Segunda guitarra'],
      ),
    ];
  }
}
