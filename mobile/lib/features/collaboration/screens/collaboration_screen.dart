import 'package:flutter/material.dart';

import '../stores/collaboration_store.dart';
import '../widgets/collaboration_summary_card.dart';

class CollaborationScreen extends StatelessWidget {
  const CollaborationScreen({super.key});

  static const routeName = '/collaboration';

  @override
  Widget build(BuildContext context) {
    final store = CollaborationStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Colaboracao')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CollaborationSummaryCard(store: store),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proximos modulos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const _ModuleRow(text: 'Candidaturas por projeto'),
                  const _ModuleRow(text: 'Quadro de tarefas/Kanban'),
                  const _ModuleRow(text: 'Agenda de ensaios'),
                  const _ModuleRow(text: 'Registro de decisoes'),
                  const _ModuleRow(text: 'Mensagens da colaboracao'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
