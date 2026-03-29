import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/course_model.dart';
import '../../router.dart';
import '../../widgets/course_card_skeleton.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/duration_parser.dart';

/// شاشة الكورسات المكتملة
class CompletedCoursesScreen extends StatefulWidget {
  const CompletedCoursesScreen({super.key});

  @override
  State<CompletedCoursesScreen> createState() => _CompletedCoursesScreenState();
}

class _CompletedCoursesScreenState extends State<CompletedCoursesScreen> {
  _SortOption _sortOption = _SortOption.completionDate;

  // ── static لتجنب إنشاء DateFormat جديد في كل بطاقة ──────────────────────
  static final _dateFormat = DateFormat('d MMMM yyyy', 'ar');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          automaticallyImplyLeading: false,
          title: const Text('الكورسات المكتملة'),
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

            // جلب الكورسات المكتملة
            var completedCourses = state.getCompletedCourses();

            if (completedCourses.isEmpty) {
              return _buildEmptyState();
            }

            // ترتيب الكورسات
            completedCourses = _sortCourses(completedCourses, state);

            // حساب الإحصائيات
            final stats = _calculateStats(completedCourses, state);

            return RefreshIndicator(
              onRefresh: () => state.refreshCurrentUser(),
              child: Column(
                children: [
                  // Header Stats + Celebration
                  _buildCelebrationHeader(stats),

                  // قائمة الكورسات
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: completedCourses.length,
                      itemBuilder: (context, index) {
                        return _buildCompletedCourseCard(
                          completedCourses[index],
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

  Widget _buildCelebrationHeader(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[400]!,
            Colors.green[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.celebration,
                size: 28,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'أكملت ${stats['count']} كورساً! عمل رائع!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 20,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                'إجمالي ساعات التعلم: ${stats['hours']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (stats['avgRating'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 20,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'معدل التقييم: ${stats['avgRating']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedCourseCard(
    CourseProgress courseProgress,
    GlobalLearningState state,
  ) {
    final courseData = state.getCourseData(
      courseProgress.fieldId,
      courseProgress.skillId,
      courseProgress.courseId,
    );

    if (courseData == null) {
      return const SizedBox.shrink();
    }

    final completionText = courseProgress.completedAt != null
        ? _dateFormat.format(courseProgress.completedAt!)
        : 'تاريخ غير معروف';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[700]!
              : Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[900]!.withOpacity(0.3)
              : Colors.green[50],
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
                // Logo + عنوان + علامة إكمال
                Row(
                  children: [
                    // علامة الإكمال
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
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
                            '${courseData.instructor} • ${courseData.platform}',
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

                // تاريخ الإكمال
                Row(
                  children: [
                    const Icon(Icons.event_available, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'أكملته في: $completionText',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // المدة
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'المدة: ${courseData.duration}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // التقييم
                _buildRatingRow(courseProgress, state),

                const SizedBox(height: 8),

                // الشهادة
                if (courseData.hasCertificate) ...[
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'شهادة متاحة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 4),

                // الأزرار
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          AppNavigation.goToCourseDetails(
                            courseProgress.fieldId,
                            courseProgress.skillId,
                            courseProgress.courseId,
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('مراجعة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    if (courseData.hasCertificate) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openCertificate(courseData),
                          icon: const Icon(Icons.card_membership, size: 16),
                          label: const Text('الشهادة'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber[700],
                            side: BorderSide(color: Colors.amber[700]!),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _shareCourse(courseData),
                      icon: const Icon(Icons.share, size: 20),
                      tooltip: 'مشاركة',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(CourseProgress courseProgress, GlobalLearningState state) {
    if (courseProgress.userRating != null) {
      // عرض التقييم الموجود
      return Row(
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            'تقييمك: ',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          ...List.generate(5, (index) {
            return Icon(
              index < (courseProgress.userRating ?? 0)
                  ? Icons.star
                  : Icons.star_border,
              size: 16,
              color: Colors.amber,
            );
          }),
        ],
      );
    } else {
      // طلب التقييم
      return InkWell(
        onTap: () => _showRatingDialog(courseProgress, state),
        child: Row(
          children: [
            Icon(Icons.star_border, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'قيّم الكورس',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showRatingDialog(
    CourseProgress courseProgress,
    GlobalLearningState state,
  ) async {
    double rating = 5.0;

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('قيّم هذا الكورس'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ما رأيك في هذا الكورس؟'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = (index + 1).toDouble();
                          });
                        },
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, rating),
                  child: const Text('تقييم'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await state.rateCourse(
        fieldId: courseProgress.fieldId,
        skillId: courseProgress.skillId,
        courseId: courseProgress.courseId,
        rating: result,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شكراً لتقييمك!')),
        );
      }
    }
  }

  Future<void> _openCertificate(CourseModel courseData) async {
    // فتح رابط الشهادة (يمكن تحسينه لاحقاً)
    final uri = Uri.parse(courseData.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل فتح رابط الشهادة')),
        );
      }
    }
  }

  Future<void> _shareCourse(CourseModel courseData) async {
    await Share.share(
      'أكملت كورس "${courseData.title}" على ${courseData.platform}! 🎉',
      subject: 'إنجاز جديد في التعلم',
    );
  }

  Map<String, dynamic> _calculateStats(
    List<CourseProgress> courses,
    GlobalLearningState state,
  ) {
    double totalHours = 0;
    int ratedCount = 0;
    double totalRating = 0;

    for (final course in courses) {
      final courseData = state.getCourseData(
        course.fieldId,
        course.skillId,
        course.courseId,
      );

      if (courseData != null) {
        final studyMins = course.totalStudyMinutes;
        totalHours += studyMins > 0
            ? studyMins / 60.0
            : DurationParser.parseToHours(courseData.duration);
      }

      if (course.userRating != null) {
        totalRating += course.userRating!;
        ratedCount++;
      }
    }

    return {
      'count': courses.length,
      'hours': DurationParser.hoursToText(totalHours),
      'avgRating': ratedCount > 0
          ? '⭐ ${(totalRating / ratedCount).toStringAsFixed(1)}'
          : null,
    };
  }

  List<CourseProgress> _sortCourses(
    List<CourseProgress> courses,
    GlobalLearningState state,
  ) {
    final sorted = List<CourseProgress>.from(courses);

    switch (_sortOption) {
      case _SortOption.completionDate:
        sorted.sort((a, b) {
          if (a.completedAt == null && b.completedAt == null) return 0;
          if (a.completedAt == null) return 1;
          if (b.completedAt == null) return -1;
          return b.completedAt!.compareTo(a.completedAt!);
        });
        break;

      case _SortOption.rating:
        sorted.sort((a, b) {
          if (a.userRating == null && b.userRating == null) return 0;
          if (a.userRating == null) return 1;
          if (b.userRating == null) return -1;
          return b.userRating!.compareTo(a.userRating!);
        });
        break;

      case _SortOption.platform:
        // pre-map المنصة مرة واحدة قبل الـ sort
        final platformMap = {
          for (final c in courses)
            c.courseId:
                state.getCourseData(c.fieldId, c.skillId, c.courseId)?.platform ?? ''
        };
        sorted.sort((a, b) =>
            (platformMap[a.courseId] ?? '')
                .compareTo(platformMap[b.courseId] ?? ''));
        break;

      case _SortOption.duration:
        // pre-map المدة بالساعات مرة واحدة قبل الـ sort
        final durationMap = {
          for (final c in courses)
            c.courseId: DurationParser.parseToHours(
              state.getCourseData(c.fieldId, c.skillId, c.courseId)?.duration ?? '0',
            )
        };
        sorted.sort((a, b) =>
            (durationMap[b.courseId] ?? 0)
                .compareTo(durationMap[a.courseId] ?? 0));
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                title: const Text('التقييم'),
                subtitle: const Text('الأعلى أولاً'),
                value: _SortOption.rating,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text('المنصة'),
                value: _SortOption.platform,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text('المدة'),
                subtitle: const Text('الأطول أولاً'),
                value: _SortOption.duration,
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
      title: 'لم تكمل أي كورس بعد!',
      subtitle: 'أنهِ أول كورس لك وابدأ رحلة الإنجازات! 🚀',
    );
  }
}

enum _SortOption {
  completionDate,
  rating,
  platform,
  duration,
}