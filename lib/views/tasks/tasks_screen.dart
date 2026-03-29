import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/task_controller.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/task_model.dart';
import '../../router.dart';
import 'add_custom_task_screen.dart';
import 'custom_task_details_screen.dart';
import '../../widgets/task_cards.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TasksScreen
// ══════════════════════════════════════════════════════════════════════════════

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المهام',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          tabs: [
            _buildTab(icon: Icons.school_outlined, label: 'دراسية'),
            _buildTab(icon: Icons.star_outline, label: 'مهارات'),
            _buildTab(icon: Icons.checklist_outlined, label: 'مخصصة'),
          ],
        ),
      ),
      body: Consumer<TaskController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.dailyTasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // [FIX] لا Scaffold داخل TabBarView — كان يسبب تضارب FAB و MediaQuery
          // على بعض الأجهزة. الـ FAB الآن خارج TabBarView بالكامل.
          return Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _DailyTasksTab(controller: controller),
                  _SkillTasksTab(controller: controller),
                  _CustomTasksTab(controller: controller),
                ],
              ),

              // [FIX] FAB خارج TabBarView — يظهر فقط عند تبويب "مخصصة"
              // نستخدم animation.value بدل index لأن index لا يتغير أثناء السحب
              // مما كان يُسبب تأخير ثانية في الظهور/الاختفاء عند swipe
              AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, _) {
                  // animation.value = 2.0 عند التبويب الثالث (index 2)
                  // نحسب المسافة عن index 2 ونُظهر الـ FAB فقط عند الاقتراب منه
                  final animValue = _tabController.animation!.value;
                  final distanceFromTab2 = (animValue - 2.0).abs();
                  // نُظهره عند < 0.5 (أي المستخدم في منتصف السحب نحو التبويب)
                  if (distanceFromTab2 >= 0.5) return const SizedBox.shrink();
                  // opacity تدريجي حسب قرب التبويب
                  final opacity = (1.0 - distanceFromTab2 * 2).clamp(0.0, 1.0);
                  return Positioned(
                    bottom: 16,
                    left: 16,
                    child: Opacity(
                      opacity: opacity,
                      child: FloatingActionButton.extended(
                        heroTag: 'add_custom_task',
                        onPressed:
                            opacity < 0.5
                                ? null
                                : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddCustomTaskScreen(),
                                  ),
                                ),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة مهمة'),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Tab _buildTab({required IconData icon, required String label}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 1 — المهام الدراسية
// ══════════════════════════════════════════════════════════════════════════════

class _DailyTasksTab extends StatelessWidget {
  const _DailyTasksTab({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.dailyTasks;

    if (tasks.isEmpty) {
      return const _EmptyState(
        emoji: '🎉',
        title: 'لا توجد مهام اليوم!',
        subtitle: 'استمتع بوقتك',
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.forceDailySync(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];

          if (task.type == TaskType.lecture) {
            // [FIX] guard زمني — تعطيل أزرار الحضور قبل موعد المحاضرة.
            // upcoming = الموعد لم يحن → onAttendance: null يعطّل الأزرار في الـ Card
            final canRecord =
                task.status != TaskStatus.upcoming &&
                task.status != TaskStatus.completed;
            return LectureTaskCard(
              task: task,
              onAttendance:
                  canRecord
                      ? (status) => _showAttendanceSheet(context, task, status)
                      : null,
            );
          }

          if (task.type == TaskType.studySession) {
            // [FIX] guard زمني:
            // onStarted  : فقط عند ongoing
            // onCompleted: عند ongoing أو missed
            final isUpcoming = task.status == TaskStatus.upcoming;
            final isCompleted = task.status == TaskStatus.completed;
            return StudySessionTaskCard(
              task: task,
              onStarted:
                  (!isUpcoming && !isCompleted)
                      ? () => controller.updateStudySessionStatus(
                        taskId: task.id,
                        newStatus: StudySessionTaskStatus.started,
                      )
                      : null,
              onCompleted:
                  (!isUpcoming && !isCompleted)
                      ? () => _showStudySessionCompletionSheet(
                        context,
                        task,
                        controller,
                      )
                      : null,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // [FIX] _showAttendanceSheet ينتظر إغلاق الـ Sheet قبل تسجيل الحضور —
  // كانت تُستدعى بدون await فلا يوجد loading indicator ولا error handling.
  // الآن onSave تُغلق الـ sheet أولاً ثم تسجّل، وأي خطأ يظهر كـ SnackBar.
  Future<void> _showAttendanceSheet(
    BuildContext context,
    TaskModel task,
    LectureAttendanceStatus status,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => _AttendanceBottomSheet(
            task: task,
            initialStatus: status,
            onSave: (savedStatus, rating, lateMinutes, notes) async {
              Navigator.pop(ctx);

              try {
                await context.read<TaskController>().recordLectureAttendance(
                  taskId: task.id,
                  attendanceStatus: savedStatus,
                  understandingRating: rating,
                  lateMinutes: lateMinutes,
                  notes: notes,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل تسجيل الحضور: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Study Session Completion Sheet
// ══════════════════════════════════════════════════════════════════════════════

void _showStudySessionCompletionSheet(
  BuildContext context,
  TaskModel task,
  TaskController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (ctx) => _StudySessionCompletionSheet(
          task: task,
          onSave: (understandingRating, notes) async {
            Navigator.pop(ctx);
            try {
              await controller.updateStudySessionStatus(
                taskId: task.id,
                newStatus: StudySessionTaskStatus.completed,
                understandingRating: understandingRating,
                notes: notes,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل تسجيل الجلسة: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 2 — مهام المهارات
// ══════════════════════════════════════════════════════════════════════════════

class _SkillTasksTab extends StatelessWidget {
  const _SkillTasksTab({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.courseTasks;

    if (tasks.isEmpty) {
      return _EmptyState(
        emoji: '📚',
        title: 'لا توجد كورسات نشطة',
        subtitle: 'ابدأ كورساً جديداً من المجالات',
        actionLabel: 'اذهب للمجالات',
        onAction: () => AppNavigation.goToMyFields(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return SkillCourseTaskCard(
          task: task,
          onStart: () {
            final learningState = context.read<GlobalLearningState>();
            final courseData = learningState.getCourseData(
              task.fieldId ?? '',
              task.skillId ?? '',
              task.courseId ?? '',
            );
            if (courseData != null) {
              AppNavigation.goToCourseDetails(
                task.fieldId ?? '',
                task.skillId ?? '',
                task.courseId ?? '',
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعذّر فتح الكورس، حاول مجدداً')),
              );
            }
          },
          onComplete: () => _confirmMarkCurrentLesson(context, task),
        );
      },
    );
  }

  // نظام المجالات يتحكم بالترتيب والقفل، لذا نؤكد فقط إكمال الدرس الحالي.
  void _confirmMarkCurrentLesson(BuildContext context, TaskModel task) {
    final currentLesson = task.currentLesson ?? 1;
    final total = task.totalLessons ?? 1;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'إكمال الدرس $currentLesson من $total',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                task.courseTitle ?? task.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'هل أكملت مشاهدة هذا الدرس؟',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('لاحقاً'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final learningState =
                            context.read<GlobalLearningState>();
                        final checkResult = learningState.checkLessonAllowed(
                          task.fieldId ?? '',
                          task.skillId ?? '',
                        );
 
                        if (checkResult == LessonCheckResult.dailyBlocked) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'أكملت حصتك اليومية — عُد غداً لمواصلة التعلم 💪',
                                ),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(12),
                              ),
                            );
                          }
                          return;
                        }
 
                        if (checkResult == LessonCheckResult.weeklyBlocked) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'أكملت أيام تعلمك هذا الأسبوع — ابدأ من جديد الأسبوع القادم 🗓️',
                                ),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(12),
                              ),
                            );
                          }
                          return;
                        }

                        // تحذيرات (لا تمنع — فقط تنبّه)
                        if (checkResult == LessonCheckResult.dailyWarning) {
                          learningState.markDailyWarningSent(
                            task.fieldId ?? '',
                            task.skillId ?? '',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'وصلت للحد اليومي — إذا تجاوزته سيُمنع التعليم لبقية اليوم ⚠️',
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(12),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }

                        if (checkResult == LessonCheckResult.weeklyWarning) {
                          learningState.markWeeklyWarningSent(
                            task.fieldId ?? '',
                            task.skillId ?? '',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'وصلت للحد الأسبوعي — إذا تجاوزته سيُمنع التعليم حتى الأسبوع القادم ⚠️',
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(12),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }

                        // تنفيذ التعليم
                        try {
                          final tc = context.read<TaskController>();
                          await tc.markCurrentLesson(taskId: task.id);
                          if (tc.error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tc.error!),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('فشل تسجيل الدرس: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('نعم، أكملته'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 3 — المهام المخصصة
// ══════════════════════════════════════════════════════════════════════════════

// [FIX] أُزيل Scaffold الداخلي الذي كان يُسبب تضارب FAB و MediaQuery.
// الـ FAB انتقل إلى TasksScreen مباشرةً كـ Positioned widget.
class _CustomTasksTab extends StatelessWidget {
  const _CustomTasksTab({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.customTasks;

    if (tasks.isEmpty) {
      return const _EmptyState(
        emoji: '📌',
        title: 'لا توجد مهام مخصصة',
        subtitle: 'أضف مهامك الشخصية باستخدام الزر أدناه',
      );
    }

    return ListView.builder(
      // padding سفلي إضافي حتى لا يختبئ آخر عنصر خلف الـ FAB
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return CustomTaskCard(
          task: task,
          onDetails:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailsScreen(task: task),
                ),
              ),
          // المهمة الدورية لا تُكتمَل — نُخفي الزر بتمرير null
          onComplete: task.isRecurring
              ? null
              : () async {
                  try {
                    await controller.completeCustomTask(task.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل إكمال المهمة: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          onDelete: () => _confirmDelete(context, task.id),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String taskId) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('حذف المهمة'),
            content: const Text('هل أنت متأكد من حذف هذه المهمة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                // [FIX] await + error handling — الكود القديم لا ينتظر الحذف
                // ولا يعرض أي خطأ للمستخدم عند الفشل
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await context.read<TaskController>().deleteCustomTask(
                      taskId,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل حذف المهمة: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('حذف'),
              ),
            ],
          ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Study Session Completion Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _StudySessionCompletionSheet extends StatefulWidget {
  const _StudySessionCompletionSheet({
    required this.task,
    required this.onSave,
  });

  final TaskModel task;
  final Future<void> Function(int understandingRating, String? notes) onSave;

  @override
  State<_StudySessionCompletionSheet> createState() =>
      _StudySessionCompletionSheetState();
}

class _StudySessionCompletionSheetState
    extends State<_StudySessionCompletionSheet> {
  int _understanding = 3;
  bool _isSaving = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // العنوان
          Text(
            widget.task.subjectName ?? widget.task.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (widget.task.formattedTimeSlot.isNotEmpty)
            Text(
              widget.task.formattedTimeSlot,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 20),

          // تقييم الفهم
          Text(
            'كيف كان مستوى فهمك في هذه الجلسة؟',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _understanding = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _understanding ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _understandingLabel(_understanding),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ملاحظات
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'ملاحظات (اختياري) — مثال: احتاج مراجعة الفصل الثالث',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            maxLines: 2,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),

          // زر الحفظ
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed:
                  _isSaving
                      ? null
                      : () async {
                        setState(() => _isSaving = true);
                        await widget.onSave(
                          _understanding,
                          _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                        );
                      },
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? 'جاري الحفظ...' : 'تسجيل الإكمال'),
            ),
          ),
        ],
      ),
    );
  }

  String _understandingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'لم أفهم تقريباً';
      case 2:
        return 'فهم جزئي';
      case 3:
        return 'فهم متوسط';
      case 4:
        return 'فهم جيد';
      case 5:
        return 'فهم ممتاز';
      default:
        return '';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Attendance Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _AttendanceBottomSheet extends StatefulWidget {
  const _AttendanceBottomSheet({
    required this.task,
    required this.initialStatus,
    required this.onSave,
  });

  final TaskModel task;
  final LectureAttendanceStatus initialStatus;
  final Future<void> Function(
    LectureAttendanceStatus status,
    int rating,
    int lateMinutes,
    String? notes,
  )
  onSave;

  @override
  State<_AttendanceBottomSheet> createState() => _AttendanceBottomSheetState();
}

class _AttendanceBottomSheetState extends State<_AttendanceBottomSheet> {
  late LectureAttendanceStatus _status;
  int _understanding = 3;
  int _lateMinutes = 10;
  bool _isSaving = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAbsent = _status == LectureAttendanceStatus.absent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            widget.task.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // [FIX] يعرض formattedTimeSlot بدل raw timeSlot
          if (widget.task.timeSlot != null)
            Text(
              widget.task.formattedTimeSlot,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 20),

          // حالة الحضور
          Text('الحالة', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(
                label: 'حضرت ✅',
                selected: _status == LectureAttendanceStatus.attended,
                color: Colors.green,
                onTap:
                    () => setState(
                      () => _status = LectureAttendanceStatus.attended,
                    ),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'تأخرت ⏰',
                selected: _status == LectureAttendanceStatus.late,
                color: Colors.orange,
                onTap:
                    () =>
                        setState(() => _status = LectureAttendanceStatus.late),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'غبت ❌',
                selected: _status == LectureAttendanceStatus.absent,
                color: Colors.red,
                onTap:
                    () => setState(
                      () => _status = LectureAttendanceStatus.absent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // دقائق التأخير
          if (_status == LectureAttendanceStatus.late) ...[
            Text(
              'دقائق التأخير: $_lateMinutes دقيقة',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              value: _lateMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '$_lateMinutes دقيقة',
              onChanged: (v) => setState(() => _lateMinutes = v.round()),
            ),
            const SizedBox(height: 12),
          ],

          // تقييم الفهم
          if (!isAbsent) ...[
            Text('تقييم الفهم', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _understanding = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      star <= _understanding ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // ملاحظات
          if (!isAbsent) ...[
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
          ],

          // زر الحفظ
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              // [FIX] زر الحفظ يُظهر loading indicator أثناء الحفظ
              onPressed:
                  _isSaving
                      ? null
                      : () async {
                        setState(() => _isSaving = true);
                        await widget.onSave(
                          _status,
                          isAbsent ? 0 : _understanding,
                          _lateMinutes,
                          _notesController.text.isEmpty
                              ? null
                              : _notesController.text,
                        );
                        // لا نحتاج setState هنا — الـ sheet ستُغلق في onSave
                      },
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('تسجيل'),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
