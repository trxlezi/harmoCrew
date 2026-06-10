import '../models/application.dart';
import '../models/artist_profile.dart';
import '../models/collaboration_message.dart';
import '../models/decision_record.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import '../models/rehearsal.dart';
import '../models/weekly_goal.dart';

class MockCollaborationData {
  const MockCollaborationData._();

  static List<ArtistProfile> artists() {
    return const [
      ArtistProfile(
        id: 'artist-marina',
        name: 'Marina Costa',
        email: 'marina@harmocrew.app',
        bio: 'Vocalista e compositora focada em pop alternativo.',
        specialties: ['Vocal principal', 'Composicao', 'Presenca de palco'],
        availability: 'Noites de quarta e sexta',
        instruments: ['Voz', 'Teclado'],
        styles: ['Pop alternativo', 'Neo Soul', 'MPB'],
        city: 'Sao Paulo',
      ),
      ArtistProfile(
        id: 'artist-bruno',
        name: 'Bruno Lima',
        email: 'bruno@harmocrew.app',
        bio: 'Guitarrista com experiencia em shows universitarios.',
        specialties: ['Guitarra', 'Arranjo', 'Direcao musical'],
        availability: 'Sabados pela manha',
        instruments: ['Guitarra', 'Violao'],
        styles: ['Pop Rock', 'Indie', 'Blues'],
        city: 'Campinas',
      ),
      ArtistProfile(
        id: 'artist-luiza',
        name: 'Luiza Nascimento',
        email: 'luiza@harmocrew.app',
        bio: 'Baixista e produtora com foco em grooves de soul e R&B.',
        specialties: ['Baixo', 'Producao musical', 'Groove'],
        availability: 'Tercas e quintas a noite',
        instruments: ['Baixo', 'Synth bass'],
        styles: ['Neo Soul', 'R&B', 'Funk'],
        city: 'Santo Andre',
      ),
    ];
  }

  static List<Project> projects() {
    return const [
      Project(
        id: 'project-neo-soul',
        title: 'Sessao Neo Soul',
        style: 'Neo Soul',
        summary: 'Busca baixista e tecladista para ensaio gravado.',
        status: 'Aberto para colaboracao',
        ownerArtistId: 'artist-marina',
        needs: ['Baixo', 'Teclado', 'Backing vocal'],
      ),
      Project(
        id: 'project-show',
        title: 'Show Universitario',
        style: 'Pop Rock',
        summary: 'Set de 40 minutos para evento do centro academico.',
        status: 'Confirmado',
        ownerArtistId: 'artist-bruno',
        needs: ['Bateria', 'Segunda guitarra'],
      ),
    ];
  }

  static List<Application> applications() {
    return const [
      Application(
        id: 'application-1',
        projectId: 'Sessao Neo Soul',
        artistId: 'artist-bruno',
        message: 'Posso assumir as guitarras e ajudar nos arranjos.',
        specialty: 'Guitarra',
        availability: 'Sabados pela manha',
        status: ApplicationStatus.pending,
        createdAt: '2026-06-09',
      ),
    ];
  }

  static List<ProjectTask> tasks() {
    return const [
      ProjectTask(
        id: 'task-1',
        projectId: 'project-neo-soul',
        title: 'Fechar repertorio principal',
        assignedToArtistId: 'artist-marina',
        dueDate: '2026-06-12',
        priority: ProjectTaskPriority.high,
        status: ProjectTaskStatus.doing,
      ),
      ProjectTask(
        id: 'task-2',
        projectId: 'project-show',
        title: 'Confirmar ordem das musicas',
        assignedToArtistId: 'artist-bruno',
        dueDate: '2026-06-14',
        priority: ProjectTaskPriority.medium,
        status: ProjectTaskStatus.todo,
      ),
    ];
  }

  static List<Rehearsal> rehearsals() {
    return const [
      Rehearsal(
        id: 'rehearsal-1',
        projectId: 'project-show',
        title: 'Ensaio geral',
        date: '2026-06-10',
        time: '19:30',
        location: 'Sala B - Centro Cultural',
        participantArtistIds: ['artist-marina', 'artist-bruno'],
        notes: 'Repassar set completo e entradas do show.',
        status: RehearsalStatus.scheduled,
      ),
    ];
  }

  static List<DecisionRecord> decisions() {
    return const [
      DecisionRecord(
        id: 'decision-1',
        projectId: 'project-show',
        title: 'Tom das musicas definido',
        description: 'Repertorio sera ajustado para favorecer o vocal.',
        decidedByArtistId: 'artist-marina',
        decidedAt: '2026-06-08',
        impact: 'Ajusta tonalidade e ordem das musicas do show.',
        status: DecisionStatus.registered,
      ),
      DecisionRecord(
        id: 'decision-2',
        projectId: 'project-neo-soul',
        title: 'Gravar guia antes do ensaio',
        description: 'A guia vocal sera gravada antes da sessao presencial.',
        decidedByArtistId: 'artist-bruno',
        decidedAt: '2026-06-09',
        impact: 'Reduz retrabalho durante o ensaio gravado.',
        status: DecisionStatus.reviewed,
      ),
    ];
  }

  static List<CollaborationMessage> messages() {
    return const [
      CollaborationMessage(
        id: 'message-1',
        projectId: 'project-neo-soul',
        senderArtistId: 'artist-marina',
        content: 'Vamos priorizar a guia vocal antes do proximo ensaio.',
        sentAt: '2026-06-09 15:20',
        type: CollaborationMessageType.message,
      ),
      CollaborationMessage(
        id: 'message-2',
        projectId: 'project-show',
        senderArtistId: 'artist-bruno',
        content: 'Pendencia: confirmar transporte dos equipamentos.',
        sentAt: '2026-06-10 10:15',
        type: CollaborationMessageType.pending,
      ),
    ];
  }

  static List<WeeklyGoal> weeklyGoals() {
    return const [
      WeeklyGoal(
        id: 'goal-1',
        projectId: 'project-neo-soul',
        title: 'Gravar guia vocal da faixa colaborativa',
        description: 'Entregar uma guia simples para orientar os arranjos.',
        ownerArtistId: 'artist-marina',
        weekLabel: 'Semana de 09/06',
        dueDate: '2026-06-14',
        status: WeeklyGoalStatus.inProgress,
      ),
      WeeklyGoal(
        id: 'goal-2',
        projectId: 'project-show',
        title: 'Revisar repertorio para o show universitario',
        description: 'Conferir ordem das musicas e tons finais.',
        ownerArtistId: 'artist-bruno',
        weekLabel: 'Semana de 09/06',
        dueDate: '2026-06-13',
        status: WeeklyGoalStatus.done,
      ),
    ];
  }
}
