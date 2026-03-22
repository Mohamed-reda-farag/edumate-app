import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../controllers/global_learning_state.dart';
import '../../widgets/skill_card_skeleton.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/skill_utils.dart';
import '../../router.dart';

/// شاشة المهارات النشطة (التقدم < 80%)
class ActiveSkillsScreen extends StatefulWidget {
  final bool embedded;

  const ActiveSkillsScreen({
    super.key,
    this.embedded = false, // ← إضافة
  });

  @override
  State<ActiveSkillsScreen> createState() => ActiveSkillsScreenState();
}

// public State لتمكين الاستدعاء من FieldsHubScreen
class ActiveSkillsScreenState extends State<ActiveSkillsScreen> {
  String? _selectedFieldId; // null = الكل
  _SortOption _sortOption = _SortOption.importance;

  @override
  void initState() {
    super.initState();
    // إعداد اللغة العربية للتواريخ
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // الوضع المدمج - بدون Scaffold و AppBar
      return _buildContent();
    }

    // الوضع المستقل
    return Scaffold(
      appBar: AppBar(
        title: const Text('المهارات النشطة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: showSortOptions,
            tooltip: 'ترتيب',
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppNavigation.goToLearnedSkills();
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('المهارات المتعلمة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 3. استخراج المحتوى
  Widget _buildContent() {
    return Consumer<GlobalLearningState>(
      builder: (context, state, child) {
        if (!state.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isLoadingUserProfile) {
          return _buildLoadingState();
        }

        if (state.userProfileError != null) {
          return _buildErrorState(state.userProfileError!);
        }

        if (!state.hasUserProfile) {
          return const EmptyStateWidget(
            icon: Icons.person_off,
            title: 'لا يوجد ملف تعريفي',
            subtitle: 'الرجاء تسجيل الدخول أولاً',
          );
        }

        final activeSkills = state.getActiveSkills(fieldId: _selectedFieldId);

        if (activeSkills.isEmpty) {
          return _buildEmptyState();
        }

        final sortedSkills = _sortSkills(activeSkills, state);

        return RefreshIndicator(
          onRefresh: () => state.refreshCurrentUser(),
          child: Column(
            children: [
              _buildHeaderStats(activeSkills, state),
              if (!widget.embedded)
                _buildFilterChips(state), // ← إخفاء في الوضع المدمج
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: sortedSkills.length,
                  itemBuilder: (context, index) {
                    return _buildSkillCard(sortedSkills[index], state);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderStats(
    List<SkillProgress> skills,
    GlobalLearningState state,
  ) {
    final nearCompletion =
        skills.where((s) => s.progressPercentage >= 70).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 20),
              const SizedBox(width: 8),
              Text(
                'لديك ${skills.length} مهارة نشطة',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (nearCompletion > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '$nearCompletion مهارة قريبة من الإكمال (>70%)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips(GlobalLearningState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // الكل
          FilterChip(
            label: const Text('كل المجالات'),
            selected: _selectedFieldId == null,
            onSelected: (selected) {
              setState(() {
                _selectedFieldId = null;
              });
            },
          ),
          const SizedBox(width: 8),

          // المجال الأساسي
          if (state.primaryField != null) ...[
            FilterChip(
              label: Text(
                state.getFieldData(state.primaryField!)?.name ??
                    'المجال الأساسي',
              ),
              selected: _selectedFieldId == state.primaryField,
              onSelected: (selected) {
                setState(() {
                  _selectedFieldId = selected ? state.primaryField : null;
                });
              },
            ),
            const SizedBox(width: 8),
          ],

          // المجال الثانوي
          if (state.secondaryField != null) ...[
            FilterChip(
              label: Text(
                state.getFieldData(state.secondaryField!)?.name ??
                    'المجال الثانوي',
              ),
              selected: _selectedFieldId == state.secondaryField,
              onSelected: (selected) {
                setState(() {
                  _selectedFieldId = selected ? state.secondaryField : null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillCard(
    SkillProgress skillProgress,
    GlobalLearningState state,
  ) {
    final skillData = state.getSkillData(
      skillProgress.fieldId,
      skillProgress.skillId,
    );

    if (skillData == null) {
      return const SizedBox.shrink();
    }

    // حساب الكورسات
    final activeCourses =
        skillProgress.coursesProgress.values
            .where((c) => !c.isCompleted)
            .length;
    final completedCourses =
        skillProgress.coursesProgress.values.where((c) => c.isCompleted).length;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          AppNavigation.goToSkillDetails(
            skillProgress.fieldId,
            skillProgress.skillId,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة + عنوان
              Row(
                children: [
                  // أيقونة المهارة
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: SkillUtils.levelColor(
                        skillData.level,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        skillData.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // الاسم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skillData.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          skillData.nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: skillProgress.progressPercentage / 100,
                        minHeight: 8,
                        backgroundColor:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SkillUtils.levelColor(skillData.level),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${skillProgress.progressPercentage}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: SkillUtils.levelColor(skillData.level),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Level Badge + Importance
              Row(
                children: [
                  _buildLevelBadge(context, skillData.level),
                  const SizedBox(width: 12),
                  ..._buildImportanceStars(skillData.importance),
                ],
              ),

              const SizedBox(height: 12),

              // الكورسات
              Row(
                children: [
                  const Icon(Icons.school, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'الكورسات: $activeCourses نشط',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (completedCourses > 0) ...[
                    const Text(' | ', style: TextStyle(fontSize: 12)),
                    Text(
                      '$completedCourses مكتمل',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // تاريخ البدء
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'بدأت ${timeago.format(skillProgress.startedAt, locale: 'ar')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildImportanceStars(int importance) {
    final stars = (importance / 20).round().clamp(0, 5);
    return [
      ...List.generate(
        5,
        (i) => Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: Colors.amber,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        '($importance%)',
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
    ];
  }

  Widget _buildLevelBadge(BuildContext context, String level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = SkillUtils.levelBadgeColors(level, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        SkillUtils.levelShortLabel(level),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colors.text,
        ),
      ),
    );
  }

  List<SkillProgress> _sortSkills(
    List<SkillProgress> skills,
    GlobalLearningState state,
  ) {
    final sorted = List<SkillProgress>.from(skills);

    switch (_sortOption) {
      case _SortOption.importance:
        // pre-map الأهمية مرة واحدة قبل الـ sort
        final importanceMap = {
          for (final s in skills)
            s.skillId: state.getSkillData(s.fieldId, s.skillId)?.importance ?? 0
        };
        sorted.sort((a, b) =>
            (importanceMap[b.skillId] ?? 0)
                .compareTo(importanceMap[a.skillId] ?? 0));
        break;

      case _SortOption.progress:
        sorted.sort(
            (a, b) => a.progressPercentage.compareTo(b.progressPercentage));
        break;

      case _SortOption.level:
        // pre-map المستوى مرة واحدة قبل الـ sort
        final levelMap = {
          for (final s in skills)
            s.skillId:
                SkillUtils.levelIndex(
                  state.getSkillData(s.fieldId, s.skillId)?.level ?? 'foundation',
                )
        };
        sorted.sort((a, b) =>
            (levelMap[a.skillId] ?? 0)
                .compareTo(levelMap[b.skillId] ?? 0));
        break;

      case _SortOption.startDate:
        sorted.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        break;
    }

    return sorted;
  }

  void showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ترتيب حسب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              RadioListTile<_SortOption>(
                title: const Text('الأهمية (تنازلي)'),
                subtitle: const Text('الأكثر أهمية أولاً'),
                value: _SortOption.importance,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text('التقدم (تصاعدي)'),
                subtitle: const Text('الأقل تقدماً أولاً'),
                value: _SortOption.progress,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text('المستوى'),
                subtitle: const Text('من الأساسي إلى الخبير'),
                value: _SortOption.level,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text('تاريخ البدء'),
                subtitle: const Text('الأحدث أولاً'),
                value: _SortOption.startDate,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: 5,
      itemBuilder: (context, index) => const SkillCardSkeleton(),
    );
  }

  Widget _buildErrorState(String error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'حدث خطأ',
      subtitle: error,
      actions: [
        ElevatedButton(
          onPressed: () {
            final state = context.read<GlobalLearningState>();
            final userId = state.currentUserId;
            if (userId != null) {
              state.loadUserProfile(userId);
            }
          },
          child: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    // التمييز بين مستخدم جديد لم يبدأ بعد ومستخدم أكمل جميع مهاراته
    return Consumer<GlobalLearningState>(
      builder: (context, state, _) {
        final hasLearnedSkills = state.getLearnedSkills().isNotEmpty;

        if (hasLearnedSkills) {
          // المستخدم أكمل جميع مهاراته — رسالة احتفالية
          return EmptyStateWidget(
            icon: Icons.celebration,
            title: 'أحسنت! أكملت جميع مهاراتك 🎉',
            subtitle: 'يمكنك استكشاف مجالات جديدة لتوسيع معرفتك',
            actions: [
              ElevatedButton.icon(
                onPressed: () => AppNavigation.goToLearnedSkills(),
                icon: const Icon(Icons.check_circle),
                label: const Text('المهارات المتعلمة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => AppNavigation.goToMyFields(),
                icon: const Icon(Icons.explore),
                label: const Text('استكشف مجالات جديدة'),
              ),
            ],
          );
        } else {
          // مستخدم جديد لم يبدأ بعد
          return EmptyStateWidget(
            icon: Icons.school_outlined,
            title: 'لم تبدأ أي مهارة بعد',
            subtitle: 'ابدأ بتعلم أول مهارة في مجالك واحتل مكانك في خارطة التعلم',
            actions: [
              ElevatedButton.icon(
                onPressed: () => AppNavigation.goToMyFields(),
                icon: const Icon(Icons.map_outlined),
                label: const Text('خارطة التعلم'),
              ),
            ],
          );
        }
      },
    );
  }
}

enum _SortOption { importance, progress, level, startDate }
