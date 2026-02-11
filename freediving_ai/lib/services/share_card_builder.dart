import '../models/analysis_output.dart';
import '../models/ui/share_card_model.dart';
import '../models/ui/session_summary.dart';
import '../models/ui/enums.dart';
import '../models/ui/passport_model.dart'; // For MissionSuggestion
import 'confirmed_level_service.dart';
import 'dnf_local_storage.dart';

/// Builds ShareCardModel from analysis output and session history.
///
/// Responsible for:
/// - Computing confirmed level from session history
/// - Generating improvement line (null if no previous sessions)
/// - Formatting next mission line
/// - Formatting disclaimer
class ShareCardBuilder {
  final ConfirmedLevelService _levelService = ConfirmedLevelService();

  /// Build share card data from current analysis and session history.
  ///
  /// Returns [ShareCardModel] with:
  /// - levelState: PROVISIONAL or CONFIRMED based on 14-day evidence
  /// - levelValue: 1-10
  /// - coverageCount: 0-6
  /// - improvementLine: null if no previous sessions, otherwise comparison text
  /// - nextMissionLine: formatted mission suggestion
  /// - disclaimer: evidence window notice
  ShareCardModel build({
    required AnalysisOutput currentAnalysis,
    required String sessionId,
    required DNFLocalStorage storage,
  }) {
    final now = DateTime.now();

    // Get all sessions from storage
    final allSessions = storage.getAllSessionSummaries();

    // Compute confirmed level result
    final levelResult = _levelService.computeConfirmedLevel(
      sessionSummaries: allSessions,
      currentTimestamp: now,
    );

    // Generate improvement line (compare current vs previous)
    final improvementLine = _buildImprovementLine(
      currentLevel: levelResult.levelValue,
      currentCoverage: levelResult.coverageCount,
      sessions: allSessions,
      currentTimestamp: now,
    );

    // Format next mission line
    final nextMissionLine = _formatNextMission(levelResult.nextSuggestedMission);

    // Format disclaimer
    final disclaimer = '⚠️ ${levelResult.validityNote}';

    return ShareCardModel(
      levelState: levelResult.levelState,
      levelValue: levelResult.levelValue,
      coverageCount: levelResult.coverageCount,
      improvementLine: improvementLine,
      nextMissionLine: nextMissionLine,
      disclaimer: disclaimer,
    );
  }

  /// Build improvement line by comparing current session to previous sessions.
  ///
  /// Returns null if no previous sessions exist.
  /// Otherwise returns formatted comparison like:
  /// - "📈 +2 levels from last session"
  /// - "📈 +1 component confirmed"
  /// - "📈 Maintained Level 8"
  String? _buildImprovementLine({
    required int currentLevel,
    required int currentCoverage,
    required List<SessionSummary> sessions,
    required DateTime currentTimestamp,
  }) {
    if (sessions.isEmpty) return null;

    // Sort sessions by timestamp descending (newest first)
    final sortedSessions = List<SessionSummary>.from(sessions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Find most recent previous session
    SessionSummary? previousSession;
    for (final session in sortedSessions) {
      if (session.timestamp.isBefore(currentTimestamp)) {
        previousSession = session;
        break;
      }
    }

    if (previousSession == null) return null;

    // Calculate previous level from all sessions up to that point
    final previousTimestamp = previousSession.timestamp;
    final sessionsUpToPrevious = sortedSessions
        .where((s) => s.timestamp.isBefore(currentTimestamp))
        .toList();

    final previousLevelResult = _levelService.computeConfirmedLevel(
      sessionSummaries: sessionsUpToPrevious,
      currentTimestamp: previousTimestamp,
    );

    final levelDiff = currentLevel - previousLevelResult.levelValue;
    final coverageDiff = currentCoverage - previousLevelResult.coverageCount;

    // Generate improvement message
    if (levelDiff > 0) {
      return '📈 +$levelDiff level${levelDiff > 1 ? 's' : ''} from last session';
    } else if (levelDiff < 0) {
      return '📊 ${levelDiff.abs()} level${levelDiff.abs() > 1 ? 's' : ''} below previous';
    } else if (coverageDiff > 0) {
      return '📈 +$coverageDiff component${coverageDiff > 1 ? 's' : ''} confirmed';
    } else if (coverageDiff < 0) {
      return '📊 $coverageDiff component${coverageDiff.abs() > 1 ? 's' : ''} (older evidence expired)';
    } else {
      return '📈 Maintained Level $currentLevel';
    }
  }

  /// Format next mission line from MissionSuggestion.
  ///
  /// Returns format: "🎯 Next: [Component] from [View]"
  /// Example: "🎯 Next: Streamline from Side view"
  String _formatNextMission(MissionSuggestion mission) {
    final componentName = _formatComponentName(mission.component);
    final viewName = _formatViewName(mission.recommendedView);

    return '🎯 Next: $componentName from $viewName';
  }

  /// Format component name for display (capitalize first letter).
  String _formatComponentName(ComponentType component) {
    final name = component.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Format view name for display.
  String _formatViewName(ViewType view) {
    switch (view) {
      case ViewType.side:
        return 'Side view';
      case ViewType.front:
        return 'Front view';
      case ViewType.back:
        return 'Back view';
      case ViewType.oblique:
        return 'Oblique view';
      case ViewType.unknown:
        return 'Unknown view';
    }
  }
}
