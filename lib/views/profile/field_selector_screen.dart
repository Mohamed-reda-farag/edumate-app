// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/field_model.dart';

class FieldSelectorScreen extends StatefulWidget {
  final bool isPrimary;
  final List<String> excludeFields; // المجالات المستثناة (المختارة حالياً)

  const FieldSelectorScreen({
    super.key,
    required this.isPrimary,
    this.excludeFields = const [],
  });

  @override
  State<FieldSelectorScreen> createState() => _FieldSelectorScreenState();
}

class _FieldSelectorScreenState extends State<FieldSelectorScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPrimary ? 'اختر مجالاً أساسياً' : 'اختر مجالاً ثانوياً',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GlobalLearningState>(
        builder: (context, globalState, child) {
          if (globalState.isLoadingStaticData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allFields = globalState.allFields.values.toList();
          
          // فلترة المجالات
          var filteredFields = allFields.where((field) {
            // استبعاد المجالات المختارة
            if (widget.excludeFields.contains(field.id)) {
              return false;
            }
            
            // بحث
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              if (!field.name.toLowerCase().contains(query) &&
                  !field.description.toLowerCase().contains(query)) {
                return false;
              }
            }
            
            // فلترة حسب الفئة
            if (_selectedCategory != null && field.category != _selectedCategory) {
              return false;
            }
            
            return true;
          }).toList();

          // استخراج الفئات
          final categories = allFields
              .map((f) => f.category)
              .toSet()
              .toList()
            ..sort();

          return Column(
            children: [
              // شريط البحث
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مجال...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // فلتر الفئات
              if (categories.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip('الكل', null),
                      ...categories.map((category) =>
                        _buildCategoryChip(
                          _getCategoryName(category),
                          category,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // قائمة المجالات
              Expanded(
                child: filteredFields.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredFields.length,
                        itemBuilder: (context, index) {
                          final field = filteredFields[index];
                          return _buildFieldCard(field);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFieldCard(FieldModel field) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pop(context, field.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // أيقونة المجال
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      field.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // اسم المجال
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryName(field.category),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أيقونة السهم
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // الوصف
              Text(
                field.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // معلومات إضافية
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.star,
                    label: '${field.skills.length} مهارة',
                    color: Colors.orange,
                  ),
                  _buildInfoChip(
                    icon: Icons.business,
                    label: '${field.careerPaths.length} مسار وظيفي',
                    color: Colors.blue,
                  ),
                  _buildInfoChip(
                    icon: Icons.trending_up,
                    label: 'الطلب: ${field.demandLevel}/10',
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    const categoryNames = {
      'tech': 'تقنية',
      'business': 'أعمال',
      'creative': 'إبداعي',
      'science': 'علمي',
      'languages': 'لغات',
      'personal': 'تطوير شخصي',
    };
    return categoryNames[category] ?? category;
  }
}

/// Bottom Sheet للاختيار السريع
class FieldSelectorBottomSheet {
  static Future<String?> show(
    BuildContext context, {
    required bool isPrimary,
    List<String> excludeFields = const [],
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FieldSelectorScreen(
            isPrimary: isPrimary,
            excludeFields: excludeFields,
          ),
        ),
      ),
    );
  }
}