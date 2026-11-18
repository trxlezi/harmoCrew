import 'package:flutter/material.dart';

import '../../auth/data/auth_store.dart';
import '../models/artist_profile.dart';
import '../models/collaboration_message.dart';
import '../models/project.dart';
import '../stores/collaboration_store.dart';
import '../widgets/collaboration_ui.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  static const routeName = '/messages';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  /*
   * A tela usa a store singleton para acessar projetos, artistas e mensagens.
   * O TextEditingController guarda o texto digitado ate o usuario enviar.
   */
  final CollaborationStore _store = CollaborationStore.instance;
  final TextEditingController _messageController = TextEditingController();

  String? _selectedProjectId;
  CollaborationMessageType _selectedType = CollaborationMessageType.message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    /*
     * Fluxo de envio:
     * 1. valida texto;
     * 2. garante que existe projeto;
     * 3. descobre o artistId do usuario logado;
     * 4. chama a API pelo CollaborationStore.
     */
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma mensagem antes de enviar.')),
      );
      return;
    }

    if (_store.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um projeto antes de enviar.')),
      );
      return;
    }

    final projectId = _selectedProjectId ?? _store.projects.first.id;
    final senderArtistId = _currentArtistId();
    if (senderArtistId == null) {
      /*
       * Este bloqueio evita o bug de autoria errada.
       * Antes, quando artistId nao existia, o app podia usar o primeiro artista
       * da lista. Agora ele para e avisa o usuario.
       */
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel identificar o artista logado.'),
        ),
      );
      return;
    }

    try {
      await _store.createMessageFromApi(
        CollaborationMessage(
          id: '',
          projectId: projectId,
          senderArtistId: senderArtistId,
          content: content,
          sentAt: _formatDateTime(DateTime.now()),
          type: _selectedType,
        ),
      );
      if (mounted) {
        setState(() => _messageController.clear());
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mensagem enviada.')));
  }

  Future<void> _loadData() async {
    // Ao abrir a tela, buscamos dados reais da API para listar mensagens atuais.
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
    final messages = _store.messagesForProject(_selectedProjectId);

    return Scaffold(
      appBar: AppBar(title: const Text('Comunicacao')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                ProjectSelector(
                  value: _selectedProjectId,
                  projects: _store.projects,
                  onChanged: (projectId) {
                    setState(() => _selectedProjectId = projectId);
                  },
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<CollaborationMessageType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: CollaborationMessageType.values
                      .map(
                        (type) => DropdownMenuItem<CollaborationMessageType>(
                          value: type,
                          child: Text(messageTypeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type != null) {
                      setState(() => _selectedType = type);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? const _MessagesEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageCard(
                        message: message,
                        projectName: _projectName(message.projectId),
                        authorName: _artistName(message.senderArtistId),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: messages.length,
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Nova mensagem',
                        hintText: 'Escreva uma atualizacao para a colaboracao',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    tooltip: 'Enviar',
                  ),
                ],
              ),
            ),
          ),
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

  String _artistName(String artistId) {
    /*
     * Na exibicao, se a mensagem pertence ao usuario logado, mostramos o nome da
     * sessao atual. Caso contrario, buscamos o nome na lista de artistas.
     */
    final currentUser = AuthStore.currentUser;
    if (currentUser?.artistId == artistId || _currentArtistId() == artistId) {
      return currentUser!.name;
    }

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

  String? _currentArtistId() {
    /*
     * Resolve o artista do usuario autenticado.
     *
     * Caminho principal: AuthResponse ja vem com artistId.
     * Caminho de compatibilidade: se houver userId mas nao artistId, procuramos
     * o Artist cujo userId seja igual ao userId da sessao.
     */
    final user = AuthStore.currentUser;
    if (user == null) {
      return null;
    }

    if (user.artistId != null && user.artistId!.isNotEmpty) {
      return user.artistId;
    }

    if (user.userId == null || user.userId!.isEmpty) {
      return null;
    }

    for (final artist in _store.artists) {
      if (artist.userId == user.userId) {
        return artist.id;
      }
    }

    return null;
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.projectName,
    required this.authorName,
  });

  final CollaborationMessage message;
  final String projectName;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    authorName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(messageTypeLabel(message.type))),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.content),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(projectName)),
                Chip(label: Text(message.sentAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesEmptyState extends StatelessWidget {
  const _MessagesEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        EmptyState(
          icon: Icons.chat_bubble_outline,
          message: 'Nenhuma mensagem para este projeto.',
        ),
      ],
    );
  }
}

String messageTypeLabel(CollaborationMessageType type) {
  return switch (type) {
    CollaborationMessageType.message => 'Mensagem',
    CollaborationMessageType.notice => 'Aviso',
    CollaborationMessageType.decision => 'Decisao',
    CollaborationMessageType.pending => 'Pendencia',
  };
}

String _formatDateTime(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day $hour:$minute';
}
