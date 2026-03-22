import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/survey_state.dart';

class LearningScheduleStep extends StatefulWidget {
  const LearningScheduleStep({super.key});

  @override
  State<LearningScheduleStep> createState() => _LearningScheduleStepState();
}

class _LearningScheduleStepState extends State<LearningScheduleStep> {
  final List<String> _selectedTimes = [];
  int _daysPerWeek = 3;

  @override
  void initState() {
    super.initState();
    final surveyState = context.read<SurveyState>();
    if (surveyState.schedule.isNotEmpty) {
      _selectedTimes.addAll(
        List<String>.from(surveyState.schedule['preferredTimes'] ?? []),
      );
      _daysPerWeek = surveyState.schedule['daysPerWeek'] ?? 3;
    }
  }

  void _updateSchedule(SurveyState surveyState) {
    if (_selectedTimes.isNotEmpty) {
      surveyState.setSchedule(_selectedTimes, _daysPerWeek);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surveyState = context.watch<SurveyState>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'متى تفضل التعلم؟',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'اختر الأوقات المناسبة لك خلال اليوم',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Time slots
                Text(
                  'الأوقات المفضلة:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _TimeSlotCard(
                  icon: '☀️',
                  title: 'صباحاً',
                  subtitle: '6 صباحاً - 12 ظهراً',
                  value: 'morning',
                  isSelected: _selectedTimes.contains('morning'),
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTimes.add('morning');
                      } else {
                        _selectedTimes.remove('morning');
                      }
                    });
                    _updateSchedule(surveyState);
                  },
                ),
                const SizedBox(height: 12),

                _TimeSlotCard(
                  icon: '🌤️',
                  title: 'ظهراً',
                  subtitle: '12 ظهراً - 6 مساءً',
                  value: 'afternoon',
                  isSelected: _selectedTimes.contains('afternoon'),
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTimes.add('afternoon');
                      } else {
                        _selectedTimes.remove('afternoon');
                      }
                    });
                    _updateSchedule(surveyState);
                  },
                ),
                const SizedBox(height: 12),

                _TimeSlotCard(
                  icon: '🌙',
                  title: 'مساءً',
                  subtitle: '6 مساءً - 12 منتصف الليل',
                  value: 'evening',
                  isSelected: _selectedTimes.contains('evening'),
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTimes.add('evening');
                      } else {
                        _selectedTimes.remove('evening');
                      }
                    });
                    _updateSchedule(surveyState);
                  },
                ),
                const SizedBox(height: 12),

                _TimeSlotCard(
                  icon: '🌃',
                  title: 'ليلاً',
                  subtitle: '12 منتصف الليل - 6 صباحاً',
                  value: 'night',
                  isSelected: _selectedTimes.contains('night'),
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTimes.add('night');
                      } else {
                        _selectedTimes.remove('night');
                      }
                    });
                    _updateSchedule(surveyState);
                  },
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Days per week
                Text(
                  'كم يوماً في الأسبوع؟',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Days slider
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_daysPerWeek ${_daysPerWeek == 1 ? 'يوم' : _daysPerWeek == 2 ? 'يومين' : 'أيام'}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'في الأسبوع',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: _daysPerWeek.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        label: _daysPerWeek.toString(),
                        onChanged: (value) {
                          setState(() => _daysPerWeek = value.toInt());
                          _updateSchedule(surveyState);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '7',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'نوصي بـ 3-5 أيام في الأسبوع للحصول على أفضل النتائج',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _TimeSlotCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => onChanged(value ?? false),
            ),
          ],
        ),
      ),
    );
  }
}