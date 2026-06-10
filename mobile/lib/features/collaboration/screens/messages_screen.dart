import 'package:flutter/material.dart';

import '../../auth/data/mock_auth_store.dart';
import '../models/artist_profile.dart';
import '../models/collaboration_message.dart';
import '../models/project.dart';
import '../stores/mock_collaboration_store.dart';
import '../widgets/collaboration_ui.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  static const routeName = '/messages';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MockCollaborationStore _store = MockCollaborationStore.instance;
  final TextEditingController _messageController = TextEditingController();

  String? _selectedProjectId;
  CollaborationMessageType _selectedType = CollaborationMessageType.message;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma mensagem antes de enviar.')),
      );
      return;
    }

    final projectId = _selectedProjectId ?? _store.projects.first.id;
    final user = MockAuthStore.currentUser;

    setState(() {
      _store.addMessage(
        CollaborationMessage(
          id: 'message-${DateTime.now().microsecondsSinceEpoch}',
          projectId: projectId,
          senderArtistId: user?.email ?? 'artista-local',
          content: content,
          sentAt: _formatDateTime(DateTime.now()),
          type: _selectedType,
        ),
      );
      _messageController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensagem enviada localmente.')),
    );
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
    final currentUser = MockAuthStore.currentUser;
    if (currentUser?.email == artistId) {
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
