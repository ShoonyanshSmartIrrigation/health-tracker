import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/shared/widgets/glass_card.dart';
import 'package:health_tracker/shared/widgets/progress_ring.dart';

void main() {
  group('UI Components Widget Tests', () {
    testWidgets('GlassCard Renders Child Content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('ProgressRing Renders Custom Paint', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressRing(
              progress: 0.75,
              size: 100,
              child: Text('75%'),
            ),
          ),
        ),
      );

      // Verify the widget exists
      expect(find.byType(ProgressRing), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      
      // Verify CustomPaint is drawn (there is one for track and one for active arc)
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // Settle animations to avoid pending timers error
      await tester.pumpAndSettle();
    });
  });
}
