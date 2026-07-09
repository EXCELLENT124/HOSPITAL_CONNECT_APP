import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_connect_app/app.dart';

void main() {
  test('local lawyer scores prefer same-city available specialists', () {
    final store = AppStore();
    const local = LawyerInfo('Local', 'Johannesburg', 10, true, .90);
    const remote = LawyerInfo('Remote', 'Cape Town', 10, true, .90);
    expect(store.match(local, 'Johannesburg'),
        greaterThan(store.match(remote, 'Johannesburg')));
  });

  testWidgets('shows secure automatic sign in', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(AppStore())));
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Hospital'), findsNothing);
    expect(find.text('Lawyer'), findsNothing);
    expect(find.text('Patient'), findsNothing);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
