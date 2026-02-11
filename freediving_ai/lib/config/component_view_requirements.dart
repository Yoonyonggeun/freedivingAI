import '../services/view_classifier.dart';

/// Component view requirements configuration.
///
/// Defines which camera angles are suitable for measuring each DNF component.
/// Used by DNFFullAnalyzer to determine if a component is measurable based on
/// the detected view angle.
class ComponentViewRequirements {
  /// Best view types for each component.
  ///
  /// Components are measurable from these views with high confidence.
  static const Map<String, List<ViewType>> bestViews = {
    'streamline': [ViewType.side],
    'kick': [ViewType.frontBack, ViewType.side],
    'arm': [ViewType.frontBack], // TOP_DOWN mapped as oblique with overhead detection
    'glide': [ViewType.side],
    'start': [ViewType.side],
    'turn': [ViewType.side],
  };

  /// Acceptable view types for each component (less ideal but usable).
  ///
  /// These views allow measurement but with reduced precision or confidence.
  static const Map<String, List<ViewType>> acceptableViews = {
    'streamline': [], // Side only
    'kick': [ViewType.oblique], // Can work with oblique
    'arm': [ViewType.oblique, ViewType.side],
    'glide': [], // Side only
    'start': [], // Side only
    'turn': [], // Side only
  };

  /// Check if a view type is suitable (best or acceptable) for a component.
  ///
  /// Returns true if the view allows measurement, false otherwise.
  static bool isViewSuitable(String componentId, ViewType viewType) {
    // Unknown or overhead views are never suitable
    if (viewType == ViewType.unknown || viewType == ViewType.overhead) {
      return false;
    }

    // Check best views first
    final best = bestViews[componentId] ?? [];
    if (best.contains(viewType)) {
      return true;
    }

    // Check acceptable views
    final acceptable = acceptableViews[componentId] ?? [];
    return acceptable.contains(viewType);
  }

  /// Get the quality level for a component from a given view.
  ///
  /// Returns 'best', 'acceptable', or 'unsuitable'.
  static String getViewQuality(String componentId, ViewType viewType) {
    if (viewType == ViewType.unknown || viewType == ViewType.overhead) {
      return 'unsuitable';
    }

    final best = bestViews[componentId] ?? [];
    if (best.contains(viewType)) {
      return 'best';
    }

    final acceptable = acceptableViews[componentId] ?? [];
    if (acceptable.contains(viewType)) {
      return 'acceptable';
    }

    return 'unsuitable';
  }

  /// Get a human-readable reason why a view is unsuitable for a component.
  static String getUnsuitableReason(String componentId, ViewType viewType) {
    // Handle overhead and unknown universally
    if (viewType == ViewType.overhead) {
      return 'Camera angle unsuitable (overhead view)';
    }
    if (viewType == ViewType.unknown) {
      return 'Unable to determine camera angle — body landmarks not clearly visible';
    }

    // Component-specific unsuitable reasons
    switch (componentId) {
      case 'streamline':
        if (viewType == ViewType.frontBack) {
          return 'Camera angle unsuitable (front/back view)';
        } else if (viewType == ViewType.oblique) {
          return 'Camera angle unsuitable (oblique view)';
        }
        break;
      case 'glide':
        if (viewType == ViewType.frontBack) {
          return 'Camera angle unsuitable (front/back view)';
        } else if (viewType == ViewType.oblique) {
          return 'Camera angle unsuitable (oblique view)';
        }
        break;
      case 'start':
      case 'turn':
        if (viewType == ViewType.frontBack) {
          return 'Camera angle unsuitable (front/back view)';
        } else if (viewType == ViewType.oblique) {
          return 'Camera angle unsuitable (oblique view)';
        }
        break;
      case 'kick':
        // Kick is measurable from most views except overhead/unknown
        break;
      case 'arm':
        // Arm is measurable from most views except overhead/unknown (side is acceptable)
        break;
    }

    return 'Camera angle unsuitable (${viewType.displayName})';
  }

  /// Get suggested view for a component.
  static String getSuggestedView(String componentId) {
    final best = bestViews[componentId] ?? [];
    if (best.isEmpty) return 'side view';

    if (best.contains(ViewType.side)) {
      return 'side view';
    } else if (best.contains(ViewType.frontBack)) {
      return 'front or rear view';
    } else if (best.contains(ViewType.oblique)) {
      return 'oblique (angled) view';
    }

    return 'side view';
  }

  /// Get fix path for unsuitable view.
  ///
  /// Provides actionable single-step guidance for the user to re-record.
  static String getFixPath(String componentId, ViewType currentView) {
    // Provide a single, clear next action based on component
    switch (componentId) {
      case 'streamline':
      case 'glide':
      case 'start':
      case 'turn':
        return 'Record from side view';
      case 'kick':
        return 'Record from front or rear view';
      case 'arm':
        return 'Record from front or rear view';
      default:
        return 'Record from side view';
    }
  }

  /// Check if view quality should affect confidence scoring.
  ///
  /// If view is acceptable but not best, reduce confidence slightly.
  static double getViewConfidenceMultiplier(String componentId, ViewType viewType) {
    final quality = getViewQuality(componentId, viewType);
    switch (quality) {
      case 'best':
        return 1.0;
      case 'acceptable':
        return 0.85; // Slight reduction for non-ideal view
      case 'unsuitable':
        return 0.0; // Component not measurable
      default:
        return 0.0;
    }
  }

  static String _getComponentDisplayName(String componentId) {
    switch (componentId) {
      case 'streamline':
        return 'Streamline';
      case 'kick':
        return 'Kick';
      case 'arm':
        return 'Arm Stroke';
      case 'glide':
        return 'Glide';
      case 'start':
        return 'Start/Push-off';
      case 'turn':
        return 'Turn';
      default:
        return componentId;
    }
  }
}
