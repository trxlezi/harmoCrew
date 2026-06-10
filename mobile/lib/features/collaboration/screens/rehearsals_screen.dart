import 'package:flutter/material.dart';

import '../models/artist_profile.dart';
import '../models/project.dart';
import '../models/rehearsal.dart';
import '../stores/mock_collaboration_store.dart';
import '../widgets/collaboration_ui.dart';

class RehearsalsScreen extends StatefulWidget {
  const RehearsalsScreen({super.key});

  static const routeName = '/rehearsals';

  @override
  State<RehearsalsScreen> createState() => _RehearsalsScreenState();
}

class _RehearsalsScreenState extends State<RehearsalsScreen> {
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

  void _showRehearsalForm() {
    final formKey = GlobalKey<FormState>();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    Project? selectedProject = _projectById(_selectedProjectId);
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final selectedArtistIds = <String>{};

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
            final dateLabel = selectedDate == null
                ? 'Selecionar data'
                : _formatDate(selectedDate!);
            final timeLabel = selectedTime == null
                ? 'Selecionar horario'
                : _formatTime(selectedTime!);

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
                          'Agendar ensaio',
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
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                  );

                                  if (picked != null) {
                                    setSheetState(() => selectedDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.event),
                                label: Text(dateLabel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        selectedTime ??
                                        const TimeOfDay(hour: 19, minute: 30),
                                  );

                                  if (picked != null) {
                                    setSheetState(() => selectedTime = picked);
                                  }
                                },
                                icon: const Icon(Icons.schedule),
                                label: Text(timeLabel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: locationController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Local'),
                          validator: (value) => requiredField(value, 'o local'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Participantes',
                          ),
                          items: _store.artists
                              .map(
                                (artist) => DropdownMenuItem<String>(
                                  value: artist.id,
                                  child: Text(artist.name),
                                ),
                              )
                              .toList(),
                          onChanged: (artistId) {
                            if (artistId == null) {
                              return;
                            }

                            setSheetState(
                              () => selectedArtistIds.add(artistId),
                            );
                          },
                        ),
                        if (selectedArtistIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedArtistIds
                                .map(
                                  (artistId) => Chip(
                                    label: Text(_artistName(artistId)),
                                    onDeleted: () {
                                      setSheetState(
                                        () =>
                                            selectedArtistIds.remove(artistId),
                                      );
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Observacoes',
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

                              if (selectedDate == null ||
                                  selectedTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Informe data e horario do ensaio.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _store.addRehearsal(
                                  Rehearsal(
                                    id: 'rehearsal-${DateTime.now().microsecondsSinceEpoch}',
                                    projectId: selectedProject!.id,
                                    title: 'Ensaio - ${selectedProject!.title}',
                                    date: _formatDate(selectedDate!),
                                    time: _formatTime(selectedTime!),
                                    location: locationController.text.trim(),
                                    participantArtistIds: selectedArtistIds
                                        .toList(),
                                    notes: notesController.text.trim(),
                                    status: RehearsalStatus.scheduled,
                                  ),
                                );
                              });

                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ensaio agendado com sucesso.'),
                                ),
                              );
                            },
                            child: const Text('Salvar ensaio'),
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

  void _updateStatus(String rehearsalId, RehearsalStatus status) {
    setState(() {
      _store.updateRehearsalStatus(rehearsalId, status);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ensaio marcado como ${rehearsalStatusLabel(status)}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rehearsals = _store.rehearsalsForProject(_selectedProjectId);

    return Scaffold(
      appBar: AppBar(title: const Text('Ensaios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRehearsalForm,
        icon: const Icon(Icons.event_available),
        label: const Text('Agendar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Ensaios', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Agenda local de ensaios dos projetos musicais.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ProjectSelector(
            value: _selectedProjectId,
            projects: _store.projects,
            onChanged: (projectId) {
              setState(() => _selectedProjectId = projectId);
            },
          ),
          const SizedBox(height: 20),
          if (rehearsals.isEmpty)
            const EmptyState(
              icon: Icons.event_busy,
              message: 'Nenhum ensaio agendado ainda.',
            )
          else
            ...rehearsals.map(
              (rehearsal) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _RehearsalCard(
                  rehearsal: rehearsal,
                  projectName: _projectName(rehearsal.projectId),
                  participantNames: rehearsal.participantArtistIds
                      .map(_artistName)
                      .toList(),
                  onScheduled: () =>
                      _updateStatus(rehearsal.id, RehearsalStatus.scheduled),
                  onCompleted: () =>
                      _updateStatus(rehearsal.id, RehearsalStatus.completed),
                  onCanceled: () =>
                      _updateStatus(rehearsal.id, RehearsalStatus.canceled),
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

class _RehearsalCard extends StatelessWidget {
  const _RehearsalCard({
    required this.rehearsal,
    required this.projectName,
    required this.participantNames,
    required this.onScheduled,
    required this.onCompleted,
    required this.onCanceled,
  });

  final Rehearsal rehearsal;
  final String projectName;
  final List<String> participantNames;
  final VoidCallback onScheduled;
  final VoidCallback onCompleted;
  final VoidCallback onCanceled;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = _isUpcoming(rehearsal);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isUpcoming
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 4,
            ),
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
                    rehearsal.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(rehearsalStatusLabel(rehearsal.status))),
              ],
            ),
            const SizedBox(height: 10),
            Text('Projeto: $projectName'),
            const SizedBox(height: 6),
            Text('Data: ${rehearsal.date}'),
            const SizedBox(height: 6),
            Text('Horario: ${rehearsal.time}'),
            const SizedBox(height: 6),
            Text('Local: ${rehearsal.location}'),
            const SizedBox(height: 6),
            Text(
              'Participantes: ${participantNames.isEmpty ? 'A definir' : participantNames.join(', ')}',
            ),
            if (rehearsal.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Observacoes: ${rehearsal.notes}'),
            ],
            const SizedBox(height: 12),
            if (isUpcoming)
              const Chip(
                avatar: Icon(Icons.schedule, size: 18),
                label: Text('Proximo ensaio'),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onScheduled,
                  child: const Text('Agendado'),
                ),
                ElevatedButton(
                  onPressed: onCompleted,
                  child: const Text('Realizado'),
                ),
                OutlinedButton(
                  onPressed: onCanceled,
                  child: const Text('Cancelado'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _isUpcoming(Rehearsal rehearsal) {
  final date = DateTime.tryParse(rehearsal.date);
  if (date == null || rehearsal.status != RehearsalStatus.scheduled) {
    return false;
  }

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final days = dateOnly.difference(todayOnly).inDays;

  return days >= 0 && days <= 7;
}

String rehearsalStatusLabel(RehearsalStatus status) {
  return switch (status) {
    RehearsalStatus.scheduled => 'Agendado',
    RehearsalStatus.completed => 'Realizado',
    RehearsalStatus.canceled => 'Cancelado',
  };
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
