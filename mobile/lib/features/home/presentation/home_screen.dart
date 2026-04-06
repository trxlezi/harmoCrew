import 'package:flutter/material.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../details/presentation/details_screen.dart';
import '../../members/data/mock_members.dart';
import '../../members/domain/member.dart';
import '../../members/presentation/member_form_screen.dart';
import '../../projects/data/mock_projects.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Member> _members;

  @override
  void initState() {
    super.initState();
    _members = List<Member>.from(MockMembers.seed());
  }

  Future<void> _openMemberForm() async {
    final result = await Navigator.pushNamed(
      context,
      MemberFormScreen.routeName,
    );

    if (!mounted || result is! Member) {
      return;
    }

    setState(() {
      _members.add(result);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.name} adicionado com sucesso.')),
    );
  }

  void _openDetails() {
    Navigator.pushNamed(
      context,
      DetailsScreen.routeName,
      arguments: const DetailsArguments(
        title: 'Equipe harmoCrew',
        description:
            'Dados mockados enviados da tela inicial para comprovar '
            'navegacao e passagem de parametros entre paginas.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = MockProjects.all();

    return AppScaffold(
      title: 'harmoCrew',
      currentIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMemberForm,
        icon: const Icon(Icons.person_add),
        label: const Text('Cadastrar'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          return ListView(
            padding: EdgeInsets.all(isWide ? 28 : 20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      const Color(0xFF2E7DA1),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Painel da banda',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Organize integrantes, acompanhe oportunidades e '
                      'mantenha o perfil pronto para colaboracoes.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _HeroMetric(
                          label: 'Integrantes',
                          value: _members.length.toString(),
                        ),
                        _HeroMetric(
                          label: 'Projetos ativos',
                          value: projects.length.toString(),
                        ),
                        const _HeroMetric(
                          label: 'Ensaios na semana',
                          value: '1',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visao geral',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Esta versao mobile prioriza os criterios academicos '
                        'e simula os principais fluxos da plataforma com '
                        'dados locais.',
                      ),
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openDetails,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Abrir detalhes'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openMemberForm,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Novo integrante'),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _openDetails,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Abrir detalhes'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _openMemberForm,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Novo integrante'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proximas acoes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      const _ActionRow(
                        icon: Icons.event_available,
                        title: 'Ensaiar repertorio principal',
                        subtitle: 'Quarta-feira, 19h30',
                      ),
                      const _ActionRow(
                        icon: Icons.campaign_outlined,
                        title: 'Responder candidatos pendentes',
                        subtitle: '2 projetos aguardando retorno',
                      ),
                      const _ActionRow(
                        icon: Icons.mic_external_on_outlined,
                        title: 'Atualizar perfil artistico',
                        subtitle: 'Adicionar links e descricao final',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Integrantes mockados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ..._members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(member.name.substring(0, 1)),
                      ),
                      title: Text('${member.name} - ${member.role}'),
                      subtitle: Text(member.availability),
                      trailing: const Icon(Icons.chevron_right),
                    ),
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
