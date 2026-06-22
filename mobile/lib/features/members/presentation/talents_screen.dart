import 'package:flutter/material.dart';

import '../../collaboration/models/artist_profile.dart';
import '../../collaboration/models/project.dart';
import '../../collaboration/stores/collaboration_store.dart';
import '../../collaboration/widgets/collaboration_ui.dart';
import '../domain/member.dart';
import 'artist_detail_screen.dart';
import 'member_form_screen.dart';

class TalentsScreen extends StatefulWidget {
  const TalentsScreen({super.key});

  static const routeName = '/talents';

  @override
  State<TalentsScreen> createState() => _TalentsScreenState();
}

class _TalentsScreenState extends State<TalentsScreen> {
  final CollaborationStore _store = CollaborationStore.instance;
  final TextEditingController _searchController = TextEditingController();

  String? _instrumentFilter;
  String? _styleFilter;
  String? _availabilityFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final artist = await _store.createArtistFromApi(result);
      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${artist.name} cadastrado via API.')),
      );
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
  }

  Future<void> _loadArtists() async {
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
    final artists = _filteredArtists;

    return Scaffold(
      appBar: AppBar(title: const Text('Talentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMemberForm,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Cadastrar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Descoberta de talentos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Busque artistas por nome, instrumento, especialidade e estilo.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          if (_isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 18),
          ],
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar talento',
              prefixIcon: Icon(Icons.search),
              hintText: 'Nome, instrumento ou especialidade',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _FiltersWrap(
            instrumentFilter: _instrumentFilter,
            styleFilter: _styleFilter,
            availabilityFilter: _availabilityFilter,
            instruments: _allInstruments,
            styles: _allStyles,
            availabilities: _allAvailabilities,
            onInstrumentChanged: (value) =>
                setState(() => _instrumentFilter = value),
            onStyleChanged: (value) => setState(() => _styleFilter = value),
            onAvailabilityChanged: (value) =>
                setState(() => _availabilityFilter = value),
            onClear: () {
              setState(() {
                _instrumentFilter = null;
                _styleFilter = null;
                _availabilityFilter = null;
                _searchController.clear();
              });
            },
          ),
          const SizedBox(height: 18),
          if (artists.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              message: 'Nenhum talento encontrado.',
            )
          else
            ...artists.map(
              (artist) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ArtistCard(
                  artist: artist,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      ArtistDetailScreen.routeName,
                      arguments: ArtistDetailArguments(artistId: artist.id),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  List<ArtistProfile> get _filteredArtists {
    final query = _searchController.text.trim().toLowerCase();

    return _store.artists
        .where((artist) {
          final text = [
            artist.name,
            ...artist.specialties,
            ...artist.instruments,
          ].join(' ').toLowerCase();
          final matchesQuery = query.isEmpty || text.contains(query);
          final matchesInstrument =
              _instrumentFilter == null ||
              artist.instruments.contains(_instrumentFilter);
          final matchesStyle =
              _styleFilter == null || artist.styles.contains(_styleFilter);
          final matchesAvailability =
              _availabilityFilter == null ||
              artist.availability == _availabilityFilter;

          return matchesQuery &&
              matchesInstrument &&
              matchesStyle &&
              matchesAvailability;
        })
        .toList(growable: false);
  }

  List<String> get _allInstruments {
    return _uniqueSorted(_store.artists.expand((artist) => artist.instruments));
  }

  List<String> get _allStyles {
    return _uniqueSorted(_store.artists.expand((artist) => artist.styles));
  }

  List<String> get _allAvailabilities {
    return _uniqueSorted(_store.artists.map((artist) => artist.availability));
  }
}

class ArtistDetailArguments {
  const ArtistDetailArguments({required this.artistId});

  final String artistId;
}

class _FiltersWrap extends StatelessWidget {
  const _FiltersWrap({
    required this.instrumentFilter,
    required this.styleFilter,
    required this.availabilityFilter,
    required this.instruments,
    required this.styles,
    required this.availabilities,
    required this.onInstrumentChanged,
    required this.onStyleChanged,
    required this.onAvailabilityChanged,
    required this.onClear,
  });

  final String? instrumentFilter;
  final String? styleFilter;
  final String? availabilityFilter;
  final List<String> instruments;
  final List<String> styles;
  final List<String> availabilities;
  final ValueChanged<String?> onInstrumentChanged;
  final ValueChanged<String?> onStyleChanged;
  final ValueChanged<String?> onAvailabilityChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterDropdown(
          label: 'Instrumento',
          value: instrumentFilter,
          options: instruments,
          onChanged: onInstrumentChanged,
        ),
        _FilterDropdown(
          label: 'Estilo',
          value: styleFilter,
          options: styles,
          onChanged: onStyleChanged,
        ),
        _FilterDropdown(
          label: 'Disponibilidade',
          value: availabilityFilter,
          options: availabilities,
          onChanged: onAvailabilityChanged,
        ),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear),
          label: const Text('Limpar'),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Todos')),
          ...options.map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist, required this.onTap});

  final ArtistProfile artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primarySpecialty = artist.specialties.isEmpty
        ? 'Especialidade a definir'
        : artist.specialties.first;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(artist.name.substring(0, 1))),
        title: Text(artist.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primarySpecialty),
              const SizedBox(height: 4),
              Text('Instrumentos: ${_joinOrFallback(artist.instruments)}'),
              const SizedBox(height: 4),
              Text('Estilos: ${_joinOrFallback(artist.styles)}'),
              const SizedBox(height: 4),
              Text('Disponibilidade: ${artist.availability}'),
              if (artist.city.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Localidade: ${artist.city}'),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

List<String> _uniqueSorted(Iterable<String> values) {
  final sorted = values
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList();
  sorted.sort();
  return sorted;
}

String _joinOrFallback(List<String> values) {
  return values.isEmpty ? 'A definir' : values.join(', ');
}

List<Project> relatedProjectsForArtist(
  CollaborationStore store,
  ArtistProfile artist,
) {
  return store.projects
      .where((project) {
        final ownsProject = project.ownerArtistId == artist.id;
        final hasTask = store
            .tasksForProject(project.id)
            .any((task) => task.assignedToArtistId == artist.id);
        final hasGoal = store
            .weeklyGoalsForProject(project.id)
            .any((goal) => goal.ownerArtistId == artist.id);
        final hasRehearsal = store
            .rehearsalsForProject(project.id)
            .any(
              (rehearsal) => rehearsal.participantArtistIds.contains(artist.id),
            );
        final matchesNeed = project.needs.any(
          (need) =>
              artist.instruments.contains(need) ||
              artist.specialties.contains(need),
        );

        return ownsProject || hasTask || hasGoal || hasRehearsal || matchesNeed;
      })
      .toList(growable: false);
}
