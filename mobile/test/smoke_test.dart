import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  testWidgets('initializes the app on the login screen', (tester) async {
    await tester.pumpWidget(const HarmoCrewApp());
    await tester.pump();

    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
  });
}
