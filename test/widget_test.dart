import 'package:flutter_test/flutter_test.dart';
import 'package:animate/main.dart';
import 'package:animate/state/project_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Anim-X smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ProjectProvider(),
        child: const AnimXApp(),
      ),
    );

    // Verify that the title is present.
    expect(find.text('Anim-X Studio'), findsOneWidget);
  });
}
