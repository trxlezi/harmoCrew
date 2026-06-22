import 'package:flutter/material.dart';

import '../models/artist_profile.dart';
import '../models/decision_record.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import '../models/rehearsal.dart';
import '../models/weekly_goal.dart';
import '../stores/collaboration_store.dart';
import '../widgets/collaboration_ui.dart';
import 'decisions_screen.dart';
import 'rehearsals_screen.dart';
import 'tasks_screen.dart';
import 'weekly_goals_screen.dart';

class ResponsibilitiesScreen extends StatefulWidget {
  const ResponsibilitiesScreen({super.key});

  static const routeName = '/responsibilities';

  @override
  State<ResponsibilitiesScreen> createState() => _ResponsibilitiesScreenState();
}

class _ResponsibilitiesScreenState extends State<ResponsibilitiesScreen> {
  final CollaborationStore _store = CollaborationStore.instance;

  String? _selectedProjectId;
  bool _readInitialArguments = false;

  @override
  void initState() {
    super.initState();
    if (_store.projects.isNotEmpty) {
      _selectedProjectId = _store.projects.first.id;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readInitialArguments) {
      return;
    }

    _selectedProjectId =
        _safeProjectId(ModalRoute.of(context)?.settings.arguments, _store) ??
        _selectedProjectId;
    _readInitialArguments = true;
  }

  @override
  Widget build(BuildContext context) {
    final project = _selectedProject;
    final tasks = _store.tasksForProject(_selectedProjectId);
    final goals = _store.weeklyGoalsForProject(_selectedProjectId);
    final rehearsals = _store.rehearsalsForProject(_selectedProjectId);
    final decisions = _store.decisionsForProject(_selectedProjectId);

    final openTasks = tasks
        .where((task) => task.status != ProjectTaskStatus.done)
        .toList();
    final activeGoals = goals
        .where((goal) => goal.status == WeeklyGoalStatus.inProgress)
        .toList();
    final scheduledRehearsals = rehearsals
        .where((rehearsal) => rehearsal.status == RehearsalStatus.scheduled)
        .toList();
    final recentDecisions = decisions.take(3).toList();
    final hasPendingWork =
        openTasks.isNotEmpty ||
        activeGoals.isNotEmpty ||
        scheduledRehearsals.isNotEmpty ||
        recentDecisions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Responsabilidades')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Responsabilidades por projeto',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Prazos, pendencias e compromissos reunidos por projeto musical.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          ProjectSelector(
            value: _selectedProjectId,
            projects: _store.projects,
            label: 'Projeto',
            includeAll: false,
            onChanged: (value) => setState(() => _selectedProjectId = value),
          ),
          const SizedBox(height: 18),
          if (project != null) _ProjectOwnersCard(project: project),
          const SizedBox(height: 12),
          if (!hasPendingWork)
            const EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Nenhuma pendencia encontrada para este projeto.',
            ),
          _ResponsibilitySummaryCard(
            title: 'Tarefas',
            icon: Icons.task_alt_outlined,
            count: openTasks.length,
            subtitle: '${openTasks.length} abertas',
            onTap: () => Navigator.pushNamed(context, TasksScreen.routeName),
            children: openTasks
                .map(
                  (task) => _ResponsibilityItem(
                    title: task.title,
                    detail:
                        '${_artistName(task.assignedToArtistId)} - ${statusLabel(task.status)}',
                    chip: _deadlineLabel(task.dueDate, done: false),
                    highlighted: _isDueSoon(task.dueDate),
                    completed: false,
                  ),
                )
                .toList(),
          ),
          _ResponsibilitySummaryCard(
            title: 'Metas',
            icon: Icons.flag_outlined,
            count: activeGoals.length,
            subtitle: '${activeGoals.length} em andamento',
            onTap: () =>
                Navigator.pushNamed(context, WeeklyGoalsScreen.routeName),
            children: goals
                .map(
                  (goal) => _ResponsibilityItem(
                    title: goal.title,
                    detail:
                        '${_artistName(goal.ownerArtistId)} - ${weeklyGoalStatusLabel(goal.status)}',
                    chip: _deadlineLabel(
                      goal.dueDate,
                      done: goal.status == WeeklyGoalStatus.done,
                    ),
                    highlighted: _isDueSoon(goal.dueDate),
                    completed: goal.status == WeeklyGoalStatus.done,
                  ),
                )
                .toList(),
          ),
          _ResponsibilitySummaryCard(
            title: 'Ensaios',
            icon: Icons.event_available_outlined,
            count: scheduledRehearsals.length,
            subtitle: '${scheduledRehearsals.length} agendados',
            onTap: () =>
                Navigator.pushNamed(context, RehearsalsScreen.routeName),
            children: scheduledRehearsals
                .map(
                  (rehearsal) => _ResponsibilityItem(
                    title: rehearsal.title,
                    detail: '${rehearsal.date} ${rehearsal.time}',
                    chip: rehearsal.location,
                    highlighted: _isDueSoon(rehearsal.date),
                    completed: false,
                  ),
                )
                .toList(),
          ),
          _ResponsibilitySummaryCard(
            title: 'Decisoes',
            icon: Icons.history_outlined,
            count: recentDecisions.length,
            subtitle: '${recentDecisions.length} recentes',
            onTap: () =>
                Navigator.pushNamed(context, DecisionsScreen.routeName),
            children: recentDecisions
                .map(
                  (decision) => _ResponsibilityItem(
                    title: decision.title,
                    detail:
                        '${_artistName(decision.decidedByArtistId)} - ${decisionStatusLabel(decision.status)}',
                    chip: decision.decidedAt,
                    highlighted: decision.status == DecisionStatus.registered,
                    completed: decision.status == DecisionStatus.reviewed,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Project? get _selectedProject {
    final projectId = _selectedProjectId;
    if (projectId == null) {
      return null;
    }

    for (final project in _store.projects) {
      if (project.id == projectId) {
        return project;
      }
    }

    return null;
  }

  String _artistName(String artistId) {
    return _store.artists
        .firstWhere(
          (artist) => artist.id == artistId,
          orElse: () => ArtistProfile(
            id: artistId,
            name: artistId,
            email: '',
            bio: '',
            specialties: const [],
            availability: '',
          ),
        )
        .name;
  }
}

class _ProjectOwnersCard extends StatelessWidget {
  const _ProjectOwnersCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final store = CollaborationStore.instance;
    final owners = <String>{
      project.ownerArtistId,
      ...store
          .tasksForProject(project.id)
          .map((task) => task.assignedToArtistId),
      ...store
          .weeklyGoalsForProject(project.id)
          .map((goal) => goal.ownerArtistId),
      ...store
          .decisionsForProject(project.id)
          .map((decision) => decision.decidedByArtistId),
    };

    final names = owners
        .map(
          (id) => store.artists
              .firstWhere(
                (artist) => artist.id == id,
                orElse: () => ArtistProfile(
                  id: id,
                  name: id,
                  email: '',
                  bio: '',
                  specialties: const [],
                  availability: '',
                ),
              )
              .name,
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('${project.style} - ${project.status}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: names
                  .map(
                    (name) => Chip(
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: Text(name),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsibilitySummaryCard extends StatelessWidget {
  const _ResponsibilitySummaryCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.subtitle,
    required this.children,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final int count;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(label: Text(count.toString())),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle),
              const SizedBox(height: 12),
              if (children.isEmpty)
                const Text('Nenhum item nesta categoria.')
              else
                ...children,
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsibilityItem extends StatelessWidget {
  const _ResponsibilityItem({
    required this.title,
    required this.detail,
    required this.chip,
    required this.highlighted,
    required this.completed,
  });

  final String title;
  final String detail;
  final String chip;
  final bool highlighted;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = completed
        ? Colors.green
        : highlighted
        ? colorScheme.error
        : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(detail),
              const SizedBox(height: 6),
              Chip(
                avatar: Icon(
                  completed
                      ? Icons.check_circle_outline
                      : highlighted
                      ? Icons.warning_amber_outlined
                      : Icons.schedule_outlined,
                  size: 18,
                ),
                label: Text(chip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _safeProjectId(Object? arguments, CollaborationStore store) {
  if (arguments is! String) {
    return null;
  }

  return store.projects.any((project) => project.id == arguments)
      ? arguments
      : null;
}

bool _isDueSoon(String dateText) {
  final parsed = DateTime.tryParse(dateText);
  if (parsed == null) {
    return false;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(parsed.year, parsed.month, parsed.day);
  final days = date.difference(today).inDays;
  return days <= 3;
}

String _deadlineLabel(String dateText, {required bool done}) {
  if (done) {
    return 'Concluido';
  }

  final parsed = DateTime.tryParse(dateText);
  if (parsed == null) {
    return 'Prazo: $dateText';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(parsed.year, parsed.month, parsed.day);
  final days = date.difference(today).inDays;

  if (days < 0) {
    return 'Vencido';
  }

  if (days == 0) {
    return 'Vence hoje';
  }

  if (days <= 3) {
    return 'Prazo proximo';
  }

  return 'Prazo: $dateText';
}
