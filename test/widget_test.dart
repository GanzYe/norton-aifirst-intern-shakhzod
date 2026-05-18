import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows analyze UI', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    expect(find.text('Analyze'), findsOneWidget);
    expect(find.text('Try an example'), findsOneWidget);
    expect(find.textContaining('Paste a suspicious SMS'), findsOneWidget);
  });
}
