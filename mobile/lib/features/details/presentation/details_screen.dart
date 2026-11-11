import 'package:flutter/material.dart';

class DetailsArguments {
  const DetailsArguments({required this.title, required this.description});

  /*
   * Objeto usado para demonstrar passagem de dados por rota.
   * A tela que navega para DetailsScreen envia titulo/descricao em arguments.
   */
  final String title;
  final String description;
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  /*
   * Tela generica de detalhes.
   * Ela e pequena, mas mostra um conceito importante em Flutter: rotas nomeadas
   * podem receber argumentos tipados para reaproveitar uma mesma tela.
   */
  static const routeName = '/details';

  @override
  Widget build(BuildContext context) {
    // Recupera os argumentos enviados por Navigator.pushNamed.
    final args = ModalRoute.of(context)!.settings.arguments as DetailsArguments;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    args.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    args.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que esta tela demonstra',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const _DetailBullet(text: 'Navegacao com rotas nomeadas'),
                    const _DetailBullet(
                      text: 'Passagem de argumentos entre telas',
                    ),
                    const _DetailBullet(
                      text: 'Uso consistente de widgets Material',
                    ),
                    const _DetailBullet(
                      text: 'Conteudo conectado ao fluxo principal',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBullet extends StatelessWidget {
  const _DetailBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
