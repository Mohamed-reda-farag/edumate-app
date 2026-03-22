import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/global_learning_state.dart';
import '../../../../models/skill_model.dart';
import '../../../../controllers/survey_state.dart';

class SkillLevelsStep extends StatefulWidget {
  const SkillLevelsStep({super.key});

  @override
  State<SkillLevelsStep> createState() => _SkillLevelsStepState();
}

class _SkillLevelsStepState extends State<SkillLevelsStep> {
  final Map<String, String> _skillLevels = {};

  @override
  void initState() {
    super.initState();
    final surveyState = context.read<SurveyState>();
    _skillLevels.addAll(surveyState.skillLevels);

    // Initialize with foundation level if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSkillLevels();
    });
  }

  void _initializeSkillLevels() {
    final globalState = context.read<GlobalLearningState>();
    final surveyState = context.read<SurveyState>();

    if (surveyState.primaryFieldId == null) return;

    final field = globalState.getFieldData(surveyState.primaryFieldId!);
    if (field == null) return;

    // Initialize all skills with foundation level if not set
    for (var skill in field.skills.values) {
      _skillLevels.putIfAbsent(skill.id, () => 'foundation');
    }

    if (mounted) {
      setState(() {});
      surveyState.setAllSkillLevels(_skillLevels);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final globalState = context.watch<GlobalLearningState>();
    final surveyState = context.watch<SurveyState>();

    if (surveyState.primaryFieldId == null) {
      return const Center(
        child: Text('يرجى اختيار المجال الأساسي أولاً'),
      );
    }

    final field = globalState.getFieldData(surveyState.primaryFieldId!);
    if (field == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final skills = field.skills.values.toList()
      ..sort((a, b) => a.importance.compareTo(b.importance));

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
                  'حدد مستواك في هذه المهارات',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'سيساعدنا هذا على توجيهك للمحتوى المناسب لمستواك',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Quick assessment button
                OutlinedButton.icon(
                  onPressed: () => _showQuickAssessment(context, skills),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('تقييم سريع'),
                ),
                const SizedBox(height: 24),

                // Skills list
                ...skills.map((skill) => _buildSkillCard(skill, surveyState)),

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
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'لا تقلق! يمكنك البدء من الصفر في أي مهارة',
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

  Widget _buildSkillCard(SkillModel skill, SurveyState surveyState) {
    final theme = Theme.of(context);
    final selectedLevel = _skillLevels[skill.id] ?? 'foundation';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill header
            Row(
              children: [
                Text(
                  skill.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        skill.nameEn,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (skill.isMandatory)
                  Chip(
                    label: const Text(
                      'إلزامي',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: theme.colorScheme.errorContainer,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Level selector
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LevelChip(
                  label: 'مبتدئ',
                  value: 'foundation',
                  groupValue: selectedLevel,
                  onSelected: (value) {
                    setState(() => _skillLevels[skill.id] = value);
                    surveyState.setSkillLevel(skill.id, value);
                  },
                ),
                _LevelChip(
                  label: 'متوسط',
                  value: 'intermediate',
                  groupValue: selectedLevel,
                  onSelected: (value) {
                    setState(() => _skillLevels[skill.id] = value);
                    surveyState.setSkillLevel(skill.id, value);
                  },
                ),
                _LevelChip(
                  label: 'متقدم',
                  value: 'advanced',
                  groupValue: selectedLevel,
                  onSelected: (value) {
                    setState(() => _skillLevels[skill.id] = value);
                    surveyState.setSkillLevel(skill.id, value);
                  },
                ),
                _LevelChip(
                  label: 'خبير',
                  value: 'expert',
                  groupValue: selectedLevel,
                  onSelected: (value) {
                    setState(() => _skillLevels[skill.id] = value);
                    surveyState.setSkillLevel(skill.id, value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAssessment(BuildContext context, List<SkillModel> skills) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تقييم سريع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر مستوى عام لجميع المهارات:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('مبتدئ في الجميع'),
              onTap: () {
                _setAllSkillsLevel('foundation');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('متوسط في الجميع'),
              onTap: () {
                _setAllSkillsLevel('intermediate');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('متقدم في الجميع'),
              onTap: () {
                _setAllSkillsLevel('advanced');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _setAllSkillsLevel(String level) {
    final surveyState = context.read<SurveyState>();
    for (var skillId in _skillLevels.keys) {
      _skillLevels[skillId] = level;
    }
    setState(() {});
    surveyState.setAllSkillLevels(_skillLevels);
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  const _LevelChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }
}