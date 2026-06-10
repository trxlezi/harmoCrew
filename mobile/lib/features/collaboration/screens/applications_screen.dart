import 'package:flutter/material.dart';

import '../models/application.dart';
import '../stores/mock_collaboration_store.dart';
import '../widgets/collaboration_ui.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  static const routeName = '/applications';

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final MockCollaborationStore _store = MockCollaborationStore.instance;

  void _updateStatus(String id, ApplicationStatus status) {
    setState(() {
      _store.updateApplicationStatus(id, status);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Candidatura marcada como ${_statusLabel(status)}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final applications = _store.applications;

    return Scaffold(
      appBar: AppBar(title: const Text('Candidaturas')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Candidaturas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Fluxo local de artistas interessados nos projetos.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          if (applications.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'Nenhuma candidatura registrada.',
            )
          else
            ...applications.map(
              (application) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ApplicationCard(
                  application: application,
                  onPending: () =>
                      _updateStatus(application.id, ApplicationStatus.pending),
                  onApprove: () =>
                      _updateStatus(application.id, ApplicationStatus.approved),
                  onReject: () =>
                      _updateStatus(application.id, ApplicationStatus.rejected),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onPending,
    required this.onApprove,
    required this.onReject,
  });

  final Application application;
  final VoidCallback onPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.projectId,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(_statusLabel(application.status))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Artista: ${application.artistId}'),
            const SizedBox(height: 6),
            Text('Especialidade: ${application.specialty}'),
            const SizedBox(height: 6),
            Text('Disponibilidade: ${application.availability}'),
            const SizedBox(height: 6),
            Text('Data: ${application.createdAt}'),
            const SizedBox(height: 12),
            Text(application.message),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onPending,
                  child: const Text('Pendente'),
                ),
                ElevatedButton(
                  onPressed: onApprove,
                  child: const Text('Aceitar'),
                ),
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Recusar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.pending => 'Pendente',
    ApplicationStatus.approved => 'Aceita',
    ApplicationStatus.rejected => 'Recusada',
  };
}
