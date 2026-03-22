import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/global_learning_state.dart';
import '../../../../controllers/survey_state.dart';
import '../../../../models/field_model.dart';

class SecondaryFieldStep extends StatefulWidget {
  const SecondaryFieldStep({super.key});

  @override
  State<SecondaryFieldStep> createState() => _SecondaryFieldStepState();
}

class _SecondaryFieldStepState extends State<SecondaryFieldStep> {
  String? _selectedFieldId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final surveyState = context.read<SurveyState>();
    _selectedFieldId = surveyState.secondaryFieldId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final globalState = context.watch<GlobalLearningState>();
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
                  'اختر مجالاً ثانوياً (اختياري)',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'هذا سيساعدك على توسيع مهاراتك وزيادة فرصك المهنية',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Skip button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.skip_next_rounded,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'يمكنك تخطي هذه الخطوة',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                            Text(
                              'ركز على مجالك الأساسي وأضف مجالاً ثانوياً لاحقاً',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedFieldId = null);
                          surveyState.setSecondaryField(null);
                          // الانتقال للخطوة التالية مباشرة
                          surveyState.nextStep();
                        },
                        child: const Text('تخطي'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مجال...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 24),

                // Fields grid
                if (globalState.allFields.isNotEmpty)
                  _buildFieldsGrid(globalState.allFields, surveyState),

                const SizedBox(height: 16),

                // Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.tertiary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'اختر مجالاً مكملاً لمجالك الأساسي لتوسيع فرصك',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
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

  Widget _buildFieldsGrid(
    Map<String, FieldModel> allFields,
    SurveyState surveyState,
  ) {
    // Filter out primary field
    final filteredFields = allFields.entries.where((entry) {
      if (entry.key == surveyState.primaryFieldId) return false;
      if (_searchQuery.isEmpty) return true;
      final field = entry.value;
      return field.name.toLowerCase().contains(_searchQuery) ||
          field.nameEn.toLowerCase().contains(_searchQuery) ||
          field.description.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredFields.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'لا توجد نتائج للبحث',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      cacheExtent: 1000, // تحسين الأداء بـ caching
      itemCount: filteredFields.length,
      itemBuilder: (context, index) {
        final entry = filteredFields[index];
        final field = entry.value;
        final isSelected = _selectedFieldId == entry.key;

        return _FieldCard(
          field: field,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selectedFieldId = entry.key);
            surveyState.setSecondaryField(entry.key);
          },
        );
      },
    );
  }
}

class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final bool isSelected;
  final VoidCallback onTap;

  const _FieldCard({
    required this.field,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.secondary
                : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.secondary.withOpacity(0.2)
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  field.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              field.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // English name
            Text(
              field.nameEn,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer.withOpacity(0.7)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Skills count
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.secondary.withOpacity(0.2)
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${field.totalSkills} مهارة',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}