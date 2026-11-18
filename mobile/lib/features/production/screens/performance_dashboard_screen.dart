import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../collaboration/stores/collaboration_store.dart';
import '../data/production_api_service.dart';
import '../widgets/production_common.dart';

/*
 * Funcionalidade 4 - Dashboard de performance e metricas do coletivo.
 * Taxa de conclusao, pontualidade, assiduidade nos ensaios, ritmo semanal,
 * desempenho por integrante e por projeto, ultimas tarefas e arquivos
 * importantes. Pode ver o coletivo todo ou um projeto especifico.
 */
class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({super.key});

  static const routeName = '/performance-dashboard';

  @override
  State<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends State<PerformanceDashboardScreen> {
  final _api = ProductionApiService();
  bool _collective = true;
  String? _projectId;
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_collective && _projectId == null) return;
    setState(() => _loading = true);
    try {
      final data = await _api.dashboard(
        projectId: _collective ? null : _projectId,
      );
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /*
   * Registro de presenca: base da metrica de assiduidade. Escolhe o ensaio e
   * marca quem compareceu; o ensaio passa a constar como realizado.
   */
  Future<void> _registerAttendance() async {
    final store = CollaborationStore.instance;
    try {
      await store.syncAll();
    } catch (error) {
      if (mounted) showMessage(context, error);
      return;
    }
    if (!mounted) return;
    final rehearsals = store.rehearsals;
    if (rehearsals.isEmpty) {
      showMessage(context, 'Nenhum ensaio cadastrado.');
      return;
    }
    var rehearsal = rehearsals.first;
    final attended = <String>{};
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          // Sem convidados definidos: lista todos os artistas (a API valida).
          final invitedIds = rehearsal.participantArtistIds.toSet();
          final invited = store.artists
              .where((a) => invitedIds.isEmpty || invitedIds.contains(a.id))
              .toList();
          return AlertDialog(
            title: const Text('Presenca no ensaio'),
            content: SizedBox(
              width: 360,
              child: ListView(
                shrinkWrap: true,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: rehearsal.id,
                    isExpanded: true,
                    items: rehearsals
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text('${r.title} - ${r.date}'),
                          ),
                        )
                        .toList(),
                    onChanged: (id) => setDialog(() {
                      rehearsal = rehearsals.firstWhere((r) => r.id == id);
                      attended.clear();
                    }),
                  ),
                  for (final artist in invited)
                    CheckboxListTile(
                      value: attended.contains(artist.id),
                      title: Text(artist.name),
                      onChanged: (v) => setDialog(
                        () => v == true
                            ? attended.add(artist.id)
                            : attended.remove(artist.id),
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
          );
        },
      ),
    );
    if (saved != true) return;
    try {
      await _api.registerAttendance(
        int.parse(rehearsal.id),
        attended.map(int.parse).toSet(),
      );
      if (mounted) showMessage(context, 'Presenca registrada.');
      _load();
    } catch (error) {
      if (mounted) showMessage(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance do coletivo'),
        actions: [
          IconButton(
            tooltip: 'Registrar presenca em ensaio',
            onPressed: _registerAttendance,
            icon: const Icon(Icons.how_to_reg_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Coletivo'),
                  icon: Icon(Icons.groups),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Projeto'),
                  icon: Icon(Icons.album),
                ),
              ],
              selected: {_collective},
              onSelectionChanged: (v) {
                setState(() => _collective = v.first);
                _load();
              },
            ),
            if (!_collective) ...[
              const SizedBox(height: 8),
              ProjectPickerBar(
                selectedId: _projectId,
                onChanged: (id) {
                  setState(() => _projectId = id);
                  _load();
                },
              ),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (data != null) ..._content(context, data),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, Map<String, dynamic> d) {
    String pct(String key) => d.n(key) == null ? '-' : '${d.n(key)}%';
    return [
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _Kpi(
            'Conclusao',
            '${d.i('completionPercent')}%',
            '${d.i('doneTasks')}/${d.i('totalTasks')} entregaveis',
            Icons.task_alt,
          ),
          _Kpi(
            'No prazo',
            pct('onTimePercent'),
            'das entregas concluidas',
            Icons.timer_outlined,
          ),
          _Kpi(
            'Assiduidade',
            pct('attendancePercent'),
            '${d.i('rehearsalsCompleted')} ensaio(s) realizados',
            Icons.event_available,
          ),
          _Kpi(
            'Atrasadas',
            '${d.i('overdueTasks')}',
            'tarefas com prazo estourado',
            Icons.alarm,
            alert: d.i('overdueTasks') > 0,
          ),
          _Kpi(
            'Metas semanais',
            pct('weeklyGoalsPercent'),
            '${d.i('weeklyGoalsDone')}/${d.i('weeklyGoalsTotal')} cumpridas',
            Icons.flag_outlined,
          ),
          _Kpi(
            'Tempo medio',
            d['averageCompletionDays'] == null
                ? '-'
                : '${d['averageCompletionDays']} d',
            'do inicio a entrega',
            Icons.speed,
          ),
          _Kpi(
            'Enquetes abertas',
            '${d.i('openPolls')}',
            '${d.i('decisionsRegistered')} decisoes registradas',
            Icons.how_to_vote,
          ),
          _Kpi(
            'Candidaturas',
            '${d.i('pendingApplications')}',
            'aguardando avaliacao',
            Icons.person_search,
          ),
        ],
      ),
      _Section(
        title: 'Status das tarefas',
        child: Column(
          children: [
            for (final entry in d.m('tasksByStatus').entries)
              PercentBar(
                label: taskStatusLabel(entry.key),
                percent: d.i('totalTasks') == 0
                    ? 0
                    : ((entry.value as num) * 100 / d.i('totalTasks')).round(),
                trailing: '${entry.value}',
              ),
          ],
        ),
      ),
      _Section(
        title: 'Tarefas por etapa do workflow',
        child: Column(
          children: [
            for (final entry in d.m('tasksByStage').entries)
              if ((entry.value as num) > 0)
                PercentBar(
                  label: stageLabel(entry.key),
                  percent: d.i('totalTasks') == 0
                      ? 0
                      : ((entry.value as num) * 100 / d.i('totalTasks'))
                            .round(),
                  trailing: '${entry.value}',
                ),
          ],
        ),
      ),
      _Section(
        title: 'Ritmo semanal (ultimas 8 semanas)',
        child: _WeeklyChart(points: d.l('weeklyThroughput')),
      ),
      _Section(
        title: 'Desempenho por integrante',
        child: Column(
          children: [
            if (d.l('members').isEmpty)
              const Text('Sem integrantes nos projetos.'),
            for (final member in d.l('members'))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    member.s('name').isEmpty ? '?' : member.s('name')[0],
                  ),
                ),
                title: Text(member.s('name')),
                subtitle: Text(
                  'Tarefas: ${member.i('doneTasks')}/${member.i('assignedTasks')} concluidas'
                  '${member.i('overdueTasks') > 0 ? ' - ${member.i('overdueTasks')} atrasada(s)' : ''}\n'
                  'Ensaios: ${member.i('rehearsalsAttended')}/${member.i('rehearsalsInvited')}',
                ),
                isThreeLine: true,
                trailing: Text(
                  member.n('attendancePercent') == null
                      ? '-'
                      : '${member.n('attendancePercent')}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
      ),
      if (_collective)
        _Section(
          title: 'Projetos',
          child: Column(
            children: [
              for (final project in d.l('projects'))
                PercentBar(
                  label:
                      '${project.s('title')}'
                      '${project.s('currentStage').isEmpty ? '' : ' - ${stageLabel(project.s('currentStage'))}'}',
                  percent: project.i('completionPercent'),
                  trailing:
                      '${project.i('completionPercent')}%'
                      '${project.i('overdueTasks') > 0 ? ' (${project.i('overdueTasks')} atrasada)' : ''}',
                ),
            ],
          ),
        ),
      _Section(
        title: 'Proximos prazos',
        child: _TaskList(
          tasks: d.l('upcomingDeadlines'),
          empty: 'Nenhum prazo pendente.',
        ),
      ),
      _Section(
        title: 'Ultimas tarefas atualizadas',
        child: _TaskList(
          tasks: d.l('recentTasks'),
          empty: 'Sem atividade recente.',
        ),
      ),
      _Section(
        title: 'Arquivos importantes',
        child: Column(
          children: [
            if (d.l('importantFiles').isEmpty)
              const Text('Nenhum arquivo enviado.'),
            for (final file in d.l('importantFiles'))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  file.b('locked') ? Icons.lock : Icons.description_outlined,
                ),
                title: Text(file.s('name')),
                subtitle: Text(
                  '${fileCategoryLabel(file.s('category'))} - v${file.m('currentVersion').s('versionNumber')}'
                  '${file.b('locked') ? ' (decidida)' : ''}',
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openExternalUrl(
                  context,
                  _api.mediaUrl(file.m('currentVersion').s('url')),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(
    this.title,
    this.value,
    this.caption,
    this.icon, {
    this.alert = false,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: alert ? scheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
              ],
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              caption,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.empty});

  final List<Map<String, dynamic>> tasks;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return Text(empty);
    return Column(
      children: [
        for (final task in tasks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              task.b('overdue') ? Icons.alarm : Icons.task_alt,
              color: task.b('overdue')
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            title: Text(task.s('title')),
            subtitle: Text(
              '${task.s('projectTitle')} - ${stageLabel(task.s('stage'))} - ${taskStatusLabel(task.s('status'))}'
              '${task.s('dueDate').isEmpty ? '' : ' - prazo ${formatDateTime(task.s('dueDate'), withTime: false)}'}',
            ),
          ),
      ],
    );
  }
}

// Grafico de barras agrupadas: criadas x concluidas por semana.
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.points});

  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = points.fold<int>(
      1,
      (m, p) => math.max(m, math.max(p.i('created'), p.i('completed'))),
    );
    Widget bar(int value, Color color) => Container(
      width: 10,
      height: 4 + 80 * value / maxValue,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final point in points)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${point.i('completed')}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        bar(
                          point.i('created'),
                          scheme.secondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 2),
                        bar(point.i('completed'), scheme.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(
                        point.s('weekStart'),
                        withTime: false,
                      ).substring(0, 5),
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.square,
              size: 12,
              color: scheme.secondary.withValues(alpha: 0.5),
            ),
            const Text(' planejadas   '),
            Icon(Icons.square, size: 12, color: scheme.primary),
            const Text(' concluidas'),
          ],
        ),
      ],
    );
  }
}
