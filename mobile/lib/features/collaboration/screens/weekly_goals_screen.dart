import 'package:flutter/material.dart';

import '../models/artist_profile.dart';
import '../models/weekly_goal.dart';
import '../stores/collaboration_store.dart';
import '../widgets/collaboration_ui.dart';

class WeeklyGoalsScreen extends StatefulWidget {
  const WeeklyGoalsScreen({super.key});

  static const routeName = '/weekly-goals';

  @override
  State<WeeklyGoalsScreen> createState() => _WeeklyGoalsScreenState();
}

class _WeeklyGoalsScreenState extends State<WeeklyGoalsScreen> {
  final CollaborationStore _store = CollaborationStore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showGoalForm({WeeklyGoal? goal}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: goal?.title ?? '');
    final descriptionController = TextEditingController(
      text: goal?.description ?? '',
    );
    final dueDateController = TextEditingController(text: goal?.dueDate ?? '');
    ArtistProfile? selectedArtist = goal == null
        ? null
        : _store.artists.firstWhere(
            (artist) => artist.id == goal.ownerArtistId,
            orElse: () => _store.artists.first,
          );

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
                          goal == null ? 'Nova meta' : 'Editar meta',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Descricao',
                            hintText: 'Opcional',
                          ),
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
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Prazo',
                            hintText: 'AAAA-MM-DD',
                          ),
                          validator: (value) => requiredField(value, 'o prazo'),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final messenger = ScaffoldMessenger.of(context);
                              final projectId = _store.projects.isEmpty
                                  ? null
                                  : _store.projects.first.id;
                              if (projectId == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cadastre um projeto antes de criar metas.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (goal == null) {
                                try {
                                  await _store.createWeeklyGoalFromApi(
                                    WeeklyGoal(
                                      id: '',
                                      projectId: projectId,
                                      title: titleController.text.trim(),
                                      description: descriptionController.text
                                          .trim(),
                                      ownerArtistId: selectedArtist!.id,
                                      weekLabel: _weekLabel(DateTime.now()),
                                      dueDate: dueDateController.text.trim(),
                                      status: WeeklyGoalStatus.planned,
                                    ),
                                  );
                                  if (mounted) {
                                    setState(() {});
                                  }
                                } catch (error) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                  return;
                                }
                                if (!mounted || !sheetContext.mounted) {
                                  return;
                                }

                                Navigator.pop(sheetContext);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Meta criada com sucesso.'),
                                  ),
                                );
                                return;
                              }

                              try {
                                await _store.updateWeeklyGoalFromApi(
                                  goal.copyWith(
                                    title: titleController.text.trim(),
                                    description: descriptionController.text.trim(),
                                    ownerArtistId: selectedArtist!.id,
                                    dueDate: dueDateController.text.trim(),
                                  ),
                                );
                                if (mounted) {
                                  setState(() {});
                                }
                              } catch (error) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                                return;
                              }
                              if (!mounted || !sheetContext.mounted) {
                                return;
                              }

                              Navigator.pop(sheetContext);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Meta atualizada com sucesso.'),
                                ),
                              );
                            },
                            child: Text(
                              goal == null ? 'Salvar meta' : 'Atualizar meta',
                            ),
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

  Future<void> _confirmDelete(WeeklyGoal goal) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir meta'),
          content: Text('Deseja excluir "${goal.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _store.removeWeeklyGoalFromApi(goal.id);
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

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Meta excluida com sucesso.')));
  }

  Future<void> _updateStatus(WeeklyGoal goal, WeeklyGoalStatus status) async {
    try {
      await _store.updateWeeklyGoalStatusFromApi(goal.id, status);
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

    final message = status == WeeklyGoalStatus.done
        ? 'Meta concluida com sucesso.'
        : 'Meta atualizada com sucesso.';

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = _store.weeklyGoals;

    return Scaffold(
      appBar: AppBar(title: const Text('Metas Semanais')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalForm(),
        icon: const Icon(Icons.flag_outlined),
        label: const Text('Nova meta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Metas Semanais',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Prazos e responsabilidades da semana, mantidos localmente.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          if (_isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 20),
          ],
          if (goals.isEmpty)
            const EmptyState(
              icon: Icons.flag_outlined,
              message: 'Nenhuma meta semanal cadastrada.',
            )
          else
            ...goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WeeklyGoalCard(
                  goal: goal,
                  ownerName: _artistName(goal.ownerArtistId),
                  onEdit: () => _showGoalForm(goal: goal),
                  onDelete: () => _confirmDelete(goal),
                  onPlanned: () =>
                      _updateStatus(goal, WeeklyGoalStatus.planned),
                  onInProgress: () =>
                      _updateStatus(goal, WeeklyGoalStatus.inProgress),
                  onDone: () => _updateStatus(goal, WeeklyGoalStatus.done),
                ),
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
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

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({
    required this.goal,
    required this.ownerName,
    required this.onEdit,
    required this.onDelete,
    required this.onPlanned,
    required this.onInProgress,
    required this.onDone,
  });

  final WeeklyGoal goal;
  final String ownerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPlanned;
  final VoidCallback onInProgress;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(weeklyGoalStatusLabel(goal.status))),
              ],
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(goal.description),
            ],
            const SizedBox(height: 10),
            Text('Responsavel: $ownerName'),
            const SizedBox(height: 6),
            Text('Semana: ${goal.weekLabel}'),
            const SizedBox(height: 6),
            Text('Prazo: ${goal.dueDate}'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onPlanned,
                  child: const Text('Planejada'),
                ),
                OutlinedButton(
                  onPressed: onInProgress,
                  child: const Text('Em andamento'),
                ),
                ElevatedButton(
                  onPressed: onDone,
                  child: const Text('Concluir'),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String weeklyGoalStatusLabel(WeeklyGoalStatus status) {
  return switch (status) {
    WeeklyGoalStatus.planned => 'Planejada',
    WeeklyGoalStatus.inProgress => 'Em andamento',
    WeeklyGoalStatus.done => 'Concluida',
  };
}

String _weekLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return 'Semana de $day/$month';
}
