import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/data/auth_store.dart';
import '../../collaboration/models/project.dart';
import '../../collaboration/stores/collaboration_store.dart';

/// Helpers de leitura segura de JSON.
extension JsonRead on Map<String, dynamic> {
  String s(String key, [String fallback = '']) =>
      this[key] == null ? fallback : this[key].toString();

  int i(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? fallback;
  }

  int? n(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool b(String key) => this[key] == true;

  Map<String, dynamic> m(String key) => this[key] is Map<String, dynamic>
      ? this[key] as Map<String, dynamic>
      : {};

  List<Map<String, dynamic>> l(String key) => this[key] is List
      ? (this[key] as List).whereType<Map<String, dynamic>>().toList()
      : const [];

  List<String> strings(String key) => this[key] is List
      ? (this[key] as List).map((e) => e.toString()).toList()
      : const [];
}

String? get currentArtistId => AuthStore.currentUser?.artistId;

/// "2026-11-11T10:20:00" -> "11/11/2026 10:20"
String formatDateTime(String iso, {bool withTime = true}) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  String two(int v) => v.toString().padLeft(2, '0');
  final day = '${two(date.day)}/${two(date.month)}/${date.year}';
  return withTime ? '$day ${two(date.hour)}:${two(date.minute)}' : day;
}

String stageLabel(String stage) => switch (stage) {
  'COMPOSITION' => 'Composicao',
  'ARRANGEMENT' => 'Arranjo',
  'RECORDING' => 'Gravacao',
  'MIXING' => 'Mixagem',
  'RELEASE' => 'Lancamento',
  _ => 'Sem etapa',
};

const productionStages = [
  'COMPOSITION',
  'ARRANGEMENT',
  'RECORDING',
  'MIXING',
  'RELEASE',
];

String taskStatusLabel(String status) => switch (status) {
  'TODO' => 'A fazer',
  'IN_PROGRESS' => 'Em andamento',
  'DONE' => 'Concluida',
  _ => status,
};

String applicationStatusLabel(String status) => switch (status) {
  'PENDING' => 'Recebida',
  'UNDER_REVIEW' => 'Em avaliacao',
  'SHORTLISTED' => 'Pre-selecionada',
  'APPROVED' => 'Aprovada',
  'REJECTED' => 'Nao selecionada',
  _ => status,
};

String fileCategoryLabel(String category) => switch (category) {
  'AUDIO_GUIDE' => 'Guia de audio',
  'ARRANGEMENT' => 'Arranjo',
  'SHEET_PDF' => 'Partitura (PDF)',
  'LYRICS' => 'Letra',
  'SETLIST' => 'Setlist',
  _ => 'Outro',
};

Future<void> openExternalUrl(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    showMessage(context, 'Nao foi possivel abrir $url');
  }
}

void showMessage(BuildContext context, Object message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message.toString().replaceFirst('ApiException: ', '')),
      ),
    );
}

/// Abre o seletor de arquivos nativo e devolve bytes + nome.
Future<({List<int> bytes, String name})?> pickFile({
  FileType type = FileType.any,
}) async {
  final files = await FilePicker.pickFiles(type: type);
  if (files.isEmpty) {
    return null;
  }
  final file = files.first;
  return (bytes: (await file.readAsBytes()).toList(), name: file.name);
}

/// Seletor de projeto reaproveitado nas telas do modulo de producao.
class ProjectPickerBar extends StatefulWidget {
  const ProjectPickerBar({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  State<ProjectPickerBar> createState() => _ProjectPickerBarState();
}

class _ProjectPickerBarState extends State<ProjectPickerBar> {
  final _store = CollaborationStore.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_store.projects.isEmpty) {
      _load();
    } else if (widget.selectedId == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onChanged(_store.projects.first.id),
      );
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _store.syncCoreFromApi();
      if (widget.selectedId == null && _store.projects.isNotEmpty) {
        widget.onChanged(_store.projects.first.id);
      }
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Project> projects = _store.projects;
    if (_loading) {
      return const LinearProgressIndicator();
    }
    if (projects.isEmpty) {
      return const Text('Nenhum projeto cadastrado.');
    }
    return DropdownButtonFormField<String>(
      initialValue: projects.any((p) => p.id == widget.selectedId)
          ? widget.selectedId
          : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Projeto / vaga'),
      items: projects
          .map(
            (p) => DropdownMenuItem(
              value: p.id,
              child: Text(p.title, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: widget.onChanged,
    );
  }
}

/// Barra horizontal simples (0-100) usada em graficos e notas.
class PercentBar extends StatelessWidget {
  const PercentBar({
    super.key,
    required this.label,
    required this.percent,
    this.trailing,
    this.color,
  });

  final String label;
  final int? percent;
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final value = (percent ?? 0).clamp(0, 100);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(trailing ?? (percent == null ? '-' : '$value%')),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 10,
              color: color ?? scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
