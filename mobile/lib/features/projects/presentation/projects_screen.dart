import 'package:flutter/material.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../auth/data/auth_store.dart';
import '../../collaboration/models/application.dart';
import '../../collaboration/screens/decisions_screen.dart';
import '../../collaboration/screens/kanban_screen.dart';
import '../../collaboration/screens/rehearsals_screen.dart';
import '../../collaboration/screens/responsibilities_screen.dart';
import '../../collaboration/screens/tasks_screen.dart';
import '../../collaboration/stores/collaboration_store.dart';
import '../domain/project.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  static const routeName = '/projects';

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final CollaborationStore _store = CollaborationStore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _showProjectDetails(BuildContext context, Project project) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Resumo do projeto',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(project.summary),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(label: Text(project.style)),
                      Chip(label: Text(project.status)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Perfis buscados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: project.needs
                        .map((need) => Chip(label: Text(need)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Decisoes relacionadas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _ProjectDecisionsPreview(
                    store: _store,
                    projectId: _collaborationProjectId(project.title),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showApplicationForm(context, project);
                      },
                      child: const Text('Candidatar-se'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _collaborationProjectId(String projectTitle) {
    for (final project in _store.projects) {
      if (project.title == projectTitle) {
        return project.id;
      }
    }

    return null;
  }

  void _openProjectArea(String routeName, Project project) {
    Navigator.pushNamed(
      context,
      routeName,
      arguments: _collaborationProjectId(project.title),
    );
  }

  void _showApplicationForm(BuildContext context, Project project) {
    final formKey = GlobalKey<FormState>();
    final messageController = TextEditingController();
    final specialtyController = TextEditingController();
    final availabilityController = TextEditingController();
    final user = AuthStore.currentUser;
    final artistName = user?.name ?? 'Artista convidado';
    final fallbackArtistId = _store.artists.isEmpty
        ? null
        : _store.artists.first.id;
    final artistId =
        user?.artistId ?? fallbackArtistId ?? user?.email ?? 'artista-local';

    String? requiredField(String? value, String label) {
      if (value == null || value.trim().isEmpty) {
        return 'Informe $label';
      }

      return null;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
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
                      'Nova candidatura',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _ReadOnlyInfo(label: 'Projeto', value: project.title),
                    const SizedBox(height: 8),
                    _ReadOnlyInfo(
                      label: 'Artista interessado',
                      value: artistName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: messageController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Mensagem/apresentacao',
                        hintText: 'Conte como voce pode contribuir',
                      ),
                      validator: (value) => requiredField(value, 'a mensagem'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: specialtyController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Especialidade/instrumento',
                        hintText: 'Ex.: Baixo, bateria, vocal',
                      ),
                      validator: (value) =>
                          requiredField(value, 'a especialidade'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: availabilityController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Disponibilidade',
                        hintText: 'Ex.: Noites de sexta',
                      ),
                      validator: (value) =>
                          requiredField(value, 'a disponibilidade'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final application = Application(
                            id: 'application-${DateTime.now().microsecondsSinceEpoch}',
                            projectId:
                                _collaborationProjectId(project.title) ??
                                project.title,
                            artistId: artistId,
                            message: messageController.text.trim(),
                            specialty: specialtyController.text.trim(),
                            availability: availabilityController.text.trim(),
                            status: ApplicationStatus.pending,
                            createdAt: DateTime.now()
                                .toIso8601String()
                                .substring(0, 10),
                          );

                          try {
                            await _store.createApplicationFromApi(application);
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
                              content: Text('Candidatura enviada com sucesso.'),
                            ),
                          );
                        },
                        child: const Text('Enviar candidatura'),
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
  }

  Future<void> _updateApplicationStatus(
    String id,
    ApplicationStatus status,
  ) async {
    try {
      await _store.updateApplicationStatusFromApi(id, status);
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
      SnackBar(
        content: Text(
          'Candidatura marcada como ${_applicationStatusLabel(status)}.',
        ),
      ),
    );
  }

  Future<void> _loadProjects() async {
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
    final projects = _store.projects
        .map(
          (project) => Project(
            title: project.title,
            style: project.style,
            summary: project.summary,
            status: project.status,
            needs: project.needs,
          ),
        )
        .toList(growable: false);
    final applications = _store.applications;

    return AppScaffold(
      title: 'Projetos',
      currentIndex: 1,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projetos em destaque',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lista carregada da API HarmoCrew para descoberta de oportunidades.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 20),
          ],
          ...projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Chip(label: Text(project.status)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.style,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(project.summary),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: project.needs
                            .map((need) => Chip(label: Text(need)))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              _showProjectDetails(context, project),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Ver detalhes'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openProjectArea(
                              TasksScreen.routeName,
                              project,
                            ),
                            icon: const Icon(Icons.task_alt_outlined),
                            label: const Text('Tarefas'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openProjectArea(
                              KanbanScreen.routeName,
                              project,
                            ),
                            icon: const Icon(Icons.view_kanban_outlined),
                            label: const Text('Kanban'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openProjectArea(
                              RehearsalsScreen.routeName,
                              project,
                            ),
                            icon: const Icon(Icons.event_available_outlined),
                            label: const Text('Ensaios'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openProjectArea(
                              DecisionsScreen.routeName,
                              project,
                            ),
                            icon: const Icon(Icons.history_outlined),
                            label: const Text('Decisoes'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openProjectArea(
                              ResponsibilitiesScreen.routeName,
                              project,
                            ),
                            icon: const Icon(Icons.assignment_ind_outlined),
                            label: const Text('Responsabilidades'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Candidaturas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (applications.isEmpty)
            const _ApplicationsEmptyState()
          else
            ...applications.map(
              (application) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ApplicationCard(
                  application: application,
                  onPending: () => _updateApplicationStatus(
                    application.id,
                    ApplicationStatus.pending,
                  ),
                  onApprove: () => _updateApplicationStatus(
                    application.id,
                    ApplicationStatus.approved,
                  ),
                  onReject: () => _updateApplicationStatus(
                    application.id,
                    ApplicationStatus.rejected,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectDecisionsPreview extends StatelessWidget {
  const _ProjectDecisionsPreview({
    required this.store,
    required this.projectId,
  });

  final CollaborationStore store;
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    final decisions = store.decisionsForProject(projectId);

    if (decisions.isEmpty) {
      return const Text('Nenhuma decisao registrada para este projeto.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: decisions
          .take(2)
          .map(
            (decision) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.history,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${decision.title} - ${decisionStatusLabel(decision.status)}',
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onPending,
    required this.onApprove,
    required this.onReject,
  });

  final Application application;
  final VoidCallback onPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  String get _statusLabel {
    return switch (application.status) {
      ApplicationStatus.pending => 'Pendente',
      ApplicationStatus.approved => 'Aceita',
      ApplicationStatus.rejected => 'Recusada',
    };
  }

  Color _statusColor(BuildContext context) {
    return switch (application.status) {
      ApplicationStatus.pending => Theme.of(context).colorScheme.primary,
      ApplicationStatus.approved => Colors.green,
      ApplicationStatus.rejected => Colors.redAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.projectId,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text(_statusLabel),
                  side: BorderSide(color: _statusColor(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Artista: ${application.artistId}'),
            const SizedBox(height: 6),
            Text('Especialidade: ${application.specialty}'),
            const SizedBox(height: 6),
            Text('Disponibilidade: ${application.availability}'),
            const SizedBox(height: 6),
            Text('Data: ${application.createdAt}'),
            const SizedBox(height: 12),
            Text(application.message),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onPending,
                  child: const Text('Pendente'),
                ),
                ElevatedButton(
                  onPressed: onApprove,
                  child: const Text('Aceitar'),
                ),
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Recusar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsEmptyState extends StatelessWidget {
  const _ApplicationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Nenhuma candidatura registrada ainda.'),
            ),
          ],
        ),
      ),
    );
  }
}

String _applicationStatusLabel(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.pending => 'Pendente',
    ApplicationStatus.approved => 'Aceita',
    ApplicationStatus.rejected => 'Recusada',
  };
}
