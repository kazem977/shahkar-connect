import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shahkar_connect/features/connect/presentation/connect_orb.dart';

void main() {
  testWidgets('connect orb is tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectOrb(
            connected: false,
            connecting: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.byType(ConnectOrb), findsOneWidget);
    await tester.tap(find.byType(ConnectOrb));
    expect(taps, 1);
  });
}
