import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/course_model.dart';
import '../../router.dart';
import '../../widgets/course_card_skeleton.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/duration_parser.dart';

/// شاشة الكورسات الجارية (غير المكتملة)
class ActiveCoursesScreen extends StatefulWidget {
  final bool embedded;
  
  const ActiveCoursesScreen({
    super.key,
    this.embedded = false,
  });
  
  @override
  State<ActiveCoursesScreen> createState() => ActiveCoursesScreenState();
}

// public State لتمكين الاستدعاء من FieldsHubScreen
class ActiveCoursesScreenState extends State<ActiveCoursesScreen> {
  String? _selectedPlatform; // null = الكل
  String? _selectedPrice; // null = الكل
  _SortOption _sortOption = _SortOption.lastAccess;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildContent();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الكورسات الجارية'),
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
          AppNavigation.goToCompletedCourses();
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('الكورسات المكتملة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 3. استخراج المحتوى
  Widget _buildContent() {
    return Consumer<GlobalLearningState>(
      builder: (context, state, child) {
        if (state.isLoadingUserProfile) {
          return _buildLoadingState();
        }

        if (state.lastError != null) {
          return _buildErrorState(state.lastError!);
        }

        if (!state.hasUserProfile) {
          return const EmptyStateWidget(
            icon: Icons.person_off,
            title: 'لا يوجد ملف تعريفي',
            subtitle: 'الرجاء تسجيل الدخول أولاً',
          );
        }

        var activeCourses = state.getActiveCourses();

        // بناء Map للبيانات الثابتة مرة واحدة — يُستخدم في الفلتر والترتيب والإحصائيات
        final courseDataMap = {
          for (final c in activeCourses)
            c.courseId: state.getCourseData(c.fieldId, c.skillId, c.courseId)
        };

        activeCourses = _applyFilters(activeCourses, courseDataMap);

        if (activeCourses.isEmpty) {
          return _buildEmptyState();
        }

        final totalHours = _calculateTotalHours(activeCourses, courseDataMap);
        activeCourses = _sortCourses(activeCourses, state, courseDataMap);

        final groupedCourses = groupBy<CourseProgress, String>(
          activeCourses,
          (course) => course.skillId,
        );

        return RefreshIndicator(
          onRefresh: () => state.refreshCurrentUser(),
          child: Column(
            children: [
              _buildHeaderStats(activeCourses.length, totalHours),
              if (!widget.embedded) _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: groupedCourses.length,
                  itemBuilder: (context, index) {
                    final skillId = groupedCourses.keys.elementAt(index);
                    final courses = groupedCourses[skillId]!;
                    return _buildSkillGroup(skillId, courses, state);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderStats(int coursesCount, double totalHours) {
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
              const Icon(Icons.school, size: 20),
              const SizedBox(width: 8),
              Text(
                'لديك $coursesCount كورس جاري',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'إجمالي ساعات التعلم: ${DurationParser.hoursToText(totalHours)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// استخراج المنصات المتاحة ديناميكياً من الكورسات الفعلية
  List<String> _getAvailablePlatforms(GlobalLearningState state) {
    final platforms = state
        .getActiveCourses()
        .map((c) => state.getCourseData(c.fieldId, c.skillId, c.courseId)?.platform)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return platforms;
  }

  Widget _buildFilterChips() {
    return Consumer<GlobalLearningState>(
      builder: (context, state, _) {
        final platforms = _getAvailablePlatforms(state);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('الكل'),
                selected: _selectedPlatform == null && _selectedPrice == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedPlatform = null;
                    _selectedPrice = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              // منصات ديناميكية
              ...platforms.map((platform) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(platform),
                  selected: _selectedPlatform == platform,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPlatform = selected ? platform : null;
                    });
                  },
                ),
              )),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('مجاني'),
                selected: _selectedPrice == 'free',
                onSelected: (selected) {
                  setState(() {
                    _selectedPrice = selected ? 'free' : null;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('مدفوع'),
                selected: _selectedPrice == 'paid',
                onSelected: (selected) {
                  setState(() {
                    _selectedPrice = selected ? 'paid' : null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillGroup(
      String skillId, List<CourseProgress> courses, GlobalLearningState state) {
    // جلب معلومات المهارة
    final fieldId = courses.first.fieldId;
    final skillData = state.getSkillData(fieldId, skillId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.label, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${skillData?.name ?? 'مهارة'} (${courses.length} كورس)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // الكورسات
        ...courses.map((course) => _buildCourseCard(course, state)),
      ],
    );
  }

  Widget _buildCourseCard(CourseProgress courseProgress, GlobalLearningState state) {
    final courseData = state.getCourseData(
      courseProgress.fieldId,
      courseProgress.skillId,
      courseProgress.courseId,
    );

    if (courseData == null) {
      return const SizedBox.shrink();
    }

    final progress = courseProgress.totalLessons > 0
        ? courseProgress.completedLessons.length / courseProgress.totalLessons
        : 0.0;

    return Slidable(
      key: ValueKey(courseProgress.courseId),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (_) => _handleLearningSession(courseProgress, courseData, state),
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            icon: Icons.timer,
            label: 'جلسة تعلم',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            AppNavigation.goToCourseDetails(
              courseProgress.fieldId,
              courseProgress.skillId,
              courseProgress.courseId,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + عنوان
                Row(
                  children: [
                    // Logo المنصة
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPlatformColor(courseData.platform),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getPlatformIcon(courseData.platform),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // العنوان
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseData.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${courseData.instructor} • ${courseData.platform} • ${courseData.duration}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // معلومات الدرس
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'الدرس ${courseProgress.currentLessonIndex} من ${courseProgress.totalLessons}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(courseProgress.lastAccessedAt, locale: 'ar'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _continueLearning(courseProgress, courseData, state),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('متابعة التعلم'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: 'علّم درساً كمكتمل',
                      color: const Color(0xFF6C63FF),
                      onPressed: () => _quickMarkLesson(courseProgress, state),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  void _quickMarkLesson(CourseProgress courseProgress, GlobalLearningState state) {
    final courseData = state.getCourseData(
      courseProgress.fieldId,
      courseProgress.skillId,
      courseProgress.courseId,
    );
    final duration = courseData?.duration ?? '';
    final totalHours = DurationParser.parseToHours(duration);
    final totalLessons = courseProgress.totalLessons.clamp(1, 40);
    final minutesPerLesson =
        ((totalHours * 60) / totalLessons).clamp(20.0, 180.0);

    bool canMarkLesson(int index) {
      if (courseProgress.completedLessons.contains(index)) return false;
      if (courseProgress.completedLessons.isEmpty) return index == 0;
      final nextExpected =
          courseProgress.completedLessons.reduce((a, b) => a > b ? a : b) + 1;
      if (index != nextExpected) return false;
      final minutesElapsed =
          DateTime.now().difference(courseProgress.lastAccessedAt).inMinutes;
      return minutesElapsed >= minutesPerLesson;
    }

    String lockReason(int index) {
      final nextExpected = courseProgress.completedLessons.isEmpty
          ? 0
          : courseProgress.completedLessons.reduce((a, b) => a > b ? a : b) + 1;
      if (index != nextExpected) return 'أكمل الدروس السابقة أولاً';
      final minutesElapsed =
          DateTime.now().difference(courseProgress.lastAccessedAt).inMinutes;
      final remaining = (minutesPerLesson - minutesElapsed).ceil();
      if (remaining <= 0) return '';
      if (remaining < 60) return 'متاح بعد $remaining دقيقة';
      final h = remaining ~/ 60;
      final m = remaining % 60;
      return m > 0 ? 'متاح بعد $hس $mد' : 'متاح بعد $h ساعة';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اختر الدرس المكتمل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // زر الدرس التالي
                if (courseProgress.currentLessonIndex < courseProgress.totalLessons)
                  Builder(builder: (context) {
                    final nextIndex = courseProgress.currentLessonIndex;
                    final canMark = canMarkLesson(nextIndex);
                    final reason = canMark ? '' : lockReason(nextIndex);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(canMark ? Icons.fast_forward : Icons.lock),
                          label: Text(
                              'الدرس ${courseProgress.currentLessonIndex + 1} (التالي)'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor:
                                canMark ? const Color(0xFF6C63FF) : Theme.of(context).disabledColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: canMark
                              ? () async {
                                  Navigator.pop(ctx);
                                  await _markLessonFromCard(
                                      courseProgress, nextIndex, state);
                                }
                              : null,
                        ),
                        if (reason.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '🔒 $reason',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Theme.of(context).colorScheme.outline),
                            ),
                          ),
                      ],
                    );
                  }),
                const SizedBox(height: 8),
                const Divider(),
                const Text('أو اختر درساً آخر:'),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: courseProgress.totalLessons,
                    itemBuilder: (_, index) {
                      if (courseProgress.completedLessons.contains(index)) {
                        return const SizedBox.shrink();
                      }
                      final canMark = canMarkLesson(index);
                      final reason = canMark ? '' : lockReason(index);
                      return ListTile(
                        leading: Icon(
                          canMark
                              ? Icons.play_circle_outline
                              : Icons.lock_outline,
                          color: canMark
                              ? const Color(0xFF6C63FF)
                              : Theme.of(context).colorScheme.outline,
                        ),
                        title: Text('الدرس ${index + 1}'),
                        subtitle: !canMark && reason.isNotEmpty
                            ? Text(
                                '🔒 $reason',
                                style: TextStyle(
                                    fontSize: 11, color: Theme.of(context).colorScheme.outline),
                              )
                            : null,
                        onTap: canMark
                            ? () async {
                                Navigator.pop(ctx);
                                await _markLessonFromCard(
                                    courseProgress, index, state);
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markLessonFromCard(
    CourseProgress courseProgress,
    int lessonIndex,
    GlobalLearningState state,
  ) async {
    try {
      await state.markLessonAsCompleted(
        fieldId: courseProgress.fieldId,
        skillId: courseProgress.skillId,
        courseId: courseProgress.courseId,
        lessonIndex: lessonIndex,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ أحسنت! استمر 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _handleLearningSession(
    CourseProgress courseProgress,
    CourseModel courseData,
    GlobalLearningState state,
  ) async {
    // حساب دقائق لكل درس
    final totalHours = DurationParser.parseToHours(courseData.duration);
    final totalLessons = courseProgress.totalLessons.clamp(1, 40);
    final minutesPerLesson = ((totalHours * 60) / totalLessons)
        .clamp(10.0, 180.0)
        .round();

    final result = await state.recordLearningSession(
      fieldId: courseProgress.fieldId,
      skillId: courseProgress.skillId,
      courseId: courseProgress.courseId,
      estimatedMinutesPerLesson: minutesPerLesson,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.hasNewLessons ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(result.message)),
          ],
        ),
        backgroundColor: result.hasNewLessons
            ? Colors.green
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _continueLearning(
    CourseProgress courseProgress,
    CourseModel courseData,
    GlobalLearningState state,
  ) async {
    // تسجيل الدخول
    await state.recordCourseAccess(
      fieldId: courseProgress.fieldId,
      skillId: courseProgress.skillId,
      courseId: courseProgress.courseId,
    );

    // فتح الرابط
    final uri = Uri.parse(courseData.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم فتح الكورس')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل فتح الرابط')),
        );
      }
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Colors.red;
      case 'udemy':
        return Colors.purple;
      case 'coursera':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_filled;
      case 'udemy':
        return Icons.school;
      case 'coursera':
        return Icons.menu_book;
      default:
        return Icons.link;
    }
  }

  List<CourseProgress> _applyFilters(
    List<CourseProgress> courses,
    Map<String, CourseModel?> courseDataMap,
  ) {
    return courses.where((course) {
      final courseData = courseDataMap[course.courseId];

      if (courseData == null) return false;

      if (_selectedPlatform != null &&
          courseData.platform != _selectedPlatform) {
        return false;
      }

      if (_selectedPrice != null && courseData.price != _selectedPrice) {
        return false;
      }

      return true;
    }).toList();
  }

  List<CourseProgress> _sortCourses(
    List<CourseProgress> courses,
    GlobalLearningState state,
    Map<String, CourseModel?> courseDataMap,
  ) {
    final sorted = List<CourseProgress>.from(courses);

    switch (_sortOption) {
      case _SortOption.lastAccess:
        sorted.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
        break;
      case _SortOption.startDate:
        sorted.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        break;
      case _SortOption.progress:
        sorted.sort((a, b) {
          // حماية من division by zero
          final progressA = a.totalLessons > 0
              ? a.completedLessons.length / a.totalLessons
              : 0.0;
          final progressB = b.totalLessons > 0
              ? b.completedLessons.length / b.totalLessons
              : 0.0;
          return progressA.compareTo(progressB);
        });
        break;
      case _SortOption.skill:
        // pre-map أسماء المهارات مرة واحدة قبل الـ sort
        final skillNames = {
          for (final c in courses)
            c.courseId:
                state.getSkillData(c.fieldId, c.skillId)?.name ?? c.skillId
        };
        sorted.sort((a, b) {
          return (skillNames[a.courseId] ?? '')
              .compareTo(skillNames[b.courseId] ?? '');
        });
        break;
    }

    return sorted;
  }

  double _calculateTotalHours(
    List<CourseProgress> courses,
    Map<String, CourseModel?> courseDataMap,
  ) {
    double total = 0;
    for (final course in courses) {
      final courseData = courseDataMap[course.courseId];
      if (courseData != null) {
        total += DurationParser.parseToHours(courseData.duration);
      }
    }
    return total;
  }

  // public لتمكين الاستدعاء من FieldsHubScreen
  // ignore: library_private_types_in_public_api
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RadioListTile<_SortOption>(
                title: const Text('آخر وصول'),
                subtitle: const Text('الأحدث أولاً'),
                value: _SortOption.lastAccess,
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
              RadioListTile<_SortOption>(
                title: const Text('التقدم'),
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
                title: const Text('حسب المهارة'),
                value: _SortOption.skill,
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
      itemBuilder: (context, index) => const CourseCardSkeleton(),
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
      title: 'لم تبدأ أي كورس بعد!',
      subtitle: 'استكشف الكورسات المتاحة في المهارات والمجالات',
    );
  }
}

enum _SortOption {
  lastAccess,
  startDate,
  progress,
  skill,
}