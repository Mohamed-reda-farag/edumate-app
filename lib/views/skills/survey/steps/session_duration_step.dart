import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/survey_state.dart';

class SessionDurationStep extends StatefulWidget {
  const SessionDurationStep({super.key});

  @override
  State<SessionDurationStep> createState() => _SessionDurationStepState();
}

class _SessionDurationStepState extends State<SessionDurationStep> {
  String? _selectedDuration;

  @override
  void initState() {
    super.initState();
    final surveyState = context.read<SurveyState>();
    _selectedDuration = surveyState.sessionDuration;
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
                  'كم من الوقت تريد التعلم يومياً؟',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'اختر المدة التي تناسب جدولك اليومي',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Duration options
                _DurationCard(
                  icon: '⚡',
                  title: 'جلسة قصيرة',
                  duration: '15-30 دقيقة',
                  description: 'مثالي للمبتدئين أو أصحاب الوقت المحدود',
                  value: 'short',
                  isSelected: _selectedDuration == 'short',
                  color: Colors.amber,
                  onTap: () {
                    setState(() => _selectedDuration = 'short');
                    surveyState.setSessionDuration('short');
                  },
                ),
                const SizedBox(height: 16),

                _DurationCard(
                  icon: '✅',
                  title: 'جلسة متوسطة',
                  duration: '30-60 دقيقة',
                  description: 'توازن مثالي بين التعلم والالتزام اليومي',
                  value: 'medium',
                  isSelected: _selectedDuration == 'medium',
                  isRecommended: true,
                  color: Colors.green,
                  onTap: () {
                    setState(() => _selectedDuration = 'medium');
                    surveyState.setSessionDuration('medium');
                  },
                ),
                const SizedBox(height: 16),

                _DurationCard(
                  icon: '🔥',
                  title: 'جلسة طويلة',
                  duration: '60-120 دقيقة',
                  description: 'للمتحمسين الذين يريدون تقدماً سريعاً',
                  value: 'long',
                  isSelected: _selectedDuration == 'long',
                  color: Colors.deepOrange,
                  onTap: () {
                    setState(() => _selectedDuration = 'long');
                    surveyState.setSessionDuration('long');
                  },
                ),

                const SizedBox(height: 24),

                // Comparison table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'مقارنة سريعة',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ComparisonRow(
                        label: 'مناسب للمبتدئين',
                        short: true,
                        medium: true,
                        long: false,
                      ),
                      _ComparisonRow(
                        label: 'تقدم سريع',
                        short: false,
                        medium: true,
                        long: true,
                      ),
                      _ComparisonRow(
                        label: 'سهل الالتزام',
                        short: true,
                        medium: true,
                        long: false,
                      ),
                      _ComparisonRow(
                        label: 'تغطية شاملة',
                        short: false,
                        medium: true,
                        long: true,
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
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'يمكنك تغيير مدة الجلسات في أي وقت من الإعدادات',
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

class _DurationCard extends StatelessWidget {
  final String icon;
  final String title;
  final String duration;
  final String description;
  final String value;
  final bool isSelected;
  final bool isRecommended;
  final Color color;
  final VoidCallback onTap;

  const _DurationCard({
    required this.icon,
    required this.title,
    required this.duration,
    required this.description,
    required this.value,
    required this.isSelected,
    this.isRecommended = false,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title and duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isSelected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 6),
                            Chip(
                              label: const Text(
                                'موصى بها',
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.green.withOpacity(0.2),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        duration,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
            const SizedBox(height: 10),

            // Description
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final bool short;
  final bool medium;
  final bool long;

  const _ComparisonRow({
    required this.label,
    required this.short,
    required this.medium,
    required this.long,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                short ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: short ? Colors.green : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                medium ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: medium ? Colors.green : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                long ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: long ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}