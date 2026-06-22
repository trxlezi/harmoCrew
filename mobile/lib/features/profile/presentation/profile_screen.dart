import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../../core/native/native_features_store.dart';
import '../../auth/data/auth_store.dart';
import '../../collaboration/screens/weekly_goals_screen.dart';
import '../../collaboration/stores/collaboration_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final store = CollaborationStore.instance;
    /*
     * Primeiro tenta usar artistId da sessao. Se ele nao existir, busca pelo
     * userId na lista de artistas. Assim o perfil mostra metas do artista certo.
     */
    final artistId = user?.artistId ?? _artistIdForUser(store, user?.userId);
    final goals = store.weeklyGoalsForArtist(artistId);
    final initials = (user?.name ?? 'Marina Costa')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1))
        .join();

    return AppScaffold(
      title: 'Perfil',
      currentIndex: 2,
      body: Consumer<NativeFeaturesStore>(
        builder: (context, nativeStore, _) {
          final avatar = _avatar(nativeStore.profileImagePath, initials);

          return ListView(
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
                          avatar,
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
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await nativeStore.pickProfileImageFromGallery();
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Selecionar foto da galeria'),
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
              _NativeResourcesCard(nativeStore: nativeStore),
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
                      if (goals.isEmpty)
                        const Text('Nenhuma meta semanal para este artista.')
                      else
                        ...goals
                            .take(3)
                            .map(
                              (goal) => _InfoRow(
                                icon: goal.status.name == 'done'
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_unchecked,
                                text:
                                    '${goal.title} - ${weeklyGoalStatusLabel(goal.status)}',
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _avatar(String? profileImagePath, String initials) {
  final imageFile = profileImagePath == null ? null : File(profileImagePath);
  final hasImage = imageFile != null && imageFile.existsSync();

  return CircleAvatar(
    radius: 30,
    backgroundColor: AppThemeFallback.primary,
    backgroundImage: hasImage ? FileImage(imageFile) : null,
    child: hasImage
        ? null
        : Text(initials, style: const TextStyle(color: Colors.white)),
  );
}

class _NativeResourcesCard extends StatelessWidget {
  const _NativeResourcesCard({required this.nativeStore});

  final NativeFeaturesStore nativeStore;

  @override
  Widget build(BuildContext context) {
    final status = nativeStore.notificationsEnabled
        ? 'Notificacoes locais ativadas'
        : 'Notificacoes locais desativadas';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recursos nativos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Receber notificacoes do HarmoCrew'),
              subtitle: Text('Preferencia salva localmente com Hive. $status.'),
              value: nativeStore.notificationsEnabled,
              onChanged: nativeStore.setNotificationsEnabled,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: nativeStore.notificationsEnabled
                      ? () async {
                          await nativeStore.showDemoNotification();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notificacao local enviada.'),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Enviar notificacao de teste'),
                ),
                const Chip(label: Text('Provider')),
                const Chip(label: Text('Hive')),
                const Chip(label: Text('Galeria')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppThemeFallback {
  const AppThemeFallback._();

  static const primary = Color(0xFF0A84FF);
}

String? _artistIdForUser(CollaborationStore store, String? userId) {
  // Compatibilidade para sessoes que tem userId, mas nao receberam artistId.
  if (userId == null || userId.isEmpty) {
    return null;
  }

  for (final artist in store.artists) {
    if (artist.userId == userId) {
      return artist.id;
    }
  }

  return null;
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
