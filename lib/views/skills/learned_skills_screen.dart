import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/global_learning_state.dart';
import '../../widgets/skill_card_skeleton.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/skill_utils.dart';
import '../../router.dart';

/// شاشة المهارات المتعلمة (التقدم ≥ 80%)
class LearnedSkillsScreen extends StatefulWidget {
  const LearnedSkillsScreen({super.key});

  @override
  State<LearnedSkillsScreen> createState() => _LearnedSkillsScreenState();
}

class _LearnedSkillsScreenState extends State<LearnedSkillsScreen> {
  _SortOption _sortOption = _SortOption.completionDate;

  // ── static لتجنب إنشاء DateFormat جديد في كل بطاقة ──────────────────────
  static final _dateFormat = DateFormat('d MMMM yyyy', 'ar');

  /// أحدث تاريخ إكمال كورس في المهارة — تُستخدم في الـ sort والعرض
  static DateTime? _getCompletionDate(SkillProgress skillProgress) {
    DateTime? latest;
    for (final course in skillProgress.coursesProgress.values) {
      if (course.completedAt != null) {
        if (latest == null || course.completedAt!.isAfter(latest)) {
          latest = course.completedAt;
        }
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          automaticallyImplyLeading: false,
          title: const Text('المهارات المتعلمة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptions,
              tooltip: 'ترتيب',
            ),
          ],
        ),
        body: Consumer<GlobalLearningState>(
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

            // جلب المهارات المتعلمة
            final learnedSkills = state.getLearnedSkills();

            if (learnedSkills.isEmpty) {
              return _buildEmptyState();
            }

            // ترتيب المهارات
            final sortedSkills = _sortSkills(learnedSkills, state);

            // حساب إجمالي الكورسات المكتملة عبر جميع المهارات
            final totalCompletedCourses = sortedSkills.fold<int>(
              0,
              (sum, skill) =>
                  sum +
                  skill.coursesProgress.values
                      .where((c) => c.isCompleted)
                      .length,
            );

            return RefreshIndicator(
              onRefresh: () => state.refreshCurrentUser(),
              child: Column(
                children: [
                  // Header Stats
                  _buildHeaderStats(sortedSkills.length, totalCompletedCourses),

                  // قائمة المهارات
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: sortedSkills.length,
                      itemBuilder: (context, index) {
                        return _buildLearnedSkillCard(
                          sortedSkills[index],
                          state,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderStats(int skillsCount, int totalCompletedCourses) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, size: 24, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'أكملت $skillsCount مهارة حتى الآن!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'إجمالي الكورسات المكتملة: $totalCompletedCourses',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearnedSkillCard(
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

    // حساب عدد الكورسات المكتملة
    final completedCourses =
        skillProgress.coursesProgress.values.where((c) => c.isCompleted).length;

    // حساب تاريخ الإكمال (أحدث completedAt)
    final completionDate = _getCompletionDate(skillProgress);
    final completionText =
        completionDate != null
            ? _dateFormat.format(completionDate)
            : 'تاريخ غير معروف';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.green[700]!
                  : Colors.green[200]!,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.green[900]!.withOpacity(0.3)
                  : Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
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
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Center(
                            child: Text(
                              skillData.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
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
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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

                // Progress Bar (أخضر)
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
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${skillProgress.progressPercentage}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // تاريخ الإكمال
                Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'مكتملة في: $completionText',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // عدد الكورسات المكتملة
                Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'عدد الكورسات المكتملة: $completedCourses',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // المستوى
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'المستوى: ${SkillUtils.levelShortLabel(skillData.level)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // زر مراجعة
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppNavigation.goToSkillDetails(
                        skillProgress.fieldId,
                        skillProgress.skillId,
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('مراجعة المهارة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      case _SortOption.completionDate:
        // pre-compute تواريخ الإكمال مرة واحدة قبل الـ sort
        final dateMap = {
          for (final s in skills) s.skillId: _getCompletionDate(s),
        };
        sorted.sort((a, b) {
          final dateA = dateMap[a.skillId];
          final dateB = dateMap[b.skillId];
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
        break;

      case _SortOption.percentage:
        sorted.sort(
          (a, b) => b.progressPercentage.compareTo(a.progressPercentage),
        );
        break;

      case _SortOption.coursesCount:
        // pre-compute عدد الكورسات المكتملة مرة واحدة قبل الـ sort
        final countMap = {
          for (final s in skills)
            s.skillId:
                s.coursesProgress.values.where((c) => c.isCompleted).length,
        };
        sorted.sort(
          (a, b) =>
              (countMap[b.skillId] ?? 0).compareTo(countMap[a.skillId] ?? 0),
        );
        break;

      case _SortOption.level:
        // pre-map المستوى مرة واحدة قبل الـ sort
        // الترتيب: expert أولاً ← foundation أخيراً (تنازلي)
        final levelMap = {
          for (final s in skills)
            s.skillId: SkillUtils.levelIndex(
              state.getSkillData(s.fieldId, s.skillId)?.level ?? 'foundation',
            ),
        };
        sorted.sort(
          (a, b) =>
              (levelMap[b.skillId] ?? 0).compareTo(levelMap[a.skillId] ?? 0),
        );
        break;
    }

    return sorted;
  }

  void _showSortOptions() {
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
                title: const Text('تاريخ الإكمال'),
                subtitle: const Text('الأحدث أولاً'),
                value: _SortOption.completionDate,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text('النسبة'),
                subtitle: const Text('الأعلى أولاً'),
                value: _SortOption.percentage,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text('عدد الكورسات'),
                subtitle: const Text('الأكثر أولاً'),
                value: _SortOption.coursesCount,
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
                subtitle: const Text('من الخبير إلى الأساسي'),
                value: _SortOption.level,
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
    return const EmptyStateWidget(
      icon: Icons.school,
      title: 'لم تكمل أي مهارة بعد!',
      subtitle: 'استمر في التعلم لتحقيق أول إنجاز لك! 💪',
    );
  }
}

enum _SortOption { completionDate, percentage, coursesCount, level }
