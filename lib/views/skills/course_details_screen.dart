import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/global_learning_state.dart';
import '../../services/review_service.dart';
import '../../utils/duration_parser.dart';
import '../../models/course_model.dart';
import '../../models/skill_model.dart';
import 'skill_assessment_screen.dart';
import 'reviews_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CourseDetailsScreen
// ─────────────────────────────────────────────────────────────────────────────
class CourseDetailsScreen extends StatefulWidget {
  final String fieldId;
  final String skillId;
  final String courseId;

  const CourseDetailsScreen({
    super.key,
    required this.fieldId,
    required this.skillId,
    required this.courseId,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _descExpanded = false;
  bool _isStarting = false;
  bool _justOpenedCourse = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    final state = context.read<GlobalLearningState>();
    if (state.getFieldData(widget.fieldId) == null) {
      await state.loadField(widget.fieldId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _justOpenedCourse = true;
    } else if (state == AppLifecycleState.resumed && _justOpenedCourse) {
      _justOpenedCourse = false;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showQuickProgressDialog();
      });
    }
  }

  void _showQuickProgressDialog() {
    if (!mounted) return;
    final cp = _getProgress(context.read<GlobalLearningState>());
    if (cp == null || cp.isCompleted) return;

    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('📚 كيف كان التعلم؟'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('هل أكملت درساً جديداً؟'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('نعم'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showLessonSelectionSheet();
                        },
                      ),
                      TextButton(
                        child: const Text('ليس بعد'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showLessonSelectionSheet() {
    final state = context.read<GlobalLearningState>();
    final cp = _getProgress(state);
    if (cp == null) return;

    // جلب duration من بيانات الكورس للتحقق من الـ unlock
    final course = state.getCourseData(
      widget.fieldId,
      widget.skillId,
      widget.courseId,
    );
    final duration = course?.duration ?? '15 hours';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder:
                  (_, scrollCtrl) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'اختر الدرس المكتمل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (_) {
                            final canMark = _canMarkLesson(
                              cp,
                              duration,
                              cp.currentLessonIndex,
                            );
                            if (cp.currentLessonIndex >= cp.totalLessons ||
                                !canMark) {
                              return const SizedBox.shrink();
                            }
                            return ElevatedButton.icon(
                              icon: const Icon(Icons.fast_forward),
                              label: Text(
                                'الدرس ${cp.currentLessonIndex + 1} (التالي)',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _markLessonCompleted(cp.currentLessonIndex);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const Text('أو اختر درساً آخر:'),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollCtrl,
                            child: _LessonsList(
                              cp: cp,
                              courseDuration: duration,
                              onMarkLesson: (index) async {
                                Navigator.pop(ctx);
                                await _markLessonCompleted(index);
                              },
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

  Future<void> _markLessonCompleted(int lessonIndex) async {
    final globalState = context.read<GlobalLearningState>();

    // ── فحص حدود التعلم قبل التعليم ────────────────────────────────────────
    final checkResult = globalState.checkLessonAllowed(
      widget.fieldId,
      widget.skillId,
    );

    if (checkResult == LessonCheckResult.dailyBlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.block, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أكملت حصتك اليومية — عُد غداً لمواصلة التعلم 💪',
                  ),
                ),
              ],
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أكملت أيام تعلمك هذا الأسبوع — ابدأ من جديد الأسبوع القادم 🗓️',
                  ),
                ),
              ],
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

    // ── تحذيرات (لا تمنع — فقط تنبّه) ─────────────────────────────────────
    if (checkResult == LessonCheckResult.dailyWarning) {
      // تسجيل أن التحذير أُرسل
      globalState.markDailyWarningSent(widget.fieldId, widget.skillId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'وصلت للحد اليومي — إذا تجاوزته سيُمنع التعليم لبقية اليوم ⚠️',
                  ),
                ),
              ],
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
      // نكمل التعليم رغم التحذير
    }

    if (checkResult == LessonCheckResult.weeklyWarning) {
      globalState.markWeeklyWarningSent(widget.fieldId, widget.skillId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'وصلت للحد الأسبوعي — إذا تجاوزته سيُمنع التعليم حتى الأسبوع القادم ⚠️',
                  ),
                ),
              ],
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
      // نكمل التعليم رغم التحذير
    }

    try {
      await globalState.markLessonAsCompleted(
        fieldId: widget.fieldId,
        skillId: widget.skillId,
        courseId: widget.courseId,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );

        final progress = globalState.getCourseProgress(
          widget.fieldId,
          widget.skillId,
          widget.courseId,
        );
        if (progress?.isCompleted == true) {
          _onCourseJustCompleted(globalState);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'حدث خطأ: $e', isSuccess: false);
      }
    }
  }

  /// يُستدعى مباشرة عند اكتمال الكورس (isCompleted → true)
  void _onCourseJustCompleted(GlobalLearningState state) {
    // فحص: هل هذا أول كورس مكتمل في المهارة؟
    final skillProgress =
        state.userProfile?.fieldProgress[widget.fieldId]?.skillsProgress[widget
            .skillId];

    final completedCoursesCount =
        skillProgress?.coursesProgress.values
            .where((c) => c.isCompleted)
            .length ??
        0;

    if (completedCoursesCount == 1) {
      // أول كورس مكتمل → أطلق Dialog الاختبار بدلاً من الاحتفال
      _showAssessmentDialog(state);
    } else {
      // كورس إضافي مكتمل → الاحتفال المعتاد فقط
      _showCompletionCelebration();
    }
  }

  /// Dialog دعوة للاختبار (يظهر عند اكتمال أول كورس في المهارة)
  void _showAssessmentDialog(GlobalLearningState state) {
    final skillData = state.getSkillData(widget.fieldId, widget.skillId);
    final skillProgress =
        state.userProfile?.fieldProgress[widget.fieldId]?.skillsProgress[widget
            .skillId];

    if (skillData == null) {
      _showCompletionCelebration();
      return;
    }

    // ── فحص مسبق: استنفاد المحاولات ────────────────────────────────────────
    if ((skillProgress?.assessmentAttempts ?? 0) >= 3) {
      _showMaxAttemptsDialog(skillData.name);
      return;
    }

    // ── فحص مسبق: فترة الانتظار ─────────────────────────────────────────────
    final eligibility = state.checkAssessmentEligibility(
      fieldId: widget.fieldId,
      skillId: widget.skillId,
    );

    if (eligibility == AssessmentOutcome.waitRequired) {
      final remainingMinutes = state.getRemainingWaitMinutes(
        fieldId: widget.fieldId,
        skillId: widget.skillId,
      );
      _showWaitDialog(remainingMinutes, skillData.name);
      return;
    }

    // ── كل شيء طبيعي — افتح dialog دعوة الاختبار ───────────────────────────
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '🎉 أكملت الكورس!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.quiz_outlined,
                    size: 56,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'هل أنت مستعد لاختبار مستواك في مهارة "${skillData.name}"؟\n\n'
                    'الاختبار عبارة عن أسئلة قصيرة (حتى 15 سؤال) '
                    'لتأكيد أنك تعلمت المهارة فعلاً.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  // ── عرض عدد المحاولات المتبقية ───────────────────────────────
                  const SizedBox(height: 12),
                  _buildAttemptsIndicator(
                    skillProgress?.assessmentAttempts ?? 0,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'لاحقاً',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // فتح dialog الموافقة قبل الاختبار
                    _showAssessmentConsentDialog(
                      state,
                      skillData,
                      skillProgress,
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('ابدأ الاختبار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// dialog الموافقة على شروط الاختبار — يظهر قبل فتح SkillAssessmentScreen
  void _showAssessmentConsentDialog(
    GlobalLearningState state,
    SkillModel skillData,
    SkillProgress? skillProgress,
  ) {
    bool agreed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder:
                  (ctx, setStateLocal) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      '📋 قبل بدء الاختبار',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── معلومات الاختبار ──────────────────────────────────
                          _ConsentInfoRow(
                            icon: Icons.quiz_outlined,
                            color: const Color(0xFF6C63FF),
                            text: 'حتى 15 سؤالاً بأسلوب محادثة تفاعلية',
                          ),
                          _ConsentInfoRow(
                            icon: Icons.emoji_events_outlined,
                            color: Colors.amber,
                            text: 'درجة النجاح: 80% فأكثر',
                          ),
                          _ConsentInfoRow(
                            icon: Icons.repeat_outlined,
                            color: Colors.blue,
                            text:
                                'المحاولات المتبقية: '
                                '${3 - (skillProgress?.assessmentAttempts ?? 0)} من 3',
                          ),
                          const Divider(height: 24),

                          // ── تأثير الدرجات ─────────────────────────────────────
                          Text(
                            'تأثير درجتك على تقدمك:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ConsentGradeRow(
                            range: '≥ 80%',
                            result: 'المهارة مكتملة ✅',
                            color: Colors.green,
                          ),
                          _ConsentGradeRow(
                            range: '50% - 79%',
                            result: 'تقدم الكورس يُعاد جزئياً',
                            color: Colors.orange,
                          ),
                          _ConsentGradeRow(
                            range: '20% - 49%',
                            result: 'تقدم الكورس يُعاد لنفس النسبة',
                            color: Colors.deepOrange,
                          ),
                          _ConsentGradeRow(
                            range: '< 20%',
                            result: 'الكورس يُلغى كاملاً ⚠️',
                            color: Colors.red,
                          ),
                          const Divider(height: 24),

                          // ── تحذيرات ───────────────────────────────────────────
                          Text(
                            'تحذيرات مهمة:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ConsentInfoRow(
                            icon: Icons.content_paste_off_outlined,
                            color: Colors.red,
                            text: 'النسخ/اللصق يُخفّض درجتك',
                          ),
                          _ConsentInfoRow(
                            icon: Icons.exit_to_app_outlined,
                            color: Colors.red,
                            text:
                                'الخروج من التطبيق أثناء الاختبار يُخفّض درجتك',
                          ),
                          const SizedBox(height: 16),

                          // ── checkbox الموافقة ─────────────────────────────────
                          GestureDetector(
                            onTap: () => setStateLocal(() => agreed = !agreed),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: agreed,
                                  onChanged:
                                      (v) => setStateLocal(
                                        () => agreed = v ?? false,
                                      ),
                                  activeColor: const Color(0xFF6C63FF),
                                ),
                                const Expanded(
                                  child: Text(
                                    'قرأت وفهمت جميع الشروط وأوافق على المتابعة',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            agreed
                                ? () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => SkillAssessmentScreen(
                                            fieldId: widget.fieldId,
                                            skillId: widget.skillId,
                                            skill: skillData,
                                          ),
                                    ),
                                  ).then((_) {
                                    // بعد العودة من الاختبار — فحص خيار تعليم الكورس
                                    if (mounted) {
                                      _checkCourseCompletionChoice(state);
                                    }
                                  });
                                }
                                : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('ابدأ الاختبار'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  /// يُستدعى بعد العودة من SkillAssessmentScreen
  /// إذا كان المستخدم متقدماً ونجح → يعرض خيار تعليم الكورس مكتملاً
  void _checkCourseCompletionChoice(GlobalLearningState state) {
    if (!state.pendingCourseCompletionChoice) return;
    state.clearPendingCourseCompletionChoice();

    final cp = _getProgress(state);
    if (cp == null || cp.isCompleted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '🎉 اجتزت الاختبار!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 56,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'أثبتت إتقانك للمهارة.\n\n'
                    'هل تريد تعليم هذا الكورس كمكتمل؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
              actions: [
                // لا — يستمر في التعلم
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('سأكمل التعلم'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // نعم — يعلّم الكورس مكتملاً
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await state.markCourseAsCompleted(
                        fieldId: widget.fieldId,
                        skillId: widget.skillId,
                        courseId: widget.courseId,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('تم تعليم الكورس كمكتمل ✅'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(12),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('نعم، أتقنت محتواه'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// مؤشر مرئي لعدد المحاولات المتبقية (3 دوائر)
  Widget _buildAttemptsIndicator(int usedAttempts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'المحاولات: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        ...List.generate(3, (i) {
          final isUsed = i < usedAttempts;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUsed ? Colors.grey[400] : const Color(0xFF6C63FF),
                border: Border.all(
                  color: isUsed ? Colors.grey[400]! : const Color(0xFF6C63FF),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          '${3 - usedAttempts} متبقية',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Dialog: استنفاد المحاولات الثلاث
  void _showMaxAttemptsDialog(String skillName) {
    showDialog(
      context: context,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '🔒 استُنفدت جميع المحاولات',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: Colors.grey[500]),
                  const SizedBox(height: 16),
                  Text(
                    'استنفدت جميع محاولاتك الثلاث لاختبار مهارة "$skillName".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'يمكنك إعادة الاختبار بعد:\n'
                      '• إعادة هذا الكورس من الصفر\n'
                      '• أو إكمال كورس جديد في نفس المهارة',
                      style: TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('حسناً'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// Dialog: فترة الانتظار مع عرض الوقت المتبقي
  void _showWaitDialog(int remainingMinutes, String skillName) {
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    final waitText =
        hours > 0
            ? (minutes > 0 ? '$hours ساعة و$minutes دقيقة' : '$hours ساعة')
            : '$minutes دقيقة';

    showDialog(
      context: context,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '⏳ يرجى الانتظار',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 56, color: Colors.orange[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا يمكنك إجراء اختبار مهارة "$skillName" الآن.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: Text(
                      'الوقت المتبقي: $waitText',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'خذ الوقت الكافي لمراجعة المادة قبل المحاولة التالية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('حسناً'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// الاحتفال الاعتيادي — يظهر للكورسات الإضافية بعد الأول，
  /// أو كـ fallback عند عدم توفر بيانات المهارة
  void _showCompletionCelebration() {
    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '🎉 تهانينا!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.celebration, size: 64, color: Colors.amber),
                  SizedBox(height: 16),
                  Text(
                    'لقد أكملت الكورس بنجاح!',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('شكراً'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showRatingDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('قيّم الكورس'),
                ),
              ],
            ),
          ),
    );
  }

  void _showRatingDialog() {
    double tempRating = 0;
    final state = context.read<GlobalLearningState>();
    final cp = _getProgress(state);
    if (cp != null) tempRating = cp.userRating ?? 0;

    showDialog(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('تقييم الكورس'),
              content: StatefulBuilder(
                builder:
                    (_, setStateLocal) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('كيف تقيّم هذا الكورس؟'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            return GestureDetector(
                              onTap:
                                  () =>
                                      setStateLocal(() => tempRating = i + 1.0),
                              child: Icon(
                                i < tempRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('لاحقاً'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (tempRating > 0) {
                      _handleRating(context, tempRating, state);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('حفظ التقييم'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLessonsSection(CourseProgress cp, String courseDuration) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.playlist_play, color: Color(0xFF6C63FF)),
        title: const Text(
          'محتوى الكورس',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'التقدم: ${cp.completedLessons.length} من ${cp.totalLessons} (${_calcProgressPercent(cp)}%)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          _LessonsList(
            cp: cp,
            courseDuration: courseDuration,
            onMarkLesson: _markLessonCompleted,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:
                    cp.totalLessons > 0
                        ? cp.completedLessons.length / cp.totalLessons
                        : 0,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6C63FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  CourseProgress? _getProgress(GlobalLearningState state) =>
      state
          .userProfile
          ?.fieldProgress[widget.fieldId]
          ?.skillsProgress[widget.skillId]
          ?.coursesProgress[widget.courseId];

  _CourseStatus _statusFromProgress(CourseProgress? cp) {
    if (cp == null) return _CourseStatus.notStarted;
    if (cp.isCompleted) return _CourseStatus.completed;
    return _CourseStatus.inProgress;
  }

  int _calcProgressPercent(CourseProgress cp) {
    if (cp.totalLessons == 0) return 0;
    return ((cp.completedLessons.length / cp.totalLessons) * 100).round();
  }

  int _calcTotalLessons(String duration) {
    return (DurationParser.parseToHours(duration) * 3).round().clamp(5, 40);
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _handleMainButton(
    BuildContext ctx,
    CourseModel course,
    GlobalLearningState state,
  ) async {
    final cp = _getProgress(state);
    final status = _statusFromProgress(cp);

    if (status == _CourseStatus.notStarted) {
      final confirmed = await _showStartDialog(ctx, course);
      if (!confirmed) return;
      setState(() => _isStarting = true);
      try {
        await state.startCourse(
          fieldId: widget.fieldId,
          skillId: widget.skillId,
          courseId: widget.courseId,
          totalLessons: _calcTotalLessons(course.duration),
        );
        await _openCourse(ctx, course.link, state);
        if (ctx.mounted) {
          _showSnackBar(ctx, '🎉 تم تسجيلك في الكورس بنجاح', isSuccess: true);
        }
      } finally {
        if (mounted) setState(() => _isStarting = false);
      }
    } else {
      await _openCourse(ctx, course.link, state);
    }
  }

  Future<void> _openCourse(
    BuildContext ctx,
    String link,
    GlobalLearningState state,
  ) async {
    // تسجيل الدخول
    await state.recordCourseAccess(
      fieldId: widget.fieldId,
      skillId: widget.skillId,
      courseId: widget.courseId,
    );
    // فتح الرابط
    await _openLink(ctx, link);
  }

  Future<bool> _showStartDialog(BuildContext ctx, CourseModel course) async {
    return await showDialog<bool>(
          context: ctx,
          builder:
              (_) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.play_circle_outline, color: Color(0xFF6C63FF)),
                      SizedBox(width: 8),
                      Text(
                        'بدء الكورس',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'سيتم فتح الكورس وتسجيل بدايتك في مساركم التعليمي.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('ابدأ الآن'),
                    ),
                  ],
                ),
              ),
        ) ??
        false;
  }

  Future<void> _openLink(BuildContext ctx, String link) async {
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (ctx.mounted) {
          _showSnackBar(ctx, 'تعذر فتح الرابط', isSuccess: false);
        }
      }
    } catch (_) {
      if (ctx.mounted) {
        _showSnackBar(ctx, 'تعذر فتح الرابط', isSuccess: false);
      }
    }
  }

  Future<void> _handleRating(
    BuildContext ctx,
    double rating,
    GlobalLearningState state,
  ) async {
    try {
      await state.rateCourse(
        fieldId: widget.fieldId,
        skillId: widget.skillId,
        courseId: widget.courseId,
        rating: rating,
      );

      if (ctx.mounted) {
        _showSnackBar(
          ctx,
          'تم حفظ تقييمك: ${rating.toStringAsFixed(1)} ⭐',
          isSuccess: true,
        );
      }
    } catch (_) {
      if (ctx.mounted) {
        _showSnackBar(ctx, 'فشل حفظ التقييم', isSuccess: false);
      }
    }
  }

  void _handleShare(CourseModel course) {
    Share.share(
      '📚 ${course.title}\n'
      '👨‍🏫 ${course.instructor}\n'
      '⭐ ${course.rating}\n'
      '🔗 ${course.link}',
      subject: course.title,
    );
  }

  void _handleCopyLink(BuildContext ctx, String link) {
    Clipboard.setData(ClipboardData(text: link));
    _showSnackBar(ctx, 'تم نسخ الرابط 📋', isSuccess: true);
  }

  void _showSnackBar(BuildContext ctx, String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF2ECC71) : const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<GlobalLearningState>(
        builder: (context, state, _) {
          final course = state.getCourseData(
            widget.fieldId,
            widget.skillId,
            widget.courseId,
          );

          if (state.isLoadingStaticData && course == null) {
            return const _LoadingPage();
          }
          if (course == null) {
            return _NotFoundPage(onBack: () => context.pop());
          }

          final cp = _getProgress(state);
          final status = _statusFromProgress(cp);

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(context, course, state),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Info Grid
                          _InfoGrid(course: course),
                          const SizedBox(height: 16),

                          // ── Description
                          _DescriptionCard(
                            description: course.description,
                            expanded: _descExpanded,
                            onToggle:
                                () => setState(
                                  () => _descExpanded = !_descExpanded,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // ── Personal Progress (if started)
                          if (cp != null) ...[
                            _ProgressCard(
                              cp: cp,
                              progressPercent: _calcProgressPercent(cp),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Lessons Checklist (if started)
                          if (cp != null) ...[
                            _buildLessonsSection(cp, course.duration),
                            const SizedBox(height: 16),
                          ],

                          // ── Rating (if started)
                          if (cp != null) ...[
                            _RatingCard(
                              currentRating: cp.userRating ?? 0,
                              courseRating: course.rating,
                              onRate: (r) => _handleRating(context, r, state),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Additional actions
                          _ActionsRow(
                            onShare: () => _handleShare(course),
                            onCopyLink:
                                () => _handleCopyLink(context, course.link),
                          ),
                          const SizedBox(height: 12),

                          // ── Reviews button
                          _ReviewsButton(
                            courseId: widget.courseId,
                            courseTitle: course.title,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ReviewsScreen(
                                          fieldId: widget.fieldId,
                                          skillId: widget.skillId,
                                          courseId: widget.courseId,
                                          courseTitle: course.title,
                                        ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),

                          // ── Main CTA button
                          if (status == _CourseStatus.completed)
                            _CompletedCourseActions(
                              course: course,
                              onReview:
                                  () =>
                                      _handleMainButton(context, course, state),
                              onShare: () => _handleShare(course),
                            )
                          else
                            _MainButton(
                              status: status,
                              isLoading: _isStarting,
                              onPressed:
                                  () =>
                                      _handleMainButton(context, course, state),
                            ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────────────────
  SliverAppBar _buildHeader(
    BuildContext context,
    CourseModel course,
    GlobalLearningState state,
  ) {
    final cp = _getProgress(state);
    final status = _statusFromProgress(cp);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _platformColor(course.platform),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () => _handleShare(course),
          tooltip: 'مشاركة',
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, color: Colors.white),
          onPressed: () => _handleCopyLink(context, course.link),
          tooltip: 'نسخ الرابط',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'course_${widget.courseId}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _platformColor(course.platform),
                  _platformColor(course.platform).withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Platform logo chip
                    _PlatformBadge(platform: course.platform),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Instructor
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.instructor,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Rating + Enrollments row
                    Row(
                      children: [
                        _StarRatingDisplay(rating: course.rating),
                        const SizedBox(width: 6),
                        Text(
                          course.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 1, color: Colors.white38),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.group_outlined,
                          color: Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatEnrollments(course.enrollments),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        // Status badge
                        _StatusBadge(status: status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────
  Color _platformColor(String platform) {
    const c = {
      'YouTube': Color(0xFFCC0000),
      'Udemy': Color(0xFFA435F0),
      'Coursera': Color(0xFF0056D2),
      'edX': Color(0xFF1B1C1B),
      'Pluralsight': Color(0xFFF05A28),
      'LinkedIn Learning': Color(0xFF0A66C2),
    };
    return c[platform] ?? const Color(0xFF6C63FF);
  }

  String _formatEnrollments(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}ألف';
    return n.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────
enum _CourseStatus { notStarted, inProgress, completed }

// ─────────────────────────────────────────────────────────────────────────────
// Platform Badge
// ─────────────────────────────────────────────────────────────────────────────
class _PlatformBadge extends StatelessWidget {
  final String platform;
  const _PlatformBadge({required this.platform});

  IconData _icon() {
    switch (platform) {
      case 'YouTube':
        return Icons.play_circle_filled;
      case 'Udemy':
      case 'Coursera':
      case 'edX':
        return Icons.school;
      default:
        return Icons.ondemand_video;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            platform,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star Rating Display (read-only, small)
// ─────────────────────────────────────────────────────────────────────────────
class _StarRatingDisplay extends StatelessWidget {
  final double rating;
  const _StarRatingDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final _CourseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      _CourseStatus.notStarted => (
        'لم يبدأ',
        Colors.white38,
        Icons.lock_outline,
      ),
      _CourseStatus.inProgress => (
        'جاري',
        Colors.blue.shade300,
        Icons.play_arrow,
      ),
      _CourseStatus.completed => (
        'مكتمل',
        Colors.green.shade300,
        Icons.check_circle,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Grid (platform, language, level, duration, price, certificate)
// uses ONLY real CourseModel fields
// ─────────────────────────────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final CourseModel course;
  const _InfoGrid({required this.course});

  String _levelLabel(String l) {
    const m = {
      'beginner': 'مبتدئ',
      'intermediate': 'متوسط',
      'advanced': 'متقدم',
    };
    return m[l] ?? l;
  }

  String _priceLabel() {
    if (course.price == 'free') return 'مجاني';
    if (course.price == 'freemium') return 'مجاني جزئياً';
    final amount =
        course.priceAmount > 0
            ? '\$${course.priceAmount.toStringAsFixed(0)}'
            : 'مدفوع';
    return amount;
  }

  Color _priceColor() {
    if (course.price == 'free') return const Color(0xFF2ECC71);
    if (course.price == 'freemium') return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(
        icon: Icons.computer,
        label: 'المنصة',
        value: course.platform,
        color: const Color(0xFF6C63FF),
      ),
      _InfoItem(
        icon: Icons.language,
        label: 'اللغة',
        value: course.language == 'ar' ? '🇦🇪 عربي' : '🇺🇸 إنجليزي',
        color: const Color(0xFF4ECDC4),
      ),
      _InfoItem(
        icon: Icons.stairs,
        label: 'المستوى',
        value: _levelLabel(course.level),
        color: const Color(0xFF6C63FF),
      ),
      _InfoItem(
        icon: Icons.access_time,
        label: 'المدة',
        value: course.duration,
        color: Colors.orange,
      ),
      _InfoItem(
        icon: Icons.attach_money,
        label: 'السعر',
        value: _priceLabel(),
        color: _priceColor(),
      ),
      _InfoItem(
        icon:
            course.hasCertificate
                ? Icons.workspace_premium
                : Icons.workspace_premium_outlined,
        label: 'شهادة',
        value: course.hasCertificate ? 'متاحة ✓' : 'غير متاحة',
        color: course.hasCertificate ? const Color(0xFFFFB347) : Colors.grey,
      ),
    ];

    // Subtitles extra row if available
    final hasSubRow = course.hasSubtitles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات الكورس',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: items.map((item) => _InfoTile(item: item)).toList(),
          ),
          if (hasSubRow) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4ECDC4).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.subtitles_outlined,
                    color: Color(0xFF4ECDC4),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ترجمة: ${course.subtitleLanguages.map((l) => l == 'ar' ? 'عربي' : 'إنجليزي').join(', ')}',
                    style: const TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;
  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, color: item.color, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item.value,
                style: TextStyle(
                  color: item.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description Card (expandable)
// ─────────────────────────────────────────────────────────────────────────────
class _DescriptionCard extends StatelessWidget {
  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  const _DescriptionCard({
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'وصف الكورس',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            secondChild: Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expanded ? 'عرض أقل' : 'عرض المزيد',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6C63FF),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Card
// uses CourseProgress fields: completedLessons, totalLessons,
//   currentLessonIndex, lastAccessedAt, isCompleted
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final CourseProgress cp;
  final int progressPercent;

  const _ProgressCard({required this.cp, required this.progressPercent});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'تقدمك الشخصي',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Big percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'مكتمل',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Stats column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressStat(
                      icon: Icons.check_circle_outline,
                      label: 'الدروس المكتملة',
                      value:
                          '${cp.completedLessons.length} / ${cp.totalLessons}',
                    ),
                    const SizedBox(height: 6),
                    _ProgressStat(
                      icon: Icons.play_lesson,
                      label: 'الدرس الحالي',
                      value: 'الدرس ${cp.currentLessonIndex + 1}',
                    ),
                    const SizedBox(height: 6),
                    _ProgressStat(
                      icon: Icons.access_time,
                      label: 'آخر وصول',
                      value: _formatDate(cp.lastAccessedAt),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          if (cp.isCompleted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'أنجزت هذا الكورس! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProgressStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 5),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Rating Card (interactive — flutter_rating_bar)
// ─────────────────────────────────────────────────────────────────────────────
class _RatingCard extends StatefulWidget {
  final double currentRating;
  final double courseRating;
  final Function(double) onRate;

  const _RatingCard({
    required this.currentRating,
    required this.courseRating,
    required this.onRate,
  });

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  late double _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'قيّم هذا الكورس',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected == 0
                          ? 'اضغط لإضافة تقييمك'
                          : _ratingLabel(_selected),
                      style: TextStyle(
                        color:
                            _selected == 0
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Colors.amber.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selected = i + 1.0);
                            widget.onRate(i + 1.0);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              i < _selected
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color:
                                  i < _selected
                                      ? Colors.amber
                                      : Colors.amber.withOpacity(0.3),
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    widget.courseRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  _StarRatingDisplay(rating: widget.courseRating),
                  const SizedBox(height: 2),
                  Text(
                    'تقييم الكورس',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 4.5) return 'ممتاز! ⭐';
    if (r >= 3.5) return 'جيد جداً';
    if (r >= 2.5) return 'جيد';
    if (r >= 1.5) return 'مقبول';
    return 'ضعيف';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Actions Row (share + copy)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionsRow extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onCopyLink;

  const _ActionsRow({required this.onShare, required this.onCopyLink});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('مشاركة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C63FF),
              side: const BorderSide(color: Color(0xFF6C63FF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCopyLink,
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('نسخ الرابط'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4ECDC4),
              side: const BorderSide(color: Color(0xFF4ECDC4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews Button (مع عداد المراجعات)
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewsButton extends StatelessWidget {
  final String courseId;
  final String courseTitle;
  final VoidCallback onTap;

  const _ReviewsButton({
    required this.courseId,
    required this.courseTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: ReviewService().getCourseAverageRating(courseId),
      builder: (context, snapshot) {
        final avg = snapshot.data ?? 0.0;
        final hasRating = avg > 0;

        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
            side: const BorderSide(color: Color(0xFF6C63FF)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rate_review_outlined, size: 20),
              const SizedBox(width: 8),
              const Text(
                'آراء المستخدمين',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (hasRating) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF6C63FF),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main CTA Button
// ─────────────────────────────────────────────────────────────────────────────
class _MainButton extends StatelessWidget {
  final _CourseStatus status;
  final bool isLoading;
  final VoidCallback onPressed;

  const _MainButton({
    required this.status,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      _CourseStatus.notStarted => (
        'بدء الكورس',
        Icons.play_circle_outline,
        const Color(0xFF2ECC71),
      ),
      _CourseStatus.inProgress => (
        'متابعة التعلم',
        Icons.play_arrow,
        const Color(0xFF6C63FF),
      ),
      _CourseStatus.completed => (
        'مراجعة الكورس',
        Icons.replay,
        Colors.grey.shade600,
      ),
    };

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(icon, size: 22),
        label: Text(
          isLoading ? 'جارٍ التحميل...' : label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// أزرار الكورس المكتمل: مراجعة + الشهادة + مشاركة
// ─────────────────────────────────────────────────────────────────────
class _CompletedCourseActions extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onReview;
  final VoidCallback onShare;

  const _CompletedCourseActions({
    required this.course,
    required this.onReview,
    required this.onShare,
  });

  Future<void> _openCertificate(BuildContext context) async {
    // نفتح رابط الكورس لأنه لا يوجد رابط شهادة منفصل في الموديل بعد
    final uri = Uri.parse(course.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط الشهادة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // زر المراجعة — كامل العرض
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.replay, size: 20),
            label: const Text(
              'مراجعة الكورس',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // زر الشهادة + زر المشاركة جنباً لجنب
        Row(
          children: [
            if (course.hasCertificate)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openCertificate(context),
                  icon: const Icon(
                    Icons.workspace_premium,
                    size: 18,
                    color: Colors.amber,
                  ),
                  label: const Text('الشهادة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber[700],
                    side: BorderSide(color: Colors.amber[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (course.hasCertificate) const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('مشاركة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// دالة مستقلة لفحص إمكانية تعليم الدرس — مشتركة بين Bottom Sheet و _LessonsList
// ─────────────────────────────────────────────────────────────────────────────
bool _canMarkLesson(CourseProgress cp, String courseDuration, int index) {
  // درس مكتمل مسبقاً — لا يُعاد تعليمه
  if (cp.completedLessons.contains(index)) return false;
 
  final hours = DurationParser.parseToHours(courseDuration);
  final minutesPerLesson = ((hours * 60) / cp.totalLessons).clamp(20.0, 180.0);
 
  // أول درس — مسموح دائماً بمجرد بدء الكورس
  if (cp.completedLessons.isEmpty) return index == 0;
 
  // يجب أن يكون الدرس هو الدرس التالي المتوقع بالترتيب
  final nextExpected = cp.completedLessons.reduce((a, b) => a > b ? a : b) + 1;
  if (index != nextExpected) return false;

  final reference = cp.lastLessonUnlockedAt ?? cp.lastAccessedAt;
  final minutesElapsed = DateTime.now().difference(reference).inMinutes;
  return minutesElapsed >= minutesPerLesson;
}

// ─────────────────────────────────────────────────────────────────────────────
// قائمة الدروس — مشتركة بين Bottom Sheet و ExpansionTile
// ─────────────────────────────────────────────────────────────────────────────
class _LessonsList extends StatelessWidget {
  final CourseProgress cp;
  final String courseDuration;
  final Future<void> Function(int lessonIndex) onMarkLesson;

  const _LessonsList({
    required this.cp,
    required this.courseDuration,
    required this.onMarkLesson,
  });

  double _parsedHours() => DurationParser.parseToHours(courseDuration);

  bool _canMark(int index) => _canMarkLesson(cp, courseDuration, index);

  String _lockReason(int index) {
  final hours = _parsedHours();
  final minutesPerLesson = ((hours * 60) / cp.totalLessons).clamp(20.0, 180.0);
 
  // lastLessonUnlockedAt هو التاريخ الصحيح لحساب الوقت المتبقي
  final reference = cp.lastLessonUnlockedAt ?? cp.lastAccessedAt;
  final minutesElapsed = DateTime.now().difference(reference).inMinutes;
 
  final remaining = (minutesPerLesson - minutesElapsed).ceil();
  if (remaining <= 0) return '';
  if (remaining < 60) return 'متاح بعد $remaining دقيقة';
  final h = remaining ~/ 60;
  final m = remaining % 60;
  return m > 0 ? 'متاح بعد $hس $mد' : 'متاح بعد $h ساعة';
}

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cp.totalLessons,
      itemBuilder: (context, index) {
        final isCompleted = cp.completedLessons.contains(index);
        final isCurrent = index == cp.currentLessonIndex;
        final canMark = _canMark(index);

        final isNextLocked =
            !isCompleted &&
            !canMark &&
            cp.completedLessons.isNotEmpty &&
            index == cp.completedLessons.reduce((a, b) => a > b ? a : b) + 1;

        final lockMsg = isNextLocked ? _lockReason(index) : '';

        return CheckboxListTile(
          value: isCompleted,
          enabled: canMark,
          activeColor: const Color(0xFF6C63FF),
          dense: true,
          title: Row(
            children: [
              Text(
                'الدرس ${index + 1}',
                style: TextStyle(
                  color:
                      isCompleted
                          ? Colors.green
                          : canMark
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey[500],
                ),
              ),
              if (isCurrent && !isCompleted && canMark) ...[
                const SizedBox(width: 8),
                Chip(
                  label: const Text(
                    'التالي',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              if (isNextLocked && lockMsg.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 11,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        lockMsg,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          secondary:
              isCompleted
                  ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                  : canMark
                  ? Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey[400],
                    size: 20,
                  )
                  : const Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
          onChanged: (value) async {
            if (value == true && canMark) {
              await onMarkLesson(index);
            }
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Consent Dialog Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ConsentInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ConsentInfoRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ConsentGradeRow extends StatelessWidget {
  final String range;
  final String result;
  final Color color;

  const _ConsentGradeRow({
    required this.range,
    required this.result,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              range,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Not Found
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              Text(
                'جارٍ تحميل الكورس...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFoundPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: onBack,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.video_library_outlined,
                size: 64,
                color: Color(0xFF6C63FF),
              ),
              const SizedBox(height: 16),
              const Text(
                'لم يتم العثور على الكورس',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'تحقق من الرابط وأعد المحاولة',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
