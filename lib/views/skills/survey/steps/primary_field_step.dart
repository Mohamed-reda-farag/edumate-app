import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../controllers/global_learning_state.dart';
import '../../../../controllers/survey_state.dart';
import '../../../../models/field_model.dart';

class PrimaryFieldStep extends StatefulWidget {
  const PrimaryFieldStep({super.key});

  @override
  State<PrimaryFieldStep> createState() => _PrimaryFieldStepState();
}

class _PrimaryFieldStepState extends State<PrimaryFieldStep> {
  String? _selectedFieldId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final surveyState = context.read<SurveyState>();
    _selectedFieldId = surveyState.primaryFieldId;

    // تحميل المجالات مسبقاً
    _loadFieldsIfNeeded();
  }

  Future<void> _loadFieldsIfNeeded() async {
    final globalState = context.read<GlobalLearningState>();

    // انتظر انتهاء أي تحميل جارٍ
    if (globalState.isLoadingStaticData) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return globalState.isLoadingStaticData;
      });
    }

    if (!mounted) return;

    const int expectedMinFields = 10; // حد أدنى معقول — أقل منه يعني بيانات ناقصة
    if (globalState.allFields.length < expectedMinFields) {
      await globalState.loadAllFields();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // إلغاء timer السابق
    _debounceTimer?.cancel();
    
    // إنشاء timer جديد
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.toLowerCase());
    });
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
                  'اختر مجالك الأساسي للتعلم',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'هذا هو المجال الذي ستركز عليه في رحلتك التعليمية',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
                              _debounceTimer?.cancel();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 24),

                // Loading state
                if (globalState.isLoadingStaticData)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (globalState.allFields.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_off,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد مجالات متاحة',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => globalState.loadAllFields(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildFieldsGrid(globalState.allFields, surveyState),

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
                          'نصيحة: اختر المجال الأقرب لأهدافك المهنية',
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

  Widget _buildFieldsGrid(
    Map<String, FieldModel> allFields,
    SurveyState surveyState,
  ) {
    // Filter fields based on search
    final filteredFields = allFields.entries.where((entry) {
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
            surveyState.setPrimaryField(entry.key);
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
      onLongPress: () {
        // Show field details dialog
        showDialog(
          context: context,
          builder: (context) => _FieldDetailsDialog(field: field),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    ? theme.colorScheme.primary.withOpacity(0.2)
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
                    ? theme.colorScheme.onPrimaryContainer
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
                    ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
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
                    ? theme.colorScheme.primary.withOpacity(0.2)
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

class _FieldDetailsDialog extends StatelessWidget {
  final FieldModel field;

  const _FieldDetailsDialog({required this.field});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    field.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          field.nameEn,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                field.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'عدد المهارات: ${field.totalSkills}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('فهمت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}