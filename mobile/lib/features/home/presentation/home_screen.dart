import 'package:flutter/material.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../collaboration/models/artist_profile.dart';
import '../../collaboration/models/application.dart';
import '../../collaboration/models/decision_record.dart';
import '../../collaboration/models/project_task.dart';
import '../../collaboration/models/rehearsal.dart';
import '../../collaboration/models/weekly_goal.dart';
import '../../collaboration/screens/applications_screen.dart';
import '../../collaboration/screens/decisions_screen.dart';
import '../../collaboration/screens/messages_screen.dart';
import '../../collaboration/screens/rehearsals_screen.dart';
import '../../collaboration/screens/tasks_screen.dart';
import '../../collaboration/screens/weekly_goals_screen.dart';
import '../../collaboration/stores/collaboration_store.dart';
import '../../collaboration/widgets/collaboration_summary_card.dart';
import '../../details/presentation/details_screen.dart';
import '../../members/domain/member.dart';
import '../../members/presentation/member_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollaborationStore _store = CollaborationStore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _openMemberForm() async {
    final result = await Navigator.pushNamed(
      context,
      MemberFormScreen.routeName,
    );

    if (!mounted || result is! Member) {
      return;
    }

    try {
      await _store.createArtistFromApi(result);
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.name} adicionado com sucesso.')),
    );
  }

  void _openDetails() {
    Navigator.pushNamed(
      context,
      DetailsScreen.routeName,
      arguments: const DetailsArguments(
        title: 'Equipe harmoCrew',
        description: 'Tela conectada aos dados reais da API HarmoCrew.',
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      await _store.syncAll();
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = _store.projects;
    final members = _store.artists;
    final collaborationStore = _store;
    final pendingApplications = collaborationStore.applications
        .where((application) => application.status == ApplicationStatus.pending)
        .length;
    final doingTasks = collaborationStore.tasks
        .where((task) => task.status == ProjectTaskStatus.doing)
        .length;
    final doneTasks = collaborationStore.tasks
        .where((task) => task.status == ProjectTaskStatus.done)
        .length;
    final weekGoals = collaborationStore.weeklyGoals
        .where((goal) => _isCurrentWeek(goal.dueDate))
        .length;
    final registeredDecisions = collaborationStore.decisions
        .where((decision) => decision.status == DecisionStatus.registered)
        .length;
    final recentActivities = _recentActivities(collaborationStore);
    final upcomingDeadlines = _upcomingDeadlines(collaborationStore);

    return AppScaffold(
      title: 'harmoCrew',
      currentIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMemberForm,
        icon: const Icon(Icons.person_add),
        label: const Text('Cadastrar'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          final useSplitLayout = constraints.maxWidth >= 700 || isLandscape;
          final horizontalPadding = useSplitLayout ? 28.0 : 20.0;
          final sectionWidth = useSplitLayout
              ? (constraints.maxWidth - (horizontalPadding * 2) - 20) / 2
              : constraints.maxWidth;
          final navigationCardWidth = useSplitLayout
              ? 180.0
              : ((constraints.maxWidth - (horizontalPadding * 2) - 12) / 2)
                    .clamp(136.0, 220.0);

          return ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      const Color(0xFF2E7DA1),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Painel da banda',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Organize integrantes, acompanhe oportunidades e '
                      'mantenha o perfil pronto para colaboracoes.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _HeroMetric(
                          label: 'Integrantes',
                          value: members.length.toString(),
                        ),
                        _HeroMetric(
                          label: 'Projetos ativos',
                          value: projects.length.toString(),
                        ),
                        _HeroMetric(
                          label: 'Ensaios na semana',
                          value: collaborationStore
                              .rehearsalsInWeek(DateTime.now())
                              .toString(),
                        ),
                        _HeroMetric(
                          label: 'Metas concluidas',
                          value: collaborationStore
                              .completedGoalsInWeek(DateTime.now())
                              .toString(),
                        ),
                        _HeroMetric(
                          label: 'Candidaturas pendentes',
                          value: pendingApplications.toString(),
                        ),
                        _HeroMetric(
                          label: 'Tarefas em andamento',
                          value: doingTasks.toString(),
                        ),
                        _HeroMetric(
                          label: 'Tarefas concluidas',
                          value: doneTasks.toString(),
                        ),
                        _HeroMetric(
                          label: 'Metas da semana',
                          value: weekGoals.toString(),
                        ),
                        _HeroMetric(
                          label: 'Decisoes registradas',
                          value: registeredDecisions.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CollaborationSummaryCard(store: collaborationStore),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: sectionWidth,
                    child: _DashboardListCard(
                      title: 'Atividades recentes',
                      emptyMessage: 'Nenhuma atividade colaborativa recente.',
                      items: recentActivities,
                    ),
                  ),
                  SizedBox(
                    width: sectionWidth,
                    child: _DashboardListCard(
                      title: 'Proximos prazos',
                      emptyMessage: 'Nenhum prazo proximo encontrado.',
                      items: upcomingDeadlines,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _NavigationCard(
                    width: navigationCardWidth,
                    icon: Icons.inbox_outlined,
                    title: 'Candidaturas',
                    subtitle: '$pendingApplications pendentes',
                    onTap: () => Navigator.pushNamed(
                      context,
                      ApplicationsScreen.routeName,
                    ),
                  ),
                  _NavigationCard(
                    width: navigationCardWidth,
                    icon: Icons.task_alt_outlined,
                    title: 'Tarefas',
                    subtitle: '$doingTasks em andamento',
                    onTap: () =>
                        Navigator.pushNamed(context, TasksScreen.routeName),
                  ),
                  _NavigationCard(
                    width: navigationCardWidth,
                    icon: Icons.event_available_outlined,
                    title: 'Ensaios',
                    subtitle:
                        '${collaborationStore.rehearsalsInWeek(DateTime.now())} na semana',
                    onTap: () => Navigator.pushNamed(
                      context,
                      RehearsalsScreen.routeName,
                    ),
                  ),
                  _NavigationCard(
                    width: navigationCardWidth,
                    icon: Icons.history_outlined,
                    title: 'Decisoes',
                    subtitle: '$registeredDecisions registradas',
                    onTap: () =>
                        Navigator.pushNamed(context, DecisionsScreen.routeName),
                  ),
                  _NavigationCard(
                    width: navigationCardWidth,
                    icon: Icons.flag_outlined,
                    title: 'Metas',
                    subtitle: '$weekGoals na semana',
                    onTap: () => Navigator.pushNamed(
                      context,
                      WeeklyGoalsScreen.routeName,
                    ),
                  ),
                  _NavigationCard(
                    width: navigationCardWidth,
                    icon: Icons.forum_outlined,
                    title: 'Comunicacao',
                    subtitle: '${collaborationStore.messages.length} mensagens',
                    onTap: () =>
                        Navigator.pushNamed(context, MessagesScreen.routeName),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: sectionWidth,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visao geral',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Esta versao mobile prioriza os criterios '
                              'academicos consumindo os fluxos reais da API '
                              'HarmoCrew.',
                            ),
                            const SizedBox(height: 20),
                            if (useSplitLayout)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _openDetails,
                                      icon: const Icon(Icons.arrow_forward),
                                      label: const Text('Abrir detalhes'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _openMemberForm,
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Novo integrante'),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _openDetails,
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Abrir detalhes'),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _openMemberForm,
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Novo integrante'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: sectionWidth,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proximas acoes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            ...upcomingDeadlines
                                .take(3)
                                .map(
                                  (item) => _ActionRow(
                                    icon: item.icon,
                                    title: item.title,
                                    subtitle: item.subtitle,
                                  ),
                                ),
                            if (upcomingDeadlines.isEmpty)
                              const Text('Nenhuma acao pendente no momento.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Integrantes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (useSplitLayout)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: members
                      .map(
                        (member) => SizedBox(
                          width: sectionWidth,
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(member.name.substring(0, 1)),
                              ),
                              title: Text(
                                '${member.name} - ${_artistRole(member)}',
                              ),
                              subtitle: Text(member.availability),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                ...members.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(member.name.substring(0, 1)),
                        ),
                        title: Text('${member.name} - ${_artistRole(member)}'),
                        subtitle: Text(member.availability),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.tightFor(width: 120, height: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _DashboardListCard extends StatelessWidget {
  const _DashboardListCard({
    required this.title,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final List<_DashboardItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(emptyMessage)
            else
              ...items
                  .take(5)
                  .map(
                    (item) => _ActionRow(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<_DashboardItem> _recentActivities(CollaborationStore store) {
  final activities = <_DashboardItem>[];

  if (store.applications.isNotEmpty) {
    final application = store.applications.last;
    activities.add(
      _DashboardItem(
        icon: Icons.inbox_outlined,
        title: 'Candidatura criada',
        subtitle: '${application.specialty} em ${application.projectId}',
      ),
    );
  }

  if (store.tasks.isNotEmpty) {
    final task = store.tasks.last;
    activities.add(
      _DashboardItem(
        icon: Icons.task_alt_outlined,
        title: 'Tarefa atualizada',
        subtitle: '${task.title} - ${_taskStatusLabel(task.status)}',
      ),
    );
  }

  if (store.rehearsals.isNotEmpty) {
    final rehearsal = store.rehearsals.last;
    activities.add(
      _DashboardItem(
        icon: Icons.event_available_outlined,
        title: 'Ensaio agendado',
        subtitle: '${rehearsal.date} as ${rehearsal.time}',
      ),
    );
  }

  if (store.decisions.isNotEmpty) {
    final decision = store.decisions.last;
    activities.add(
      _DashboardItem(
        icon: Icons.history_outlined,
        title: 'Decisao registrada',
        subtitle: decision.title,
      ),
    );
  }

  if (store.messages.isNotEmpty) {
    final message = store.messages.last;
    activities.add(
      _DashboardItem(
        icon: Icons.forum_outlined,
        title: 'Mensagem enviada',
        subtitle: message.content,
      ),
    );
  }

  return activities;
}

String _artistRole(ArtistProfile artist) {
  return artist.specialties.isEmpty ? 'Artista' : artist.specialties.first;
}

List<_DashboardItem> _upcomingDeadlines(CollaborationStore store) {
  final items = <_DashboardItem>[];

  for (final task in store.tasks.where((task) {
    return task.status != ProjectTaskStatus.done && _isUpcoming(task.dueDate);
  })) {
    items.add(
      _DashboardItem(
        icon: Icons.task_alt_outlined,
        title: task.title,
        subtitle: 'Tarefa vence em ${task.dueDate}',
      ),
    );
  }

  for (final goal in store.weeklyGoals.where((goal) {
    return goal.status != WeeklyGoalStatus.done && _isUpcoming(goal.dueDate);
  })) {
    items.add(
      _DashboardItem(
        icon: Icons.flag_outlined,
        title: goal.title,
        subtitle: 'Meta vence em ${goal.dueDate}',
      ),
    );
  }

  for (final rehearsal in store.rehearsals.where((rehearsal) {
    return rehearsal.status == RehearsalStatus.scheduled &&
        _isUpcoming(rehearsal.date);
  })) {
    items.add(
      _DashboardItem(
        icon: Icons.event_available_outlined,
        title: rehearsal.title,
        subtitle: '${rehearsal.date} as ${rehearsal.time}',
      ),
    );
  }

  return items;
}

bool _isCurrentWeek(String dateText) {
  final parsed = DateTime.tryParse(dateText);
  if (parsed == null) {
    return false;
  }

  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final end = start.add(const Duration(days: 7));
  final date = DateTime(parsed.year, parsed.month, parsed.day);

  return !date.isBefore(start) && date.isBefore(end);
}

bool _isUpcoming(String dateText) {
  final parsed = DateTime.tryParse(dateText);
  if (parsed == null) {
    return false;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(parsed.year, parsed.month, parsed.day);
  final days = date.difference(today).inDays;

  return days >= 0 && days <= 7;
}

String _taskStatusLabel(ProjectTaskStatus status) {
  return switch (status) {
    ProjectTaskStatus.todo => 'A fazer',
    ProjectTaskStatus.doing => 'Em andamento',
    ProjectTaskStatus.done => 'Concluida',
  };
}
