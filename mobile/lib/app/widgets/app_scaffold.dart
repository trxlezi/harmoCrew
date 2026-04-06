import 'package:flutter/material.dart';

import '../../features/auth/data/mock_auth_store.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/details/presentation/details_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/members/presentation/member_form_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final int currentIndex;
  final Widget body;
  final Widget? floatingActionButton;

  void _goToTab(BuildContext context, int index, {bool closeDrawer = false}) {
    final routes = [
      HomeScreen.routeName,
      ProjectsScreen.routeName,
      ProfileScreen.routeName,
    ];

    if (ModalRoute.of(context)?.settings.name == routes[index]) {
      if (closeDrawer) {
        Navigator.pop(context);
      }
      return;
    }

    Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: Drawer(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.music_note),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'harmoCrew Mobile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Prototipo academico com dados locais',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Painel'),
                onTap: () => _goToTab(context, 0, closeDrawer: true),
              ),
              ListTile(
                leading: const Icon(Icons.workspaces_outline),
                title: const Text('Projetos'),
                onTap: () => _goToTab(context, 1, closeDrawer: true),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Perfil'),
                onTap: () => _goToTab(context, 2, closeDrawer: true),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sobre a equipe'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    DetailsScreen.routeName,
                    arguments: const DetailsArguments(
                      title: 'Equipe harmoCrew',
                      description:
                          'Fluxo demonstrativo com navegacao, dados mockados '
                          'e telas reais para defesa academica.',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Cadastrar integrante'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, MemberFormScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  MockAuthStore.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    LoginScreen.routeName,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _goToTab(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined),
            activeIcon: Icon(Icons.folder_open),
            label: 'Projetos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
