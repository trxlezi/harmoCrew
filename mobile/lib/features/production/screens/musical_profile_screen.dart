import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/production_api_service.dart';
import '../widgets/production_common.dart';

/*
 * Perfil musical do usuario logado (Funcionalidade 1): influencias usadas no
 * matching e audio de apresentacao que o contratante ouve na avaliacao.
 */
class MusicalProfileScreen extends StatefulWidget {
  const MusicalProfileScreen({super.key});

  static const routeName = '/musical-profile';

  @override
  State<MusicalProfileScreen> createState() => _MusicalProfileScreenState();
}

class _MusicalProfileScreenState extends State<MusicalProfileScreen> {
  final _api = ProductionApiService();
  final _influences = TextEditingController();
  final _styles = TextEditingController();
  final _instruments = TextEditingController();
  final _city = TextEditingController();
  Map<String, dynamic>? _artist;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _influences.dispose();
    _styles.dispose();
    _instruments.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = currentArtistId;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final artist = await _api.artist(id);
      if (!mounted) return;
      setState(() {
        _artist = artist;
        _influences.text = artist.strings('influences').join(', ');
        _styles.text = artist.strings('musicalStyles').join(', ');
        _instruments.text = artist.strings('instruments').join(', ');
        _city.text = artist.s('city');
      });
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _split(String text) =>
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _save() async {
    final artist = _artist;
    final id = currentArtistId;
    if (artist == null || id == null) return;
    setState(() => _busy = true);
    try {
      final updated = await _api.updateArtist(id, {
        'stageName': artist.s('stageName'),
        'bio': artist['bio'],
        'mainSpecialty': artist.s('mainSpecialty', 'Musico'),
        'availability': artist.s('availability', 'A combinar'),
        'instruments': _split(_instruments.text),
        'musicalStyles': _split(_styles.text),
        'influences': _split(_influences.text),
        'city': _city.text.trim(),
      });
      if (!mounted) return;
      setState(() => _artist = updated);
      showMessage(context, 'Perfil musical atualizado.');
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadAudio() async {
    final id = currentArtistId;
    if (id == null) return;
    final file = await pickFile(type: FileType.audio);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final updated = await _api.uploadArtistAudio(id, file.bytes, file.name);
      if (!mounted) return;
      setState(() => _artist = updated);
      showMessage(context, 'Audio enviado.');
    } catch (error) {
      if (mounted) showMessage(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artist = _artist;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil musical')),
      body: currentArtistId == null
          ? const Center(child: Text('Faca login com um perfil de artista.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_busy) const LinearProgressIndicator(),
                Text(
                  artist?.s('stageName') ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Estes dados alimentam o ranking de compatibilidade com as vagas.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _styles,
                  decoration: const InputDecoration(
                    labelText: 'Estilos (separados por virgula)',
                  ),
                ),
                TextField(
                  controller: _instruments,
                  decoration: const InputDecoration(
                    labelText: 'Instrumentos (separados por virgula)',
                  ),
                ),
                TextField(
                  controller: _influences,
                  decoration: const InputDecoration(
                    labelText: 'Influencias (ex.: Tim Maia, Jorge Ben)',
                  ),
                ),
                TextField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar perfil'),
                ),
                const Divider(height: 40),
                Text(
                  'Audio de apresentacao',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (artist != null && artist.s('audioUrl').isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.audiotrack),
                    title: Text(artist.s('audioFilename', 'Audio do perfil')),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      onPressed: () => openExternalUrl(
                        context,
                        _api.mediaUrl(artist.s('audioUrl')),
                      ),
                    ),
                  )
                else
                  const Text('Nenhum audio enviado ainda.'),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _uploadAudio,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Enviar audio'),
                ),
              ],
            ),
    );
  }
}
