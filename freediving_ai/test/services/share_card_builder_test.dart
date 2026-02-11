import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:freediving_ai/models/analysis_output.dart';
import 'package:freediving_ai/models/component_result.dart';
import 'package:freediving_ai/models/swimmer_track.dart';
import 'package:freediving_ai/models/ui/enums.dart';
import 'package:freediving_ai/models/ui/session_summary.dart';
import 'package:freediving_ai/services/share_card_builder.dart';
import 'package:freediving_ai/services/dnf_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for testing with temp directory
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  group('ShareCardBuilder', () {
    late ShareCardBuilder builder;
    late DNFLocalStorage storage;

    setUp(() async {
      builder = ShareCardBuilder();
      storage = DNFLocalStorage();
      await storage.initialize();
      await storage.deleteAllSessionSummaries(); // Clean slate for each test
    });

    tearDown(() async {
      await storage.deleteAllSessionSummaries();
    });

    test('builds card with no previous sessions (improvementLine = null)', () {
      // Create a minimal AnalysisOutput
      final analysis = _createAnalysisOutput();

      final card = builder.build(
        currentAnalysis: analysis,
        sessionId: 'test_session_1',
        storage: storage,
      );

      expect(card.levelValue, 1);
      expect(card.levelState, LevelState.provisional);
      expect(card.coverageCount, 0);
      expect(card.improvementLine, isNull);
      expect(card.nextMissionLine, startsWith('🎯 Next:'));
      expect(card.disclaimer, contains('last 14 days'));
    });

    test('builds card with previous sessions (improvementLine present)', () async {
      // Add a previous session with some confirmed components
      final previousSession = _createSessionSummary(
        sessionId: 'session_1',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        componentEvidence: {
          ComponentType.glide: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 70.0,
          ),
          ComponentType.kick: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 65.0,
          ),
        },
      );

      await storage.saveSessionSummary(previousSession);

      // Add current session with more confirmed components
      final currentSession = _createSessionSummary(
        sessionId: 'session_2',
        timestamp: DateTime.now(),
        componentEvidence: {
          ComponentType.glide: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
          ComponentType.kick: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.arm: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 70.0,
          ),
        },
      );

      await storage.saveSessionSummary(currentSession);

      final analysis = _createAnalysisOutput();

      final card = builder.build(
        currentAnalysis: analysis,
        sessionId: 'session_2',
        storage: storage,
      );

      expect(card.improvementLine, isNotNull);
      expect(card.improvementLine, contains('📈'));
      expect(card.coverageCount, greaterThan(0));
    });

    test('coverage count calculation (0-6)', () async {
      // Test with 0 components
      var card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'test_0',
        storage: storage,
      );
      expect(card.coverageCount, 0);

      // Test with 3 components
      final session3 = _createSessionSummary(
        sessionId: 'session_3',
        timestamp: DateTime.now(),
        componentEvidence: {
          ComponentType.glide: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.kick: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.arm: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
        },
      );
      await storage.saveSessionSummary(session3);

      card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'session_3',
        storage: storage,
      );
      expect(card.coverageCount, 3);

      // Test with all 6 components
      final session6 = _createSessionSummary(
        sessionId: 'session_6',
        timestamp: DateTime.now(),
        componentEvidence: {
          ComponentType.glide: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.kick: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.arm: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.streamline: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.start: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
          ComponentType.turn: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 75.0,
          ),
        },
      );
      await storage.deleteAllSessionSummaries();
      await storage.saveSessionSummary(session6);

      card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'session_6',
        storage: storage,
      );
      expect(card.coverageCount, 6);
    });

    test('PROVISIONAL vs CONFIRMED state', () async {
      // PROVISIONAL: not all 6 components confirmed
      var card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'provisional',
        storage: storage,
      );
      expect(card.levelState, LevelState.provisional);

      // CONFIRMED: all 6 components + glide
      final confirmedSession = _createSessionSummary(
        sessionId: 'confirmed',
        timestamp: DateTime.now(),
        componentEvidence: {
          ComponentType.glide: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
          ComponentType.kick: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
          ComponentType.arm: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
          ComponentType.streamline: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
          ComponentType.start: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
          ComponentType.turn: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
        },
      );
      await storage.deleteAllSessionSummaries();
      await storage.saveSessionSummary(confirmedSession);

      card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'confirmed',
        storage: storage,
      );
      expect(card.levelState, LevelState.confirmed);
      expect(card.coverageCount, 6);
    });

    test('next mission formatting', () {
      final card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'test_mission',
        storage: storage,
      );

      expect(card.nextMissionLine, startsWith('🎯 Next:'));
      expect(card.nextMissionLine, contains('from'));
      expect(card.nextMissionLine, contains('view'));
    });

    test('disclaimer formatting', () {
      final card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'test_disclaimer',
        storage: storage,
      );

      expect(card.disclaimer, startsWith('⚠️'));
      expect(card.disclaimer, contains('last'));
      expect(card.disclaimer, contains('days'));
    });

    test('improvement line shows level increase', () async {
      // Add old session with lower level (score ~50)
      final oldSession = _createSessionSummary(
        sessionId: 'old',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        componentEvidence: {
          ComponentType.glide: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 50.0,
          ),
          ComponentType.kick: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 50.0,
          ),
        },
      );
      await storage.saveSessionSummary(oldSession);

      // Add new session with higher level (score ~80)
      final newSession = _createSessionSummary(
        sessionId: 'new',
        timestamp: DateTime.now(),
        componentEvidence: {
          ComponentType.glide: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
          ComponentType.kick: ComponentEvidence(
            status: 'confirmed',
            confidence: ConfidenceLabel.high,
            score: 80.0,
          ),
        },
      );
      await storage.saveSessionSummary(newSession);

      final card = builder.build(
        currentAnalysis: _createAnalysisOutput(),
        sessionId: 'new',
        storage: storage,
      );

      expect(card.improvementLine, isNotNull);
      expect(card.improvementLine, contains('📈'));
      expect(card.improvementLine, anyOf([
        contains('level'),
        contains('component'),
        contains('Maintained'),
      ]));
    });
  });
}

// Helper functions

AnalysisOutput _createAnalysisOutput() {
  return AnalysisOutput(
    analysisMode: 'LEVEL_TEST',
    modeMessage: 'Test mode',
    classification: ClassificationResult(
      discipline: 'DNF',
      confidence: 0.9,
      reason: 'Test',
    ),
    overallScore: 75.0,
    overallScoreAvailable: true,
    components: {},
    trackingDiagnostics: TrackingDiagnostics(
      totalFrames: 100,
      trackedFrames: 95,
      idSwitchCount: 0,
      trackConfidence: 0.95,
      multiPersonFrameRatio: 0.0,
      coverageRatio: 0.95,
      avgMatchQuality: 0.9,
    ),
    qualityScore: QualityScore(
      overall: 0.9,
      baseScore: 1.0,
      penalties: {},
    ),
  );
}

SessionSummary _createSessionSummary({
  required String sessionId,
  required DateTime timestamp,
  Map<ComponentType, ComponentEvidence> componentEvidence = const {},
}) {
  return SessionSummary(
    sessionId: sessionId,
    timestamp: timestamp,
    mode: 'MISSION',
    viewType: ViewType.side,
    viewConfidence: ConfidenceLabel.high,
    trackingQuality: TrackingQuality.good,
    idSwitches: 0,
    multiPersonLevel: MultiPersonLevel.none,
    componentEvidence: componentEvidence,
    nextMissionSummary: 'Test mission',
  );
}
