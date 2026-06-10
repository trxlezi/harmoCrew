import 'package:flutter/material.dart';

import '../stores/mock_collaboration_store.dart';

class CollaborationSummaryCard extends StatelessWidget {
  const CollaborationSummaryCard({super.key, required this.store});

  final MockCollaborationStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colaboracao mockada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Estrutura local preparada para candidaturas, tarefas, ensaios, '
              'decisoes, mensagens e metas semanais.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryChip(
                  label: 'Candidaturas',
                  value: store.openApplicationCount.toString(),
                ),
                _SummaryChip(
                  label: 'Tarefas abertas',
                  value: store.pendingTaskCount.toString(),
                ),
                _SummaryChip(
                  label: 'Ensaios',
                  value: store.rehearsals.length.toString(),
                ),
                _SummaryChip(
                  label: 'Decisoes',
                  value: store.decisions.length.toString(),
                ),
                _SummaryChip(
                  label: 'Mensagens',
                  value: store.messages.length.toString(),
                ),
                _SummaryChip(
                  label: 'Metas abertas',
                  value: store.openGoalCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(value, style: const TextStyle(color: Colors.white)),
      ),
      label: Text(label),
    );
  }
}
