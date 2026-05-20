import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/screens/home_screen.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/example_samples_row.dart';

void main() {
  testWidgets('Home screen shows analyze UI after user types', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    expect(find.text('Example message'), findsOneWidget);
    expect(find.text('Tap to try one'), findsOneWidget);
    expect(find.byType(ExampleSamplesChipStrip), findsOneWidget);
    expect(find.text('Safe · Delivery update'), findsOneWidget);
    expect(find.text('Suspicious · Unusual sign-in'), findsOneWidget);
    expect(find.textContaining('Paste a suspicious SMS'), findsOneWidget);
    expect(find.text('.eml'), findsOneWidget);

    expect(find.text('Analyze'), findsNothing);

    await tester.enterText(find.byType(TextField), 'hello scam');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Analyze'), findsOneWidget);
  });
}
