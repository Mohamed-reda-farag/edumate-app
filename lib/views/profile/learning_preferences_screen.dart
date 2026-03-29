import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/global_learning_state.dart';
import 'confirmation_dialogs.dart';

/// شاشة تفضيلات التعلم والأهداف — منفصلة عن SettingsScreen الرئيسية.
/// تحتوي على قسمَي "تفضيلات التعلم" و"أهدافك" كما كانا في الإعدادات.
class LearningPreferencesScreen extends StatelessWidget {
  const LearningPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفضيلات التعلم'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GlobalLearningState>(
        builder: (context, globalState, _) {
          if (globalState.isLoadingUserProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LearningPreferencesSection(globalState: globalState),
                const SizedBox(height: 24),
                _GoalsSection(globalState: globalState),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// قسم تفضيلات التعلم
// ─────────────────────────────────────────────────────────────────────────────

class _LearningPreferencesSection extends StatelessWidget {
  final GlobalLearningState globalState;
  const _LearningPreferencesSection({required this.globalState});

  @override
  Widget build(BuildContext context) {
    final preferences = globalState.userProfile?.preferences ?? {};
    final preferredTimesRaw = preferences['preferredTimes'];
    final List<String> preferredTimes;
    if (preferredTimesRaw is List) {
      preferredTimes = preferredTimesRaw.map((e) => e.toString()).toList();
    } else {
      preferredTimes = ['morning'];
    }
    final weekDaysCount =
        (preferences['weekDaysCount'] is int)
            ? preferences['weekDaysCount'] as int
            : int.tryParse(preferences['weekDaysCount']?.toString() ?? '') ?? 3;
    final sessionDuration =
        preferences['sessionDuration']?.toString() ?? 'medium';

    return _SectionCard(
      title: 'تفضيلات التعلم',
      icon: Icons.access_time_rounded,
      children: [
        const Text(
          'الأوقات المفضلة',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _TimeChip(
              label: 'صباحاً',
              value: 'morning',
              selectedTimes: preferredTimes,
              globalState: globalState,
            ),
            _TimeChip(
              label: 'ظهراً',
              value: 'afternoon',
              selectedTimes: preferredTimes,
              globalState: globalState,
            ),
            _TimeChip(
              label: 'مساءً',
              value: 'evening',
              selectedTimes: preferredTimes,
              globalState: globalState,
            ),
            _TimeChip(
              label: 'ليلاً',
              value: 'night',
              selectedTimes: preferredTimes,
              globalState: globalState,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'أيام الأسبوع',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _WeekDaysSlider(
          weekDaysCount: weekDaysCount,
          globalState: globalState,
        ),
        const SizedBox(height: 20),
        const Text(
          'مدة الجلسة',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _DurationOption(
              value: 'short',
              label: 'قصيرة\n15-30 دقيقة',
              currentValue: sessionDuration,
              globalState: globalState,
            ),
            const SizedBox(width: 8),
            _DurationOption(
              value: 'medium',
              label: 'متوسطة\n30-60 دقيقة',
              currentValue: sessionDuration,
              globalState: globalState,
            ),
            const SizedBox(width: 8),
            _DurationOption(
              value: 'long',
              label: 'طويلة\n60+ دقيقة',
              currentValue: sessionDuration,
              globalState: globalState,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// قسم الأهداف والالتزام
// ─────────────────────────────────────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  final GlobalLearningState globalState;
  const _GoalsSection({required this.globalState});

  @override
  Widget build(BuildContext context) {
    final preferences = globalState.userProfile?.preferences ?? {};
    final goalsRaw = preferences['goals'];
    final List<String> goals;
    if (goalsRaw is List) {
      goals = goalsRaw.map((e) => e.toString()).toList();
    } else {
      goals = ['professional'];
    }
    final commitmentLevel =
        preferences['commitmentLevel']?.toString() ?? 'medium';

    return _SectionCard(
      title: 'أهدافك',
      icon: Icons.flag_rounded,
      children: [
        const Text(
          'ماذا تريد أن تحقق؟',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _GoalChip(
              value: 'professional',
              label: '💼 المهارات المهنية',
              selectedGoals: goals,
              globalState: globalState,
            ),
            _GoalChip(
              value: 'certificate',
              label: '🎓 الشهادات',
              selectedGoals: goals,
              globalState: globalState,
            ),
            _GoalChip(
              value: 'side_project',
              label: '🚀 مشروع جانبي',
              selectedGoals: goals,
              globalState: globalState,
            ),
            _GoalChip(
              value: 'career_change',
              label: '🔄 تغيير المسار',
              selectedGoals: goals,
              globalState: globalState,
            ),
            _GoalChip(
              value: 'personal',
              label: '✨ التطوير الشخصي',
              selectedGoals: goals,
              globalState: globalState,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'مستوى الالتزام',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _CommitmentOption(
              value: 'light',
              label: 'خفيف',
              currentValue: commitmentLevel,
              globalState: globalState,
            ),
            const SizedBox(width: 8),
            _CommitmentOption(
              value: 'medium',
              label: 'متوسط',
              currentValue: commitmentLevel,
              globalState: globalState,
            ),
            const SizedBox(width: 8),
            _CommitmentOption(
              value: 'high',
              label: 'عالي',
              currentValue: commitmentLevel,
              globalState: globalState,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets مساعدة
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _updatePreference(
  BuildContext context,
  GlobalLearningState globalState,
  String key,
  dynamic value,
) async {
  try {
    await globalState.updatePreferences({key: value});
  } catch (e) {
    if (context.mounted) {
      ConfirmationDialogs.showErrorSnackBar(context, 'فشل حفظ التفضيلات');
    }
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String value;
  final List<String> selectedTimes;
  final GlobalLearningState globalState;

  const _TimeChip({
    required this.label,
    required this.value,
    required this.selectedTimes,
    required this.globalState,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTimes.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        final newTimes = List<String>.from(selectedTimes);
        if (selected) {
          newTimes.add(value);
        } else {
          if (newTimes.length > 1) newTimes.remove(value);
        }
        await _updatePreference(context, globalState, 'preferredTimes', newTimes);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _WeekDaysSlider extends StatelessWidget {
  final int weekDaysCount;
  final GlobalLearningState globalState;

  const _WeekDaysSlider({
    required this.weekDaysCount,
    required this.globalState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: weekDaysCount.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$weekDaysCount أيام',
            onChanged: (value) {
              _updatePreference(
                context,
                globalState,
                'weekDaysCount',
                value.toInt(),
              );
            },
          ),
        ),
        Text(
          '$weekDaysCount',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text('أيام', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

class _DurationOption extends StatelessWidget {
  final String value;
  final String label;
  final String currentValue;
  final GlobalLearningState globalState;

  const _DurationOption({
    required this.value,
    required this.label,
    required this.currentValue,
    required this.globalState,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentValue == value;
    return Expanded(
      child: InkWell(
        onTap: () =>
            _updatePreference(context, globalState, 'sessionDuration', value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String value;
  final String label;
  final List<String> selectedGoals;
  final GlobalLearningState globalState;

  const _GoalChip({
    required this.value,
    required this.label,
    required this.selectedGoals,
    required this.globalState,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedGoals.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final newGoals = List<String>.from(selectedGoals);
        if (selected) {
          newGoals.add(value);
        } else {
          if (newGoals.length > 1) newGoals.remove(value);
        }
        _updatePreference(context, globalState, 'goals', newGoals);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _CommitmentOption extends StatelessWidget {
  final String value;
  final String label;
  final String currentValue;
  final GlobalLearningState globalState;

  const _CommitmentOption({
    required this.value,
    required this.label,
    required this.currentValue,
    required this.globalState,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentValue == value;
    return Expanded(
      child: InkWell(
        onTap: () =>
            _updatePreference(context, globalState, 'commitmentLevel', value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة القسم — نفس تصميم _buildSection في SettingsScreen
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}