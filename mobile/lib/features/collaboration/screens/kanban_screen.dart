import 'package:flutter/material.dart';

import '../models/artist_profile.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import '../stores/mock_collaboration_store.dart';
import '../widgets/collaboration_ui.dart' hide priorityLabel;
import 'tasks_screen.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  static const routeName = '/kanban';

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final MockCollaborationStore _store = MockCollaborationStore.instance;

  String? _selectedProjectId;
  String? _selectedArtistId;
  bool _readInitialArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readInitialArguments) {
      return;
    }

    _selectedProjectId = _safeProjectId(
      ModalRoute.of(context)?.settings.arguments,
      _store,
    );
    _readInitialArguments = true;
  }

  List<ProjectTask> _tasksFor(ProjectTaskStatus status) {
    return _store.tasks.where((task) {
      final matchesStatus = task.status == status;
      final matchesProject =
          _selectedProjectId == null || task.projectId == _selectedProjectId;
      final matchesArtist =
          _selectedArtistId == null ||
          task.assignedToArtistId == _selectedArtistId;

      return matchesStatus && matchesProject && matchesArtist;
    }).toList();
  }

  void _moveTask(ProjectTask task, ProjectTaskStatus status) {
    setState(() {
      _store.updateTaskStatus(task.id, status);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tarefa movida para ${statusLabel(status)}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ProjectTaskStatus.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kanban'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'A fazer'),
              Tab(text: 'Em andamento'),
              Tab(text: 'Concluidas'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  ProjectSelector(
                    value: _selectedProjectId,
                    projects: _store.projects,
                    onChanged: (projectId) {
                      setState(() => _selectedProjectId = projectId);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedArtistId,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por responsavel',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os responsaveis'),
                      ),
                      ..._store.artists.map(
                        (artist) => DropdownMenuItem<String?>(
                          value: artist.id,
                          child: Text(artist.name),
                        ),
                      ),
                    ],
                    onChanged: (artistId) {
                      setState(() => _selectedArtistId = artistId);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: ProjectTaskStatus.values
                    .map(
                      (status) => _KanbanStatusList(
                        status: status,
                        tasks: _tasksFor(status),
                        projectName: _projectName,
                        artistName: _artistName,
                        onMove: _moveTask,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _projectName(String projectId) {
    return _store.projects
        .firstWhere(
          (project) => project.id == projectId,
          orElse: () => Project(
            id: projectId,
            title: projectId,
            style: '',
            summary: '',
            status: '',
            ownerArtistId: '',
            needs: const [],
          ),
        )
        .title;
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

String? _safeProjectId(Object? arguments, MockCollaborationStore store) {
  if (arguments is! String) {
    return null;
  }

  return store.projects.any((project) => project.id == arguments)
      ? arguments
      : null;
}

class _KanbanStatusList extends StatelessWidget {
  const _KanbanStatusList({
    required this.status,
    required this.tasks,
    required this.projectName,
    required this.artistName,
    required this.onMove,
  });

  final ProjectTaskStatus status;
  final List<ProjectTask> tasks;
  final String Function(String projectId) projectName;
  final String Function(String artistId) artistName;
  final void Function(ProjectTask task, ProjectTaskStatus status) onMove;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _KanbanEmptyState(status: status);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemBuilder: (context, index) {
        final task = tasks[index];

        return _KanbanTaskCard(
          task: task,
          projectName: projectName(task.projectId),
          assigneeName: artistName(task.assignedToArtistId),
          onMove: (status) => onMove(task, status),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: tasks.length,
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  const _KanbanTaskCard({
    required this.task,
    required this.projectName,
    required this.assigneeName,
    required this.onMove,
  });

  final ProjectTask task;
  final String projectName;
  final String assigneeName;
  final void Function(ProjectTaskStatus status) onMove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text('Projeto: $projectName'),
            const SizedBox(height: 6),
            Text('Responsavel: $assigneeName'),
            const SizedBox(height: 6),
            Text('Prazo: ${task.dueDate}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PriorityChip(priority: task.priority),
                Chip(label: Text(statusLabel(task.status))),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (task.status != ProjectTaskStatus.todo)
                  OutlinedButton(
                    onPressed: () => onMove(ProjectTaskStatus.todo),
                    child: const Text('Mover para fazer'),
                  ),
                if (task.status != ProjectTaskStatus.doing)
                  OutlinedButton(
                    onPressed: () => onMove(ProjectTaskStatus.doing),
                    child: const Text('Mover para andamento'),
                  ),
                if (task.status != ProjectTaskStatus.done)
                  ElevatedButton(
                    onPressed: () => onMove(ProjectTaskStatus.done),
                    child: const Text('Mover para concluida'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanEmptyState extends StatelessWidget {
  const _KanbanEmptyState({required this.status});

  final ProjectTaskStatus status;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.view_kanban_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhuma tarefa em ${statusLabel(status).toLowerCase()}.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
