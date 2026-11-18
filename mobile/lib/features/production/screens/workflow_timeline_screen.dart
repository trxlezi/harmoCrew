import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../collaboration/stores/collaboration_store.dart';
import '../data/production_api_service.dart';
import '../widgets/production_common.dart';

/*
 * Funcionalidade 3 - Workflow musical com timeline.
 *
 * Aba "Gantt": barras de cada tarefa no tempo, agrupadas pelas etapas
 * Composicao -> Arranjo -> Gravacao -> Mixagem -> Lancamento, com linha de
 * "hoje" e destaque para prazos estourados.
 * Aba "Quadro": Kanban por etapa, mudando o status com um toque.
 */
class WorkflowTimelineScreen extends StatefulWidget {
  const WorkflowTimelineScreen({super.key});

  static const routeName = '/workflow-timeline';

  @override
  State<WorkflowTimelineScreen> createState() => _WorkflowTimelineScreenState();
}

class _WorkflowTimelineScreenState extends State<WorkflowTimelineScreen> {
  final _api = ProductionApiService();
  String? _projectId;
  Map<String, dynamic>? _timeline;
  bool _loading = false;

  Future<void> _load() async {
    final projectId = _projectId;
    if (projectId == null) return;
    setState(() => _loading = true);
    try {
      final timeline = await _api.timeline(projectId);
      if (mounted) setState(() => _timeline = timeline);
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(Map<String, dynamic> task, String status) async {
    try {
      await _api.updateTaskStatus(task.i('id'), status);
      _load();
    } catch (error) {
      if (mounted) showMessage(context, error);
    }
  }

  Future<void> _newTask() async {
    final projectId = _projectId;
    if (projectId == null) return;
    final draft = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _TaskDialog(),
    );
    if (draft == null) return;
    try {
      await _api.createTask(projectId, draft);
      if (mounted) {
        showMessage(context, 'Tarefa criada. O responsavel foi avisado.');
      }
      _load();
    } catch (error) {
      if (mounted) showMessage(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timeline;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workflow musical'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gantt'),
              Tab(text: 'Quadro por etapa'),
            ],
          ),
        ),
        floatingActionButton: _projectId == null
            ? null
            : FloatingActionButton.extended(
                onPressed: _newTask,
                icon: const Icon(Icons.add_task),
                label: const Text('Tarefa'),
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
            if (timeline != null) _StageStepper(timeline: timeline),
            Expanded(
              child: timeline == null
                  ? const SizedBox()
                  : TabBarView(
                      children: [
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _Gantt(timeline: timeline),
                        ),
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _StageBoard(
                            timeline: timeline,
                            onStatus: _setStatus,
                          ),
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

class _StageStepper extends StatelessWidget {
  const _StageStepper({required this.timeline});

  final Map<String, dynamic> timeline;

  @override
  Widget build(BuildContext context) {
    final current = timeline.s('currentStage');
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (final (index, stage) in timeline.l('stages').indexed) ...[
            if (index > 0) const Icon(Icons.chevron_right, size: 18),
            Chip(
              avatar:
                  stage.i('totalTasks') > 0 && stage.i('progressPercent') == 100
                  ? const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.green,
                    )
                  : null,
              backgroundColor: stage.s('stage') == current
                  ? scheme.primaryContainer
                  : null,
              label: Text('${stage.s('label')} ${stage.i('progressPercent')}%'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Gantt extends StatelessWidget {
  const _Gantt({required this.timeline});

  final Map<String, dynamic> timeline;

  static const _dayWidth = 18.0;
  static const _labelWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    final tasks = [
      for (final stage in timeline.l('stages'))
        for (final task in stage.l('tasks')) task,
    ];
    final dated = tasks.where((t) => t.s('dueDate').isNotEmpty).toList();
    if (dated.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Crie tarefas com etapa, inicio e prazo para ver a timeline.',
            ),
          ),
        ],
      );
    }
    DateTime start(Map<String, dynamic> t) => DateTime.parse(
      t.s('startDate').isEmpty ? t.s('dueDate') : t.s('startDate'),
    );
    DateTime end(Map<String, dynamic> t) => DateTime.parse(t.s('dueDate'));
    final today = DateUtils.dateOnly(DateTime.now());
    final first = dated
        .map(start)
        .followedBy([today])
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final last = dated
        .map(end)
        .followedBy([today])
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final days = last.difference(first).inDays + 2;
    final scheme = Theme.of(context).colorScheme;
    final stageColors = [
      Colors.purple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
    ];

    final rows = <Widget>[];
    for (final (stageIndex, stage) in timeline.l('stages').indexed) {
      final stageTasks = stage
          .l('tasks')
          .where((t) => t.s('dueDate').isNotEmpty)
          .toList();
      if (stageTasks.isEmpty) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            '${stage.s('label')} - ${stage.i('doneTasks')}/${stage.i('totalTasks')}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );
      for (final task in stageTasks) {
        final offset = start(task).difference(first).inDays;
        final length = math.max(
          1,
          end(task).difference(start(task)).inDays + 1,
        );
        final done = task.s('status') == 'DONE';
        final overdue = task.b('overdue');
        rows.add(
          SizedBox(
            height: 34,
            child: Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    '${task.s('title')}${task.s('assigneeName').isEmpty ? '' : ' (${task.s('assigneeName')})'}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: overdue ? scheme.error : null,
                    ),
                  ),
                ),
                SizedBox(
                  width: days * _dayWidth,
                  child: Stack(
                    children: [
                      Positioned(
                        left:
                            today.difference(first).inDays * _dayWidth +
                            _dayWidth / 2,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: scheme.error.withValues(alpha: 0.4),
                        ),
                      ),
                      Positioned(
                        left: offset * _dayWidth,
                        top: 7,
                        child: Tooltip(
                          message:
                              '${task.s('title')}\n${taskStatusLabel(task.s('status'))} - prazo ${formatDateTime(task.s('dueDate'), withTime: false)}',
                          child: Container(
                            width: length * _dayWidth,
                            height: 20,
                            decoration: BoxDecoration(
                              color:
                                  (overdue
                                          ? scheme.error
                                          : stageColors[stageIndex %
                                                stageColors.length])
                                      .withValues(alpha: done ? 0.35 : 0.85),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: _labelWidth),
                  for (var d = 0; d < days; d++)
                    SizedBox(
                      width: _dayWidth,
                      child: Text(
                        first.add(Duration(days: d)).day == 1 ||
                                d == 0 ||
                                first.add(Duration(days: d)).weekday == 1
                            ? '${first.add(Duration(days: d)).day}/${first.add(Duration(days: d)).month}'
                            : '',
                        style: const TextStyle(fontSize: 9),
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                ],
              ),
              ...rows,
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Linha vermelha = hoje. Barras vermelhas = prazo estourado. Tarefas sem etapa: '
          '${timeline.l('unstagedTasks').length}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StageBoard extends StatelessWidget {
  const _StageBoard({required this.timeline, required this.onStatus});

  final Map<String, dynamic> timeline;
  final void Function(Map<String, dynamic> task, String status) onStatus;

  @override
  Widget build(BuildContext context) {
    final stages = [
      ...timeline.l('stages'),
      {
        'label': 'Sem etapa',
        'tasks': timeline['unstagedTasks'],
        'overdueTasks': 0,
      },
    ];
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      children: [
        for (final stage in stages)
          SizedBox(
            width: 260,
            child: Card(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Text(
                    stage.s('label'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (stage.i('overdueTasks') > 0)
                    Text(
                      '${stage.i('overdueTasks')} atrasada(s)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 8),
                  for (final task in stage.l('tasks'))
                    Card(
                      color: task.b('overdue')
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.s('title'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Dono: ${task.s('assigneeName', task.s('responsibleName', '-'))}',
                            ),
                            if (task.s('dueDate').isNotEmpty)
                              Text(
                                'Prazo: ${formatDateTime(task.s('dueDate'), withTime: false)}',
                              ),
                            const SizedBox(height: 6),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: 'TODO',
                                  label: Text('A fazer'),
                                ),
                                ButtonSegment(
                                  value: 'IN_PROGRESS',
                                  label: Text('Fazendo'),
                                ),
                                ButtonSegment(
                                  value: 'DONE',
                                  label: Text('Feito'),
                                ),
                              ],
                              selected: {task.s('status')},
                              onSelectionChanged: (value) =>
                                  onStatus(task, value.first),
                            ),
                          ],
                        ),
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

class _TaskDialog extends StatefulWidget {
  const _TaskDialog();

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  final _title = TextEditingController();
  String _stage = productionStages.first;
  String _priority = 'MEDIUM';
  String? _assignee;
  DateTime _start = DateUtils.dateOnly(DateTime.now());
  DateTime _due = DateUtils.dateOnly(
    DateTime.now(),
  ).add(const Duration(days: 7));

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _due = picked);
  }

  String _date(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    final artists = CollaborationStore.instance.artists;
    return AlertDialog(
      title: const Text('Nova tarefa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titulo'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _stage,
              decoration: const InputDecoration(labelText: 'Etapa'),
              items: productionStages
                  .map(
                    (s) =>
                        DropdownMenuItem(value: s, child: Text(stageLabel(s))),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _stage = v ?? _stage),
            ),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Prioridade'),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Baixa')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Media')),
                DropdownMenuItem(value: 'HIGH', child: Text('Alta')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? _priority),
            ),
            DropdownButtonFormField<String?>(
              initialValue: _assignee,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Responsavel'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sem dono definido'),
                ),
                ...artists.map(
                  (a) => DropdownMenuItem<String?>(
                    value: a.id,
                    child: Text(a.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _assignee = v),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _pick(true),
                    child: Text('Inicio ${_date(_start)}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _pick(false),
                    child: Text('Prazo ${_date(_due)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            final assigneeName = artists
                .where((a) => a.id == _assignee)
                .map((a) => a.name)
                .firstOrNull;
            Navigator.pop(context, {
              'title': _title.text.trim(),
              'status': 'TODO',
              'priority': _priority,
              'stage': _stage,
              'startDate': _date(_start),
              'dueDate': _date(_due),
              'responsibleName': assigneeName ?? 'Equipe',
              'assigneeArtistId': ?int.tryParse(_assignee ?? ''),
            });
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
