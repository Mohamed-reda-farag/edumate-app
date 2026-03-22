import 'package:flutter/foundation.dart';

class SurveyState extends ChangeNotifier {
  // Current step
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Total steps
  static const int totalSteps = 6;

  // Data collected
  String? primaryFieldId;
  String? secondaryFieldId;
  Map<String, String> skillLevels = {}; // skillId -> level
  Map<String, dynamic> schedule = {};
  String? sessionDuration;
  Map<String, dynamic> goals = {};

  // Navigation
  bool get canGoNext {
    switch (_currentStep) {
      case 0:
        return primaryFieldId != null;
      case 1:
        return true; // optional step
      case 2:
        return skillLevels.isNotEmpty;
      case 3:
        return schedule.isNotEmpty &&
            schedule['preferredTimes'] != null &&
            schedule['daysPerWeek'] != null;
      case 4:
        return sessionDuration != null;
      case 5:
        return goals.isNotEmpty &&
            goals['objectives'] != null &&
            goals['commitmentLevel'] != null;
      default:
        return false;
    }
  }

  bool get canGoPrevious => _currentStep > 0;
  bool get isLastStep => _currentStep == totalSteps - 1;

  double get progress => (_currentStep + 1) / totalSteps;

  void nextStep() {
    if (canGoNext && _currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (canGoPrevious) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Data setters
  void setPrimaryField(String fieldId) {
    primaryFieldId = fieldId;
    // Reset secondary field if it's the same as primary
    if (secondaryFieldId == fieldId) {
      secondaryFieldId = null;
    }
    notifyListeners();
  }

  void setSecondaryField(String? fieldId) {
    secondaryFieldId = fieldId;
    notifyListeners();
  }

  void setSkillLevel(String skillId, String level) {
    skillLevels[skillId] = level;
    notifyListeners();
  }

  void setAllSkillLevels(Map<String, String> levels) {
    skillLevels = Map.from(levels);
    notifyListeners();
  }

  void setSchedule(List<String> preferredTimes, int daysPerWeek) {
    schedule = {
      'preferredTimes': preferredTimes,
      'daysPerWeek': daysPerWeek,
    };
    notifyListeners();
  }

  void setSessionDuration(String duration) {
    sessionDuration = duration;
    notifyListeners();
  }

  void setGoals({
    required List<String> objectives,
    required String commitmentLevel,
    String? notes,
  }) {
    goals = {
      'objectives': objectives,
      'commitmentLevel': commitmentLevel,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    notifyListeners();
  }

  // Validation
  String? validate() {
    if (primaryFieldId == null) {
      return 'يرجى اختيار مجالك الأساسي';
    }
    if (skillLevels.isEmpty) {
      return 'يرجى تحديد مستواك في المهارات';
    }
    if (schedule.isEmpty) {
      return 'يرجى تحديد جدولك التعليمي';
    }
    if (sessionDuration == null) {
      return 'يرجى اختيار مدة الجلسات';
    }
    if (goals.isEmpty) {
      return 'يرجى تحديد أهدافك';
    }
    return null;
  }

  // Reset
  void reset() {
    _currentStep = 0;
    primaryFieldId = null;
    secondaryFieldId = null;
    skillLevels.clear();
    schedule.clear();
    sessionDuration = null;
    goals.clear();
    notifyListeners();
  }

  // Get collected data
  Map<String, dynamic> getCollectedData() {
    return {
      'primaryFieldId': primaryFieldId,
      'secondaryFieldId': secondaryFieldId,
      'skillLevels': skillLevels,
      'schedule': schedule,
      'sessionDuration': sessionDuration,
      'goals': goals,
    };
  }
}