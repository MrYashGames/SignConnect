import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sensebridge/main.dart';
import 'package:sensebridge/models/sensory_profile.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const SenseBridgeApp(),
      ),
    );
    expect(find.byType(SenseBridgeApp), findsOneWidget);
  });
}
