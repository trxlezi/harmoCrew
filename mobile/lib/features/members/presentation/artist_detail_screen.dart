import 'package:flutter/material.dart';

import '../../collaboration/models/artist_profile.dart';
import '../../collaboration/models/project.dart';
import '../../collaboration/stores/collaboration_store.dart';
import 'talents_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({super.key});

  static const routeName = '/talents/detail';

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final CollaborationStore _store = CollaborationStore.instance;

  void _inviteToProject(ArtistProfile artist) {
    Project? selectedProject = _store.projects.isEmpty
        ? null
        : _store.projects.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Convidar para projeto'),
              content: DropdownButtonFormField<Project>(
                initialValue: selectedProject,
                decoration: const InputDecoration(labelText: 'Projeto'),
                items: _store.projects
                    .map(
                      (project) => DropdownMenuItem<Project>(
                        value: project,
                        child: Text(project.title),
                      ),
                    )
                    .toList(),
                onChanged: (project) =>
                    setDialogState(() => selectedProject = project),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedProject == null
                      ? null
                      : () {
                          final project = selectedProject!;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${artist.name} convidado para ${project.title}.',
                              ),
                            ),
                          );
                        },
                  child: const Text('Convidar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as ArtistDetailArguments?;
    final artistId = args?.artistId;
    final artist = _store.artists.firstWhere(
      (artist) => artist.id == artistId,
      orElse: () => const ArtistProfile(
        id: 'unknown',
        name: 'Artista nao encontrado',
        email: '',
        bio: '',
        specialties: [],
        availability: '',
      ),
    );
    final relatedProjects = relatedProjectsForArtist(_store, artist);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do artista')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 34,
            child: Text(
              artist.name.substring(0, 1),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            artist.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            artist.city.isEmpty ? artist.availability : artist.city,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _DetailSection(title: 'Bio', child: Text(artist.bio)),
          _DetailSection(
            title: 'Especialidades',
            child: _ChipWrap(values: artist.specialties),
          ),
          _DetailSection(
            title: 'Instrumentos',
            child: _ChipWrap(values: artist.instruments),
          ),
          _DetailSection(
            title: 'Estilos musicais',
            child: _ChipWrap(values: artist.styles),
          ),
          _DetailSection(
            title: 'Disponibilidade',
            child: Text(artist.availability),
          ),
          _DetailSection(
            title: 'Projetos relacionados',
            child: relatedProjects.isEmpty
                ? const Text('Nenhum projeto relacionado encontrado.')
                : Column(
                    children: relatedProjects
                        .map(
                          (project) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.workspaces_outline),
                            title: Text(project.title),
                            subtitle: Text(project.style),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _inviteToProject(artist),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Convidar para projeto'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Text('A definir');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) => Chip(label: Text(value))).toList(),
    );
  }
}
