import 'package:flutter/material.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../auth/data/mock_auth_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final user = MockAuthStore.currentUser;
    final initials = (user?.name ?? 'Marina Costa')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1))
        .join();

    return AppScaffold(
      title: 'Perfil',
      currentIndex: 2,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Perfil do artista',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          initials,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Marina Costa',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(user?.email ?? 'marina@harmocrew.app'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Artista independente focada em pop alternativo, com '
                    'interesse em gravacao colaborativa e shows universitarios.',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      Chip(label: Text('12 colaboracoes')),
                      Chip(label: Text('8 projetos concluidos')),
                      Chip(label: Text('Disponivel para ensaios')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Especialidades',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(label: Text('Vocal principal')),
                      Chip(label: Text('Composicao')),
                      Chip(label: Text('Presenca de palco')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Metas da semana',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const _InfoRow(
                    icon: Icons.check_circle_outline,
                    text: 'Revisar repertorio para o show universitario',
                  ),
                  const _InfoRow(
                    icon: Icons.check_circle_outline,
                    text: 'Responder candidaturas abertas no app',
                  ),
                  const _InfoRow(
                    icon: Icons.radio_button_unchecked,
                    text: 'Gravar guia vocal da faixa colaborativa',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
