import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

Future<void> _loginDefaultUser(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'marina@harmocrew.app',
  );
  await tester.enterText(find.byType(TextFormField).at(1), '123456');
  await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre no login e entra no app com usuario mockado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarmoCrewApp());

    expect(find.text('Entrar na sua crew'), findsOneWidget);

    await _loginDefaultUser(tester);

    expect(find.text('Painel da banda'), findsOneWidget);
  });

  testWidgets('permite cadastrar nova conta mockada', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarmoCrewApp());

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Criar novo cadastro'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Carlos Silva');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'carlos@harmocrew.app',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '654321');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar na sua crew'), findsOneWidget);
    expect(find.text('Conta criada com sucesso.'), findsOneWidget);
  });

  testWidgets('navega da tela inicial para a tela de detalhes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarmoCrewApp());
    await _loginDefaultUser(tester);

    expect(find.text('Painel da banda'), findsOneWidget);

    final detailsButton = find.widgetWithText(ElevatedButton, 'Abrir detalhes');
    await tester.ensureVisible(detailsButton);
    tester.widget<ElevatedButton>(detailsButton).onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Equipe harmoCrew'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
  });

  testWidgets('adiciona integrante pelo formulario', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarmoCrewApp());
    await _loginDefaultUser(tester);

    await tester.scrollUntilVisible(find.text('Ana - Vocal'), 300);
    expect(find.text('Ana - Vocal'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar integrante'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Carlos');
    await tester.enterText(find.byType(TextFormField).at(1), 'Baixo');
    await tester.enterText(find.byType(TextFormField).at(2), 'Noites de sexta');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar integrante'));
    await tester.pumpAndSettle();

    expect(find.text('Carlos - Baixo'), findsOneWidget);
    expect(find.text('Noites de sexta'), findsOneWidget);
  });

  testWidgets('navega entre abas principais do aplicativo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarmoCrewApp());
    await _loginDefaultUser(tester);

    expect(find.text('Painel da banda'), findsOneWidget);

    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();

    expect(find.text('Projetos em destaque'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil do artista'), findsOneWidget);
  });

  testWidgets('abre detalhes rapidos de um projeto', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HarmoCrewApp());
    await _loginDefaultUser(tester);

    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver detalhes').first);
    await tester.pumpAndSettle();

    expect(find.text('Sessao Neo Soul'), findsWidgets);
    expect(find.text('Resumo do projeto'), findsOneWidget);
    expect(find.text('Fechar'), findsOneWidget);
  });
}
