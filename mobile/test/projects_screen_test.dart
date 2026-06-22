import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/projects/presentation/projects_screen.dart';

void main() {
  testWidgets('opens the new project form from the projects screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProjectsScreen(loadOnStart: false)),
    );
    await tester.pump();

    expect(find.text('Novo projeto'), findsOneWidget);

    await tester.tap(find.text('Novo projeto'));
    await tester.pumpAndSettle();

    expect(find.text('Criar projeto'), findsOneWidget);
    expect(find.text('Titulo'), findsOneWidget);
    expect(find.text('Estilo musical'), findsOneWidget);
    expect(find.text('Salvar projeto'), findsOneWidget);
  });
}
