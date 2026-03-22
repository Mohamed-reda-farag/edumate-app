import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/survey_state.dart';

class GoalsStep extends StatefulWidget {
  const GoalsStep({super.key});

  @override
  State<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<GoalsStep> {
  final List<String> _selectedObjectives = [];
  String _commitmentLevel = 'medium';
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final surveyState = context.read<SurveyState>();
    if (surveyState.goals.isNotEmpty) {
      _selectedObjectives.addAll(
        List<String>.from(surveyState.goals['objectives'] ?? []),
      );
      _commitmentLevel = surveyState.goals['commitmentLevel'] ?? 'medium';
      _notesController.text = surveyState.goals['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateGoals(SurveyState surveyState) {
    if (_selectedObjectives.isNotEmpty) {
      surveyState.setGoals(
        objectives: _selectedObjectives,
        commitmentLevel: _commitmentLevel,
        notes: _notesController.text,
      );
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
                  'ما هي أهدافك من التعلم؟',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'اختر الأهداف التي تحفزك للاستمرار',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Objectives
                Text(
                  'اختر واحداً أو أكثر:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ObjectiveChip(
                      icon: Icons.work_outline,
                      label: 'تطوير المهارات المهنية',
                      value: 'career',
                      isSelected: _selectedObjectives.contains('career'),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedObjectives.add('career');
                          } else {
                            _selectedObjectives.remove('career');
                          }
                        });
                        _updateGoals(surveyState);
                      },
                    ),
                    _ObjectiveChip(
                      icon: Icons.rocket_launch_outlined,
                      label: 'بدء مشروع جانبي',
                      value: 'side_project',
                      isSelected: _selectedObjectives.contains('side_project'),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedObjectives.add('side_project');
                          } else {
                            _selectedObjectives.remove('side_project');
                          }
                        });
                        _updateGoals(surveyState);
                      },
                    ),
                    _ObjectiveChip(
                      icon: Icons.school_outlined,
                      label: 'التعلم الذاتي',
                      value: 'self_learning',
                      isSelected: _selectedObjectives.contains('self_learning'),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedObjectives.add('self_learning');
                          } else {
                            _selectedObjectives.remove('self_learning');
                          }
                        });
                        _updateGoals(surveyState);
                      },
                    ),
                    _ObjectiveChip(
                      icon: Icons.attach_money_outlined,
                      label: 'زيادة الدخل',
                      value: 'income',
                      isSelected: _selectedObjectives.contains('income'),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedObjectives.add('income');
                          } else {
                            _selectedObjectives.remove('income');
                          }
                        });
                        _updateGoals(surveyState);
                      },
                    ),
                    _ObjectiveChip(
                      icon: Icons.card_membership_outlined,
                      label: 'الحصول على شهادات',
                      value: 'certificates',
                      isSelected: _selectedObjectives.contains('certificates'),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedObjectives.add('certificates');
                          } else {
                            _selectedObjectives.remove('certificates');
                          }
                        });
                        _updateGoals(surveyState);
                      },
                    ),
                    _ObjectiveChip(
                      icon: Icons.swap_horiz_outlined,
                      label: 'تغيير المجال المهني',
                      value: 'career_change',
                      isSelected: _selectedObjectives.contains('career_change'),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedObjectives.add('career_change');
                          } else {
                            _selectedObjectives.remove('career_change');
                          }
                        });
                        _updateGoals(surveyState);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Commitment level
                Text(
                  'ما مستوى التزامك؟',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _CommitmentCard(
                  icon: Icons.wb_sunny_outlined,
                  title: 'خفيف',
                  subtitle: 'أتعلم في وقت الفراغ',
                  value: 'low',
                  isSelected: _commitmentLevel == 'low',
                  color: Colors.blue,
                  onTap: () {
                    setState(() => _commitmentLevel = 'low');
                    _updateGoals(surveyState);
                  },
                ),
                const SizedBox(height: 12),

                _CommitmentCard(
                  icon: Icons.trending_up_outlined,
                  title: 'متوسط',
                  subtitle: 'أخصص وقتاً منتظماً للتعلم',
                  value: 'medium',
                  isSelected: _commitmentLevel == 'medium',
                  color: Colors.green,
                  onTap: () {
                    setState(() => _commitmentLevel = 'medium');
                    _updateGoals(surveyState);
                  },
                ),
                const SizedBox(height: 12),

                _CommitmentCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'عالي',
                  subtitle: 'التعلم أولوية قصوى بالنسبة لي',
                  value: 'high',
                  isSelected: _commitmentLevel == 'high',
                  color: Colors.deepOrange,
                  onTap: () {
                    setState(() => _commitmentLevel = 'high');
                    _updateGoals(surveyState);
                  },
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Additional notes
                Text(
                  'ملاحظات إضافية (اختياري)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أخبرنا بالمزيد عن أهدافك أو احتياجاتك الخاصة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'مثال: أريد التركيز على تطوير تطبيقات الهاتف المحمول...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _updateGoals(surveyState),
                ),

                const SizedBox(height: 16),

                // Motivation message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'رحلتك التعليمية على وشك البدء! سنساعدك على تحقيق أهدافك خطوة بخطوة.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
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

class _ObjectiveChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _ObjectiveChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: onChanged,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _CommitmentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
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
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
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

            // Radio
            Radio<String>(
              value: value,
              groupValue: isSelected ? value : null,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}