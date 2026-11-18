import 'package:flutter/material.dart';

import '../data/production_api_service.dart';
import '../widgets/production_common.dart';

/*
 * Funcionalidade 2 - Central de decisao de setlist e versionamento.
 *
 * - Arquivos: upload de guias, arranjos e PDFs com historico de versoes,
 *   autor, data e link imutavel de cada versao.
 * - Enquetes: decisoes em grupo; ao encerrar viram registro de decisao e,
 *   se a opcao vencedora for uma versao de arquivo, o arquivo trava nela.
 * - Auditoria: tudo o que aconteceu no projeto, somente leitura.
 */
class DecisionCenterScreen extends StatefulWidget {
  const DecisionCenterScreen({super.key});

  static const routeName = '/decision-center';

  @override
  State<DecisionCenterScreen> createState() => _DecisionCenterScreenState();
}

class _DecisionCenterScreenState extends State<DecisionCenterScreen> {
  final _api = ProductionApiService();
  String? _projectId;
  bool _loading = false;
  List<Map<String, dynamic>> _files = const [];
  List<Map<String, dynamic>> _polls = const [];
  List<Map<String, dynamic>> _audit = const [];

  Future<void> _load() async {
    final projectId = _projectId;
    if (projectId == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.files(projectId),
        _api.polls(projectId),
        _api.auditLogs(projectId),
      ]);
      if (!mounted) return;
      setState(() {
        _files = results[0];
        _polls = results[1];
        _audit = results[2];
      });
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) showMessage(context, success);
      await _load();
    } catch (error) {
      if (mounted) {
        showMessage(context, error);
        setState(() => _loading = false);
      }
    }
  }

  // --------------------------------------------------------------- arquivos

  Future<void> _newFile() async {
    final projectId = _projectId;
    if (projectId == null) return;
    final picked = await pickFile();
    if (picked == null || !mounted) return;
    final name = TextEditingController(text: picked.name);
    final note = TextEditingController();
    var category = 'ARRANGEMENT';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Novo arquivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items:
                    const [
                          'AUDIO_GUIDE',
                          'ARRANGEMENT',
                          'SHEET_PDF',
                          'LYRICS',
                          'SETLIST',
                          'OTHER',
                        ]
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(fileCategoryLabel(c)),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setDialog(() => category = v ?? category),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'Observacao da versao',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    final fileName = name.text.trim();
    final noteText = note.text.trim();
    name.dispose();
    note.dispose();
    if (ok != true) return;
    await _run(
      () => _api.createFile(
        projectId,
        bytes: picked.bytes,
        filename: picked.name,
        name: fileName,
        category: category,
        note: noteText.isEmpty ? null : noteText,
        artistId: currentArtistId,
      ),
      'Arquivo enviado (v1).',
    );
  }

  Future<void> _newVersion(Map<String, dynamic> file) async {
    final picked = await pickFile();
    if (picked == null || !mounted) return;
    final note = await _ask('O que mudou nesta versao?');
    if (note == null) return;
    await _run(
      () => _api.uploadVersion(
        file.s('id'),
        bytes: picked.bytes,
        filename: picked.name,
        note: note.isEmpty ? null : note,
        artistId: currentArtistId,
      ),
      'Nova versao enviada.',
    );
  }

  Future<void> _unlock(Map<String, dynamic> file) async {
    final reason = await _ask('Motivo para destravar a versao decidida');
    if (reason == null || reason.isEmpty) return;
    await _run(
      () => _api.unlockFile(file.s('id'), reason, currentArtistId),
      'Arquivo destravado (registrado na auditoria).',
    );
  }

  Future<String?> _ask(String label) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  // ---------------------------------------------------------------- enquetes

  Future<void> _newPoll() async {
    final projectId = _projectId;
    if (projectId == null) return;
    final result = await showDialog<_PollDraft>(
      context: context,
      builder: (_) => _PollDialog(files: _files),
    );
    if (result == null) return;
    await _run(
      () => _api.createPoll(
        projectId,
        question: result.question,
        closesAt: result.closesAt,
        artistId: currentArtistId,
        options: result.options,
      ),
      'Enquete aberta. O grupo foi avisado.',
    );
  }

  Future<void> _close(Map<String, dynamic> poll) async {
    try {
      await _api.closePoll(poll.i('id'), currentArtistId);
      if (mounted) showMessage(context, 'Enquete encerrada e registrada.');
      _load();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      if (!message.contains('Empate')) {
        showMessage(context, error);
        return;
      }
      // Empate: o usuario escolhe a opcao de desempate.
      final max = poll
          .l('options')
          .map((o) => o.i('votes'))
          .fold<int>(0, (a, b) => a > b ? a : b);
      final tied = poll.l('options').where((o) => o.i('votes') == max).toList();
      final choice = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Empate - escolha a decisao final'),
          children: [
            for (final option in tied)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, option.i('id')),
                child: Text(option.s('label')),
              ),
          ],
        ),
      );
      if (choice == null) return;
      await _run(
        () => _api.closePoll(
          poll.i('id'),
          currentArtistId,
          tieBreakOptionId: choice,
        ),
        'Enquete encerrada com desempate.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Central de decisoes'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Arquivos'),
                Tab(text: 'Enquetes'),
                Tab(text: 'Auditoria'),
              ],
            ),
          ),
          floatingActionButton: _projectId == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    final tab = DefaultTabController.of(context).index;
                    if (tab == 0) {
                      _newFile();
                    } else {
                      _newPoll();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo'),
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
                  children: [_buildFiles(), _buildPolls(), _buildAudit()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiles() {
    if (_files.isEmpty) {
      return const Center(
        child: Text('Nenhum arquivo. Use "Novo" para enviar.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          for (final file in _files)
            Card(
              child: ExpansionTile(
                leading: Icon(
                  file.b('locked') ? Icons.lock : Icons.description_outlined,
                ),
                title: Text(file.s('name')),
                subtitle: Text(
                  '${fileCategoryLabel(file.s('category'))} - '
                  '${file.b('locked') ? 'decidido: v${file.s('lockedVersionNumber')}' : 'atual: v${file.m('currentVersion').s('versionNumber')}'}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  for (final version in file.l('versions'))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(
                          'v${version.s('versionNumber')}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      title: Text(
                        '${version.s('uploadedByName', 'Desconhecido')} - ${formatDateTime(version.s('uploadedAt'))}'
                        '${version.b('decided') ? '  (DECIDIDA)' : ''}',
                      ),
                      subtitle: Text(
                        [
                          version.s('note'),
                          version.s('originalFilename'),
                          'sha256 ${version.s('sha256').padRight(8).substring(0, 8)}',
                        ].where((e) => e.isNotEmpty).join(' - '),
                      ),
                      trailing: IconButton(
                        tooltip: 'Abrir link imutavel',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => openExternalUrl(
                          context,
                          _api.mediaUrl(version.s('url')),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (file.b('locked'))
                        TextButton.icon(
                          onPressed: () => _unlock(file),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Destravar'),
                        )
                      else
                        FilledButton.tonalIcon(
                          onPressed: () => _newVersion(file),
                          icon: const Icon(Icons.upload),
                          label: const Text('Nova versao'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPolls() {
    if (_polls.isEmpty) {
      return const Center(
        child: Text('Nenhuma enquete. Use "Novo" para criar.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [for (final poll in _polls) _pollCard(poll)],
      ),
    );
  }

  Widget _pollCard(Map<String, dynamic> poll) {
    final open = poll.s('status') == 'OPEN';
    final total = poll.i('totalVotes');
    final me = currentArtistId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    poll.s('question'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(open ? 'Aberta' : 'Encerrada')),
              ],
            ),
            if (poll.s('closesAt').isNotEmpty)
              Text(
                'Prazo: ${formatDateTime(poll.s('closesAt'))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            for (final option in poll.l('options'))
              InkWell(
                onTap: !open
                    ? null
                    : () => _run(
                        () => _api.vote(poll.i('id'), option.i('id'), me),
                        'Voto registrado.',
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: PercentBar(
                    label:
                        '${poll.n('winningOptionId') == option.i('id') ? '★ ' : ''}${option.s('label')}'
                        '${option.n('fileVersionNumber') == null ? '' : ' (arquivo v${option.s('fileVersionNumber')})'}',
                    percent: total == 0
                        ? 0
                        : (option.i('votes') * 100 / total).round(),
                    trailing: '${option.i('votes')} voto(s)',
                    color: poll.n('winningOptionId') == option.i('id')
                        ? Colors.green
                        : null,
                  ),
                ),
              ),
            if (open) ...[
              const SizedBox(height: 4),
              Text(
                'Toque em uma opcao para votar (pode trocar enquanto aberta).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: total == 0 ? null : () => _close(poll),
                  icon: const Icon(Icons.gavel),
                  label: const Text('Encerrar e registrar'),
                ),
              ),
            ] else if (poll.n('decisionRecordId') != null)
              Text(
                'Registrada como decisao #${poll.s('decisionRecordId')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudit() {
    if (_audit.isEmpty) {
      return const Center(child: Text('Sem eventos registrados.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _audit.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = _audit[index];
          return ListTile(
            dense: true,
            leading: Icon(_auditIcon(log.s('action'))),
            title: Text(log.s('details', log.s('action'))),
            subtitle: Text(
              '${formatDateTime(log.s('createdAt'))}'
              '${log.s('actorName').isEmpty ? '' : ' - ${log.s('actorName')}'} - ${log.s('action')}',
            ),
          );
        },
      ),
    );
  }

  IconData _auditIcon(String action) {
    if (action.startsWith('FILE_LOCKED')) return Icons.lock;
    if (action.startsWith('FILE_UNLOCKED')) return Icons.lock_open;
    if (action.startsWith('FILE')) return Icons.upload_file;
    if (action.startsWith('POLL_VOTE')) return Icons.how_to_vote;
    if (action.startsWith('POLL')) return Icons.poll_outlined;
    if (action.startsWith('TASK')) return Icons.task_alt;
    if (action.startsWith('APPLICATION')) return Icons.person_search;
    return Icons.history;
  }
}

class _PollDraft {
  _PollDraft(this.question, this.closesAt, this.options);

  final String question;
  final DateTime? closesAt;
  final List<({String label, int? fileVersionId})> options;
}

class _PollDialog extends StatefulWidget {
  const _PollDialog({required this.files});

  final List<Map<String, dynamic>> files;

  @override
  State<_PollDialog> createState() => _PollDialogState();
}

class _PollDialogState extends State<_PollDialog> {
  final _question = TextEditingController();
  final List<TextEditingController> _labels = [
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime? _closesAt;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _labels) {
      c.dispose();
    }
    super.dispose();
  }

  // Cria uma opcao por versao do arquivo escolhido (decidir qual versao vale).
  void _fromFile(Map<String, dynamic> file) {
    setState(() {
      _question.text = _question.text.isEmpty
          ? 'Qual versao de "${file.s('name')}" usar?'
          : _question.text;
      for (final c in _labels) {
        c.dispose();
      }
      _labels
        ..clear()
        ..addAll(
          file
              .l('versions')
              .reversed
              .map(
                (v) => TextEditingController(
                  text: 'v${v.s('versionNumber')}#${v.s('id')}',
                ),
              ),
        );
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    setState(
      () => _closesAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 20,
        time?.minute ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova enquete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _question,
              decoration: const InputDecoration(
                labelText: 'Pergunta (ex.: setlist do show)',
              ),
            ),
            const SizedBox(height: 8),
            for (final (index, controller) in _labels.indexed)
              TextField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Opcao ${index + 1}'),
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _labels.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar opcao'),
            ),
            if (widget.files.isNotEmpty)
              PopupMenuButton<Map<String, dynamic>>(
                onSelected: _fromFile,
                itemBuilder: (_) => [
                  for (final f in widget.files.where(
                    (f) => f.l('versions').length > 1,
                  ))
                    PopupMenuItem(value: f, child: Text(f.s('name'))),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Usar versoes de um arquivo como opcoes...',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.schedule),
              label: Text(
                _closesAt == null
                    ? 'Sem prazo'
                    : 'Prazo: ${formatDateTime(_closesAt!.toIso8601String())}',
              ),
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
            final options = _labels
                .map((c) => c.text.trim())
                .where((t) => t.isNotEmpty)
                .map((t) {
                  // Formato "vN#id" indica opcao ligada a uma versao de arquivo.
                  final match = RegExp(r'^v(\d+)#(\d+)$').firstMatch(t);
                  return match == null
                      ? (label: t, fileVersionId: null)
                      : (
                          label: 'Versao ${match.group(1)}',
                          fileVersionId: int.parse(match.group(2)!),
                        );
                })
                .toList();
            if (_question.text.trim().isEmpty || options.length < 2) {
              showMessage(context, 'Informe a pergunta e ao menos 2 opcoes.');
              return;
            }
            Navigator.pop(
              context,
              _PollDraft(_question.text.trim(), _closesAt, options),
            );
          },
          child: const Text('Abrir enquete'),
        ),
      ],
    );
  }
}
