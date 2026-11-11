import 'package:flutter/material.dart';

import '../data/production_api_service.dart';
import '../widgets/production_common.dart';

/*
 * Funcionalidade 1 - Correspondencia algoritmica.
 *
 * Aba "Ranking": musicos ordenados pela similaridade com a vaga (estilo,
 * instrumentos, influencias e cidade), com filtros por estilo.
 * Aba "Candidaturas": candidatos da vaga ordenados pela nota, com audio do
 * perfil e mudanca de status (o musico recebe retorno a cada mudanca).
 */
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  static const routeName = '/matching';

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final _api = ProductionApiService();
  final _style = TextEditingController();
  final _instrument = TextEditingController();
  final _city = TextEditingController();

  String? _projectId;
  double _minScore = 0;
  bool _loading = false;
  List<Map<String, dynamic>> _matches = const [];
  List<Map<String, dynamic>> _applications = const [];

  @override
  void dispose() {
    _style.dispose();
    _instrument.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final projectId = _projectId;
    if (projectId == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.matches(
          projectId,
          style: _style.text.trim(),
          instrument: _instrument.text.trim(),
          city: _city.text.trim(),
          minScore: _minScore.round(),
        ),
        _api.rankedApplications(projectId),
      ]);
      if (!mounted) return;
      setState(() {
        _matches = results[0];
        _applications = results[1];
      });
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /*
   * Requisitos da vaga usados no calculo: estilo, necessidades (instrumentos),
   * cidade e influencias desejadas.
   */
  Future<void> _editRequirements() async {
    final projectId = _projectId;
    if (projectId == null) return;
    Map<String, dynamic> project;
    try {
      project = await _api.project(projectId);
    } catch (error) {
      if (mounted) showMessage(context, error);
      return;
    }
    if (!mounted) return;
    final style = TextEditingController(text: project.s('musicalStyle'));
    final needs = TextEditingController(
      text: project.strings('needs').join(', '),
    );
    final location = TextEditingController(text: project.s('location'));
    final influences = TextEditingController(
      text: project.strings('desiredInfluences').join(', '),
    );
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Requisitos da vaga'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: style,
                decoration: const InputDecoration(labelText: 'Estilo'),
              ),
              TextField(
                controller: needs,
                decoration: const InputDecoration(
                  labelText: 'Instrumentos/funcoes (virgula)',
                ),
              ),
              TextField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              TextField(
                controller: influences,
                decoration: const InputDecoration(
                  labelText: 'Influencias desejadas (virgula)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    List<String> split(String text) => text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final body = {
      'title': project.s('title'),
      'description': project['description'],
      'musicalStyle': style.text.trim(),
      'status': project.s('status', 'ACTIVE'),
      'needs': split(needs.text),
      'startDate': project.s('startDate'),
      'location': location.text.trim(),
      'desiredInfluences': split(influences.text),
    };
    for (final c in [style, needs, location, influences]) {
      c.dispose();
    }
    if (save != true) return;
    try {
      await _api.updateProject(projectId, body);
      if (mounted) showMessage(context, 'Requisitos atualizados.');
      _load();
    } catch (error) {
      if (mounted) showMessage(context, error);
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> application,
    String status,
  ) async {
    final noteController = TextEditingController(
      text: application.s('evaluationNote'),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marcar como "${applicationStatusLabel(status)}"'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Retorno para o musico (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (confirmed != true) return;
    try {
      await _api.updateApplication(
        application.s('id'),
        status,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      showMessage(
        context,
        'Candidato notificado: ${applicationStatusLabel(status)}',
      );
      _load();
    } catch (error) {
      if (mounted) showMessage(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selecao de musicos'),
          actions: [
            IconButton(
              tooltip: 'Requisitos da vaga',
              onPressed: _projectId == null ? null : _editRequirements,
              icon: const Icon(Icons.tune),
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Ranking'),
              Tab(text: 'Candidaturas (${_applications.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ProjectPickerBar(
                selectedId: _projectId,
                onChanged: (id) {
                  setState(() => _projectId = id);
                  _load();
                },
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: TabBarView(
                children: [_buildRanking(), _buildApplications()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRanking() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.filter_alt_outlined),
            title: const Text('Filtros'),
            children: [
              TextField(
                controller: _style,
                decoration: const InputDecoration(
                  labelText: 'Estilo (ex.: rock)',
                ),
              ),
              TextField(
                controller: _instrument,
                decoration: const InputDecoration(labelText: 'Instrumento'),
              ),
              TextField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              const SizedBox(height: 8),
              Text('Compatibilidade minima: ${_minScore.round()}%'),
              Slider(
                value: _minScore,
                max: 100,
                divisions: 10,
                onChanged: (v) => setState(() => _minScore = v),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          if (_matches.isEmpty && !_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhum musico encontrado para os filtros.'),
            ),
          for (final (index, match) in _matches.indexed)
            _MatchCard(position: index + 1, match: match, api: _api),
        ],
      ),
    );
  }

  Widget _buildApplications() {
    if (_applications.isEmpty) {
      return const Center(child: Text('Nenhuma candidatura para esta vaga.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final application in _applications)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ScoreBadge(score: application.n('matchScore')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            application.s('artistName', 'Artista'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Chip(
                          label: Text(
                            applicationStatusLabel(application.s('status')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${application.s('specialty')} - ${application.s('availability')}',
                    ),
                    const SizedBox(height: 4),
                    Text(application.s('message')),
                    if (application.s('evaluationNote').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Retorno: ${application.s('evaluationNote')}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                    if (application.s('statusUpdatedAt').isNotEmpty)
                      Text(
                        'Atualizada em ${formatDateTime(application.s('statusUpdatedAt'))}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (application.s('artistAudioUrl').isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => openExternalUrl(
                              context,
                              _api.mediaUrl(application.s('artistAudioUrl')),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Ouvir audio'),
                          ),
                        for (final status in const [
                          'UNDER_REVIEW',
                          'SHORTLISTED',
                          'APPROVED',
                          'REJECTED',
                        ])
                          if (status != application.s('status'))
                            ActionChip(
                              label: Text(applicationStatusLabel(status)),
                              onPressed: () =>
                                  _changeStatus(application, status),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.position,
    required this.match,
    required this.api,
  });

  final int position;
  final Map<String, dynamic> match;
  final ProductionApiService api;

  static const _criteria = {
    'STYLE': 'Estilo',
    'INSTRUMENTS': 'Instrumentos',
    'INFLUENCES': 'Influencias',
    'LOCATION': 'Localizacao',
  };

  @override
  Widget build(BuildContext context) {
    final applied = match.l('breakdown').where((c) => c.b('applied')).toList();
    final status = match.s('applicationStatus');
    return Card(
      child: ExpansionTile(
        leading: _ScoreBadge(score: match.i('score')),
        title: Text('$position. ${match.s('stageName')}'),
        subtitle: Text(
          [
            match.s('mainSpecialty'),
            match.s('city'),
            if (match.b('member')) 'ja integra o projeto',
            if (status.isNotEmpty)
              'candidatura: ${applicationStatusLabel(status)}',
          ].where((e) => e.isNotEmpty).join(' - '),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final criterion in applied)
            PercentBar(
              label:
                  '${_criteria[criterion.s('criterion')] ?? criterion.s('criterion')} (peso ${criterion.i('weight')})',
              percent: criterion.i('score'),
            ),
          if (applied.isEmpty)
            const Text('A vaga nao define requisitos para comparar.'),
          const SizedBox(height: 8),
          Text('Estilos: ${match.strings('musicalStyles').join(', ')}'),
          Text('Instrumentos: ${match.strings('instruments').join(', ')}'),
          if (match.strings('influences').isNotEmpty)
            Text('Influencias: ${match.strings('influences').join(', ')}'),
          if (match.strings('matchedInstruments').isNotEmpty)
            Text('Atende: ${match.strings('matchedInstruments').join(', ')}'),
          if (match.s('audioUrl').isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  openExternalUrl(context, api.mediaUrl(match.s('audioUrl'))),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Ouvir audio do perfil'),
            ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final value = score ?? 0;
    final color = value >= 75
        ? Colors.green
        : value >= 40
        ? Colors.amber.shade700
        : Colors.redAccent;
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      foregroundColor: color,
      child: Text(
        score == null ? '-' : '$value',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
