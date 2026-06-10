import 'package:flutter/material.dart';

import '../models/artist_profile.dart';
import '../models/decision_record.dart';
import '../models/project.dart';
import '../stores/mock_collaboration_store.dart';
import '../widgets/collaboration_ui.dart';

class DecisionsScreen extends StatefulWidget {
  const DecisionsScreen({super.key});

  static const routeName = '/decisions';

  @override
  State<DecisionsScreen> createState() => _DecisionsScreenState();
}

class _DecisionsScreenState extends State<DecisionsScreen> {
  final MockCollaborationStore _store = MockCollaborationStore.instance;

  String? _selectedProjectId;
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

  void _showDecisionForm() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final impactController = TextEditingController();
    Project? selectedProject = _projectById(_selectedProjectId);
    ArtistProfile? selectedArtist;

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
                          'Registrar decisao',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                        TextFormField(
                          controller: titleController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Titulo',
                          ),
                          validator: (value) =>
                              requiredField(value, 'o titulo'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Descricao',
                          ),
                          validator: (value) =>
                              requiredField(value, 'a descricao'),
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
                          controller: impactController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Impacto/observacao',
                            hintText: 'Opcional',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              setState(() {
                                _store.addDecision(
                                  DecisionRecord(
                                    id: 'decision-${DateTime.now().microsecondsSinceEpoch}',
                                    projectId: selectedProject!.id,
                                    title: titleController.text.trim(),
                                    description: descriptionController.text
                                        .trim(),
                                    decidedByArtistId: selectedArtist!.id,
                                    decidedAt: DateTime.now()
                                        .toIso8601String()
                                        .substring(0, 10),
                                    impact: impactController.text.trim(),
                                    status: DecisionStatus.registered,
                                  ),
                                );
                              });

                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Decisao registrada com sucesso.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Salvar decisao'),
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

  void _updateStatus(String decisionId, DecisionStatus status) {
    setState(() {
      _store.updateDecisionStatus(decisionId, status);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Decisao marcada como ${decisionStatusLabel(status)}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decisions = _store.decisionsForProject(_selectedProjectId);

    return Scaffold(
      appBar: AppBar(title: const Text('Decisoes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDecisionForm,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Registrar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Timeline de decisoes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Rastreabilidade local das escolhas feitas nos projetos.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ProjectSelector(
            value: _selectedProjectId,
            projects: _store.projects,
            onChanged: (projectId) {
              setState(() => _selectedProjectId = projectId);
            },
          ),
          const SizedBox(height: 20),
          if (decisions.isEmpty)
            const EmptyState(
              icon: Icons.history_toggle_off,
              message: 'Nenhuma decisao registrada.',
            )
          else
            ...decisions.map(
              (decision) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _DecisionCard(
                  decision: decision,
                  projectName: _projectName(decision.projectId),
                  responsibleName: _artistName(decision.decidedByArtistId),
                  onRegistered: () =>
                      _updateStatus(decision.id, DecisionStatus.registered),
                  onReviewed: () =>
                      _updateStatus(decision.id, DecisionStatus.reviewed),
                  onCanceled: () =>
                      _updateStatus(decision.id, DecisionStatus.canceled),
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

String? _safeProjectId(Object? arguments, MockCollaborationStore store) {
  if (arguments is! String) {
    return null;
  }

  return store.projects.any((project) => project.id == arguments)
      ? arguments
      : null;
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.decision,
    required this.projectName,
    required this.responsibleName,
    required this.onRegistered,
    required this.onReviewed,
    required this.onCanceled,
  });

  final DecisionRecord decision;
  final String projectName;
  final String responsibleName;
  final VoidCallback onRegistered;
  final VoidCallback onReviewed;
  final VoidCallback onCanceled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.history, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          decision.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Chip(label: Text(decisionStatusLabel(decision.status))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(decision.description),
                  const SizedBox(height: 10),
                  Text('Projeto: $projectName'),
                  const SizedBox(height: 6),
                  Text('Responsavel: $responsibleName'),
                  const SizedBox(height: 6),
                  Text('Data: ${decision.decidedAt}'),
                  if (decision.impact.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Impacto: ${decision.impact}'),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: onRegistered,
                        child: const Text('Registrada'),
                      ),
                      ElevatedButton(
                        onPressed: onReviewed,
                        child: const Text('Revisada'),
                      ),
                      OutlinedButton(
                        onPressed: onCanceled,
                        child: const Text('Cancelada'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String decisionStatusLabel(DecisionStatus status) {
  return switch (status) {
    DecisionStatus.registered => 'Registrada',
    DecisionStatus.reviewed => 'Revisada',
    DecisionStatus.canceled => 'Cancelada',
  };
}
