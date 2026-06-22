import 'package:flutter/material.dart';

import '../models/artist_profile.dart';
import '../models/project.dart';
import '../models/project_task.dart';
import '../stores/collaboration_store.dart';
import '../widgets/collaboration_ui.dart' hide priorityLabel;

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  static const routeName = '/tasks';

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final CollaborationStore _store = CollaborationStore.instance;

  String? _selectedProjectId;
  bool _readInitialArguments = false;
  bool _isLoading = false;

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
    _loadTasks();
  }

  List<ProjectTask> get _visibleTasks {
    if (_selectedProjectId == null) {
      return _store.tasks;
    }

    return _store.tasks
        .where((task) => task.projectId == _selectedProjectId)
        .toList();
  }

  void _showTaskForm() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();
    Project? selectedProject = _projectById(_selectedProjectId);
    ArtistProfile? selectedArtist;
    ProjectTaskPriority? selectedPriority;

    String? requiredField(Object? value, String label) {
      if (value == null) {
        return 'Informe $label';
      }

      if (value is String && value.trim().isEmpty) {
        return 'Informe $label';
      }

      return null;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova tarefa',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: titleController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Titulo',
                            hintText: 'Ex.: Revisar guia vocal',
                          ),
                          validator: (value) =>
                              requiredField(value, 'o titulo'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Descricao',
                            hintText: 'Detalhes opcionais da tarefa',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Project>(
                          initialValue: selectedProject,
                          decoration: const InputDecoration(
                            labelText: 'Projeto',
                          ),
                          items: _store.projects
                              .map(
                                (project) => DropdownMenuItem<Project>(
                                  value: project,
                                  child: Text(project.title),
                                ),
                              )
                              .toList(),
                          onChanged: (project) {
                            setSheetState(() => selectedProject = project);
                          },
                          validator: (value) =>
                              requiredField(value, 'o projeto'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ArtistProfile>(
                          initialValue: selectedArtist,
                          decoration: const InputDecoration(
                            labelText: 'Responsavel',
                          ),
                          items: _store.artists
                              .map(
                                (artist) => DropdownMenuItem<ArtistProfile>(
                                  value: artist,
                                  child: Text(artist.name),
                                ),
                              )
                              .toList(),
                          onChanged: (artist) {
                            setSheetState(() => selectedArtist = artist);
                          },
                          validator: (value) =>
                              requiredField(value, 'o responsavel'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dueDateController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Prazo',
                            hintText: 'AAAA-MM-DD',
                          ),
                          validator: (value) => requiredField(value, 'o prazo'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ProjectTaskPriority>(
                          initialValue: selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Prioridade',
                          ),
                          items: ProjectTaskPriority.values
                              .map(
                                (priority) =>
                                    DropdownMenuItem<ProjectTaskPriority>(
                                      value: priority,
                                      child: Text(_priorityLabel(priority)),
                                    ),
                              )
                              .toList(),
                          onChanged: (priority) {
                            setSheetState(() => selectedPriority = priority);
                          },
                          validator: (value) =>
                              requiredField(value, 'a prioridade'),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final task = ProjectTask(
                                id: 'task-${DateTime.now().microsecondsSinceEpoch}',
                                projectId: selectedProject!.id,
                                title: titleController.text.trim(),
                                assignedToArtistId: selectedArtist!.id,
                                dueDate: dueDateController.text.trim(),
                                priority: selectedPriority!,
                                status: ProjectTaskStatus.todo,
                                description: descriptionController.text.trim(),
                              );

                              try {
                                await _store.createTaskFromApi(task);
                                if (mounted) {
                                  setState(() {});
                                }
                              } catch (error) {
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                                return;
                              }

                              if (!context.mounted || !sheetContext.mounted) {
                                return;
                              }

                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tarefa criada com sucesso.'),
                                ),
                              );
                            },
                            child: const Text('Salvar tarefa'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(String taskId, ProjectTaskStatus status) async {
    try {
      await _store.updateTaskStatusFromApi(taskId, status);
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
      SnackBar(content: Text('Tarefa marcada como ${statusLabel(status)}.')),
    );
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      await _store.syncCoreFromApi();
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _visibleTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTaskForm,
        icon: const Icon(Icons.add_task),
        label: const Text('Nova tarefa'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Tarefas de projeto',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Gestao local de responsabilidades, prazos e prioridades.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (_isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          ProjectSelector(
            value: _selectedProjectId,
            projects: _store.projects,
            onChanged: (projectId) {
              setState(() => _selectedProjectId = projectId);
            },
          ),
          const SizedBox(height: 20),
          if (tasks.isEmpty)
            const EmptyState(
              icon: Icons.assignment_outlined,
              message: 'Nenhuma tarefa encontrada.',
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TaskCard(
                  task: task,
                  projectName: _projectName(task.projectId),
                  assigneeName: _artistName(task.assignedToArtistId),
                  onTodo: () => _updateStatus(task.id, ProjectTaskStatus.todo),
                  onDoing: () =>
                      _updateStatus(task.id, ProjectTaskStatus.doing),
                  onDone: () => _updateStatus(task.id, ProjectTaskStatus.done),
                ),
              ),
            ),
          const SizedBox(height: 72),
        ],
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

  Project? _projectById(String? projectId) {
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

String? _safeProjectId(Object? arguments, CollaborationStore store) {
  if (arguments is! String) {
    return null;
  }

  return store.projects.any((project) => project.id == arguments)
      ? arguments
      : null;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.projectName,
    required this.assigneeName,
    required this.onTodo,
    required this.onDoing,
    required this.onDone,
  });

  final ProjectTask task;
  final String projectName;
  final String assigneeName;
  final VoidCallback onTodo;
  final VoidCallback onDoing;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final dueState = _dueState(task.dueDate);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: dueState.color(context), width: 4),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: task.status),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description),
            ],
            const SizedBox(height: 12),
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
                Chip(
                  avatar: Icon(dueState.icon, size: 18),
                  label: Text(dueState.label),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: onTodo, child: const Text('A fazer')),
                OutlinedButton(
                  onPressed: onDoing,
                  child: const Text('Em andamento'),
                ),
                ElevatedButton(
                  onPressed: onDone,
                  child: const Text('Concluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ProjectTaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(_statusLabel(status)));
  }
}

class _DueState {
  const _DueState({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color Function(BuildContext context) color;
}

_DueState _dueState(String dueDate) {
  final parsed = DateTime.tryParse(dueDate);
  if (parsed == null) {
    return _DueState(
      label: 'Prazo informado',
      icon: Icons.event_note,
      color: (context) => Theme.of(context).colorScheme.primary,
    );
  }

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dueOnly = DateTime(parsed.year, parsed.month, parsed.day);
  final days = dueOnly.difference(todayOnly).inDays;

  if (days < 0) {
    return _DueState(
      label: 'Vencida',
      icon: Icons.warning_amber,
      color: (_) => Colors.redAccent,
    );
  }

  if (days <= 2) {
    return _DueState(
      label: 'Prazo proximo',
      icon: Icons.schedule,
      color: (_) => Colors.amber,
    );
  }

  return _DueState(
    label: 'No prazo',
    icon: Icons.event_available,
    color: (context) => Theme.of(context).colorScheme.primary,
  );
}

String _statusLabel(ProjectTaskStatus status) {
  return statusLabel(status);
}

String statusLabel(ProjectTaskStatus status) {
  return switch (status) {
    ProjectTaskStatus.todo => 'A fazer',
    ProjectTaskStatus.doing => 'Em andamento',
    ProjectTaskStatus.done => 'Concluida',
  };
}

String _priorityLabel(ProjectTaskPriority priority) {
  return priorityLabel(priority);
}

String priorityLabel(ProjectTaskPriority priority) {
  return switch (priority) {
    ProjectTaskPriority.low => 'Baixa',
    ProjectTaskPriority.medium => 'Media',
    ProjectTaskPriority.high => 'Alta',
  };
}
