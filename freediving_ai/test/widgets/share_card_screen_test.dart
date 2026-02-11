import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freediving_ai/features/analysis/screens/share_card_screen.dart';
import 'package:freediving_ai/models/ui/share_card_model.dart';
import 'package:freediving_ai/models/ui/enums.dart';

void main() {
  group('ShareCardScreen', () {
    testWidgets('renders all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: ShareCardScreen(
              cardData: ShareCardModel(
                levelState: LevelState.provisional,
                levelValue: 5,
                coverageCount: 3,
                improvementLine: '📈 +1 level from last session',
                nextMissionLine: '🎯 Next: Streamline from Side view',
                disclaimer: '⚠️ Based on last 14 days',
              ),
              sessionId: 'test_session',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Share Your Progress'), findsOneWidget);

      // Verify card header
      expect(find.text('DNF COACH'), findsOneWidget);

      // Verify level value
      expect(find.textContaining('Level 5'), findsOneWidget);

      // Verify coverage
      expect(find.textContaining('3/6'), findsOneWidget);

      // Verify improvement line
      expect(find.textContaining('📈 +1 level'), findsOneWidget);

      // Verify next mission
      expect(find.textContaining('🎯 Next:'), findsOneWidget);
      expect(find.textContaining('Streamline'), findsOneWidget);

      // Verify disclaimer
      expect(find.textContaining('⚠️'), findsOneWidget);
      expect(find.textContaining('14 days'), findsOneWidget);

      // Verify buttons
      expect(find.text('Share as Image'), findsOneWidget);
      expect(find.text('Back to Report'), findsOneWidget);
    });

    testWidgets('PROVISIONAL styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: ShareCardScreen(
              cardData: ShareCardModel(
                levelState: LevelState.provisional,
                levelValue: 3,
                coverageCount: 2,
                nextMissionLine: '🎯 Next: Kick from Back view',
                disclaimer: '⚠️ Based on last 14 days',
              ),
              sessionId: 'provisional_test',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PROVISIONAL badge
      expect(find.text('PROVISIONAL'), findsOneWidget);
      expect(find.text('📊'), findsOneWidget);
    });

    testWidgets('CONFIRMED styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: ShareCardScreen(
              cardData: ShareCardModel(
                levelState: LevelState.confirmed,
                levelValue: 8,
                coverageCount: 6,
                improvementLine: '📈 Maintained Level 8',
                nextMissionLine: '🎯 Next: Turn from Side view',
                disclaimer: '⚠️ Based on last 14 days',
              ),
              sessionId: 'confirmed_test',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify CONFIRMED badge
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('✅'), findsOneWidget);

      // Verify full coverage
      expect(find.textContaining('6/6'), findsOneWidget);
    });

    testWidgets('conditional improvement line display', (WidgetTester tester) async {
      // Test with improvementLine = null
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: ShareCardScreen(
              cardData: ShareCardModel(
                levelState: LevelState.provisional,
                levelValue: 1,
                coverageCount: 0,
                improvementLine: null, // No previous sessions
                nextMissionLine: '🎯 Next: Glide from Side view',
                disclaimer: '⚠️ Based on last 14 days',
              ),
              sessionId: 'no_history',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify improvement line is NOT shown
      expect(find.textContaining('📈'), findsNothing);
      expect(find.textContaining('from last session'), findsNothing);
    });

    testWidgets('button interactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: ShareCardScreen(
              cardData: ShareCardModel(
                levelState: LevelState.provisional,
                levelValue: 4,
                coverageCount: 2,
                nextMissionLine: '🎯 Next: Arm from Front view',
                disclaimer: '⚠️ Based on last 14 days',
              ),
              sessionId: 'button_test',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both buttons are present and tappable
      final shareButton = find.text('Share as Image');
      final backButton = find.text('Back to Report');

      expect(shareButton, findsOneWidget);
      expect(backButton, findsOneWidget);

      // Test back button (should pop the route)
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // After pop, screen should be gone
      expect(find.text('Share Your Progress'), findsNothing);
    });

    testWidgets('displays different level values correctly', (WidgetTester tester) async {
      for (final level in [1, 5, 10]) {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => MaterialApp(
              home: ShareCardScreen(
                cardData: ShareCardModel(
                  levelState: LevelState.provisional,
                  levelValue: level,
                  coverageCount: 2,
                  nextMissionLine: '🎯 Next: Test',
                  disclaimer: '⚠️ Test',
                ),
                sessionId: 'level_$level',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('Level $level'), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('displays different coverage counts correctly', (WidgetTester tester) async {
      for (final coverage in [0, 3, 6]) {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => MaterialApp(
              home: ShareCardScreen(
                cardData: ShareCardModel(
                  levelState: coverage == 6 ? LevelState.confirmed : LevelState.provisional,
                  levelValue: 5,
                  coverageCount: coverage,
                  nextMissionLine: '🎯 Next: Test',
                  disclaimer: '⚠️ Test',
                ),
                sessionId: 'coverage_$coverage',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('$coverage/6'), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });
}
