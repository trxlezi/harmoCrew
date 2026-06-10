import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/project_task.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(20),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(label),
      side: BorderSide(color: chipColor),
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final ProjectTaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      ProjectTaskPriority.low => Colors.green,
      ProjectTaskPriority.medium => Colors.amber,
      ProjectTaskPriority.high => Theme.of(context).colorScheme.error,
    };

    return AppStatusChip(
      label: 'Prioridade: ${priorityLabel(priority)}',
      color: color,
    );
  }
}

class ProjectSelector extends StatelessWidget {
  const ProjectSelector({
    super.key,
    required this.value,
    required this.projects,
    required this.onChanged,
    this.label = 'Filtrar por projeto',
    this.includeAll = true,
  });

  final String? value;
  final List<Project> projects;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool includeAll;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (includeAll)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Todos os projetos'),
          ),
        ...projects.map(
          (project) => DropdownMenuItem<String?>(
            value: project.id,
            child: Text(project.title, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

String priorityLabel(ProjectTaskPriority priority) {
  return switch (priority) {
    ProjectTaskPriority.low => 'Baixa',
    ProjectTaskPriority.medium => 'Media',
    ProjectTaskPriority.high => 'Alta',
  };
}
