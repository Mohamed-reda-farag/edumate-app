import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/gamification_controller.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/schedule_controller.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/task_model.dart';
import '../../models/gamification_model.dart';
import '../notifications/notification_history_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HomeScreen
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Consumer4<
          AuthController,
          NotificationController,
          GamificationController,
          TaskController
        >(
          builder: (context, auth, notif, gamif, tasks, _) {
            return Consumer2<GlobalLearningState, ScheduleController>(
              builder: (context, learning, schedule, _) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _HomeAppBar(auth: auth, notif: notif, tasks: tasks, gamif: gamif),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _OverallPerformanceCard(
                              tasks: tasks,
                              schedule: schedule,
                              gamif: gamif),
                          const SizedBox(height: 16),
                          _PerformanceBreakdownRow(
                              tasks: tasks, schedule: schedule),
                          const SizedBox(height: 16),
                          _FieldsProgressSection(learning: learning),
                          const SizedBox(height: 16),
                          _GamificationSection(gamif: gamif),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _HomeAppBar
// ══════════════════════════════════════════════════════════════════════════════

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({
    required this.auth,
    required this.notif,
    required this.tasks,
    required this.gamif,
  });

  final AuthController auth;
  final NotificationController notif;
  final TaskController tasks;
  final GamificationController gamif;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  String _firstName() {
    final name = auth.currentUser?.name ?? '';
    if (name.isEmpty) return 'طالب';
    return name.trim().split(' ').first;
  }

  String _motivationalMessage() {
    final daily = tasks.dailyTasks;
    final courses = tasks.courseTasks;

    final totalDaily = daily.where((t) =>
        t.type == TaskType.lecture || t.type == TaskType.studySession).length;
    final completedDaily = daily.where((t) =>
        (t.type == TaskType.lecture || t.type == TaskType.studySession) &&
        t.status == TaskStatus.completed).length;
    final totalCourses = courses.length;
    final completedCourses =
        courses.where((t) => t.status == TaskStatus.completed).length;

    final dailyScore = totalDaily > 0 ? completedDaily / totalDaily : 0.0;
    final courseScore = totalCourses > 0 ? completedCourses / totalCourses : 0.0;
    final score = (dailyScore * 0.6) + (courseScore * 0.4);
    final streak = gamif.data?.currentStreak ?? 0;

    // نستخدم رقم اليوم في السنة كـ index — يتغير تلقائياً كل يوم
    // بدون أي حفظ في Firestore أو SharedPreferences
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // ── الحالة 1: Streak أسبوع أو أكثر ──────────────────────────────
    const streakMessages = [
      'أسبوع متواصل من الالتزام 🔥 هذا ليس حظاً، هذا انضباط!',
      'سلسلتك لا تنكسر 🔥 استمر وأنت تصنع التاريخ!',
      'أيام متواصلة وأنت لم تتوقف 🔥 الإصرار هو سر النجاح!',
      'الثبات هو أقوى سلاح 🔥 وأنت تُثبت ذلك كل يوم!',
      'كل يوم تُضيفه لسلسلتك يجعلك أقوى من الأمس 🔥',
      'من يداوم يتقن، ومن يتقن يتفوق 🔥 واصل!',
      'الاستمرارية تبني الإمبراطوريات 🔥 وأنت تبني إمبراطوريتك!',
    ];

    // ── الحالة 2: أداء ممتاز (80%+) ──────────────────────────────────
    const excellentMessages = [
      'أداؤك في القمة اليوم ✨ هذا المستوى يميّزك!',
      'نتائجك تتحدث عنك ✨ واصل هذا التألق!',
      'أنت تُثبت كل يوم أن الجدية تُؤتي ثمارها ✨',
      'رائع! الإنجاز الحقيقي يبدأ حين تلتزم بما بدأت ✨',
      'أداؤك يلهم! حافظ على هذه الوتيرة ✨',
      'التميز عادة وليس صدفة، وأنت تُجسّد ذلك ✨',
      'كل يوم مثالي يضيف طابقاً لبنائك نحو الأعلى ✨',
    ];

    // ── الحالة 3: أداء جيد (50%-79%) ─────────────────────────────────
    const goodMessages = [
      'أنت على المسار الصحيح 💪 خطوة واحدة تكفي لتصل للقمة!',
      'تقدم ملحوظ! أضف مهمة واحدة اليوم وستشعر بالفرق 💪',
      'النصف الأفضل منك يريد أن يتفوق 💪 أعطه الفرصة!',
      'الفجوة بينك وبين الممتاز صغيرة، سدّها اليوم 💪',
      'جيد جداً! لكن الأفضل فيك يستحق أكثر 💪',
      'أنت أقرب مما تظن من القمة 💪 لا تتوقف الآن!',
      'كل جهد إضافي اليوم يُضاعف نتائج الغد 💪',
    ];

    // ── الحالة 4: أداء منخفض مع وجود مهام ───────────────────────────
    const improvingMessages = [
      'لم فوات الأوان بعد 🎯 ابدأ بمهمة واحدة الآن!',
      'الفشل الوحيد هو عدم المحاولة 🎯 حاول اليوم!',
      'كل بطل مر بيوم مثل هذا 🎯 الفرق أنه لم يستسلم!',
      'يوم صعب يصنع شخصاً أقوى 🎯 أنت أقوى مما تعتقد!',
      'الطريق الألف ميل يبدأ بخطوة 🎯 خطوتك الآن!',
      'غداً سيكون أفضل إذا بدأت اليوم 🎯 لا تؤجل!',
      'ارسم منحنى صاعداً اليوم 🎯 مهمة واحدة تكفي!',
    ];

    // ── الحالة 5: لا توجد مهام بعد ───────────────────────────────────
    const startMessages = [
      'رحلتك بدأت للتو، خطوة تلو الأخرى 🌱',
      'كل خبير كان مبتدئاً يوماً ما 🌱 ابدأ الآن!',
      'الشجرة الكبيرة بدأت بذرة صغيرة 🌱 أنت في البداية!',
      'لا يهم من أين تبدأ، يهم أنك بدأت 🌱',
      'اليوم الأول هو الأهم 🌱 اجعله لا يُنسى!',
      'المستقبل يبنيه من يبدأ اليوم لا من يؤجل 🌱',
      'رحلة الألف ميل أمامك 🌱 الخطوة الأولى هي الأصعب والأجمل!',
    ];

    // اختيار الحالة المناسبة ثم الجملة اليومية منها
    final List<String> messages;
    if (streak >= 7) {
      messages = streakMessages;
    } else if (score >= 0.8) {
      messages = excellentMessages;
    } else if (score >= 0.5) {
      messages = goodMessages;
    } else if (score > 0) {
      messages = improvingMessages;
    } else {
      messages = startMessages;
    }

    return messages[dayOfYear % messages.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = notif.unreadCount;
    final isNewUser = auth.currentUser?.isNewUser ?? false;

    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNewUser
                              ? 'مرحباً بك في رحلتك 🚀'
                              : '${_greeting()}، ${_firstName()} 👋',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _motivationalMessage(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // زر الجرس مع Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationHistoryScreen(),
                          ),
                        ),
                        icon: Icon(
                          unread > 0
                              ? Icons.notifications_rounded
                              : Icons.notifications_outlined,
                          size: 28,
                          color: unread > 0
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        tooltip: 'الإشعارات',
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: BoxDecoration(
                              color: cs.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cs.onError,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// نتيجة حساب الأداء التراكمي
// ══════════════════════════════════════════════════════════════════════════════

class _PerformanceResult {
  final double score;         // الأداء العام التراكمي (0.0 - 1.0)
  final double attendanceScore; // نسبة الحضور التراكمية
  final double skillsScore;     // تقدم المهارات
  final double streakScore;     // قوة الـ Streak
  // للبطاقتين التفصيليتين (يومي فقط للعرض)
  final int completedDaily;
  final int totalDaily;
  final int completedCourses;
  final int totalCourses;

  const _PerformanceResult({
    required this.score,
    required this.attendanceScore,
    required this.skillsScore,
    required this.streakScore,
    required this.completedDaily,
    required this.totalDaily,
    required this.completedCourses,
    required this.totalCourses,
  });
}

/// المعادلة التراكمية الكاملة:
///   نسبة الحضور الكلي  × 40%  ← من ScheduleController.performances (تراكمي)
///   تقدم المهارات       × 40%  ← من GlobalLearningState (تراكمي)
///   قوة الـ Streak      × 20%  ← من GamificationController (تراكمي)
///
/// لا تصفر كل يوم — تعكس أداء المستخدم منذ بدأ التطبيق حتى الآن.
_PerformanceResult _computePerformance({
  required TaskController tasks,
  required ScheduleController schedule,
  required GamificationController gamif,
  required GlobalLearningState learning,
}) {
  // ── 1. نسبة الحضور التراكمية من performances ────────────────────────────
  final performances = schedule.performances;
  final totalLectures =
      performances.fold(0, (sum, p) => sum + p.totalLectures);
  final totalAttended =
      performances.fold(0, (sum, p) => sum + p.attendedCount);
  // التأخر يُحسب بنصف وزن (حضر لكن متأخر)
  final totalLate =
      performances.fold(0, (sum, p) => sum + p.lateCount);
  final attendanceScore = totalLectures > 0
      ? ((totalAttended + (totalLate * 0.5)) / totalLectures).clamp(0.0, 1.0)
      : 0.0;

  // ── 2. تقدم المهارات التراكمي من GlobalLearningState ────────────────────
  final skillsScore =
      (learning.getOverallProgressPercentage() / 100).clamp(0.0, 1.0);

  // ── 3. قوة الـ Streak — 30 يوم = 100% ──────────────────────────────────
  final streak = gamif.data?.currentStreak ?? 0;
  final streakScore = (streak / 30).clamp(0.0, 1.0);

  // ── المعادلة النهائية ────────────────────────────────────────────────────
  final overall = (attendanceScore * 0.40) +
      (skillsScore * 0.40) +
      (streakScore * 0.20);

  // ── بيانات العرض اليومي للبطاقتين التفصيليتين ───────────────────────────
  final daily = tasks.dailyTasks;
  final courses = tasks.courseTasks;

  final totalDaily = daily
      .where((t) =>
          t.type == TaskType.lecture || t.type == TaskType.studySession)
      .length;
  final completedDaily = daily
      .where((t) =>
          (t.type == TaskType.lecture || t.type == TaskType.studySession) &&
          t.status == TaskStatus.completed)
      .length;
  final totalCourses = courses.length;
  final completedCourses =
      courses.where((t) => t.status == TaskStatus.completed).length;

  return _PerformanceResult(
    score: overall.clamp(0.0, 1.0),
    attendanceScore: attendanceScore,
    skillsScore: skillsScore,
    streakScore: streakScore,
    completedDaily: completedDaily,
    totalDaily: totalDaily,
    completedCourses: completedCourses,
    totalCourses: totalCourses,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// بطاقة الأداء العام
// ══════════════════════════════════════════════════════════════════════════════

class _OverallPerformanceCard extends StatelessWidget {
  const _OverallPerformanceCard({
    required this.tasks,
    required this.schedule,
    required this.gamif,
  });
  final TaskController tasks;
  final ScheduleController schedule;
  final GamificationController gamif;

  String _levelLabel(double score) {
    if (score >= 0.85) return 'ممتاز 🌟';
    if (score >= 0.70) return 'جيد جداً ✅';
    if (score >= 0.50) return 'جيد 👍';
    if (score >= 0.30) return 'يحتاج تحسين 📈';
    return 'ابدأ الآن 🎯';
  }

  Color _scoreColor(double score, ColorScheme cs) {
    if (score >= 0.85) return const Color(0xFF2E7D32);
    if (score >= 0.70) return cs.primary;
    if (score >= 0.50) return const Color(0xFF1565C0);
    if (score >= 0.30) return const Color(0xFFE65100);
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final learning = context.read<GlobalLearningState>();
    final result = _computePerformance(
      tasks: tasks,
      schedule: schedule,
      gamif: gamif,
      learning: learning,
    );
    final pct = (result.score * 100).round();
    final color = _scoreColor(result.score, cs);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            'الأداء العام',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 24),

          // دائرة التقدم
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        cs.surfaceContainerHighest),
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: result.score),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => Text(
                        '$value%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _levelLabel(result.score),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // مكونات المعادلة التراكمية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                label: 'الحضور',
                value: '${(result.attendanceScore * 100).round()}%',
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'المهارات',
                value: '${(result.skillsScore * 100).round()}%',
                color: const Color(0xFF6750A4),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'الالتزام',
                value: '${(result.streakScore * 100).round()}%',
                color: const Color(0xFFE65100),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// صف تفصيل الأداء — بطاقتان
// ══════════════════════════════════════════════════════════════════════════════

class _PerformanceBreakdownRow extends StatelessWidget {
  const _PerformanceBreakdownRow({
    required this.tasks,
    required this.schedule,
  });
  final TaskController tasks;
  final ScheduleController schedule;

  @override
  Widget build(BuildContext context) {
    final daily = tasks.dailyTasks;
    final courses = tasks.courseTasks;

    final totalDaily = daily
        .where((t) =>
            t.type == TaskType.lecture || t.type == TaskType.studySession)
        .length;
    final completedDaily = daily
        .where((t) =>
            (t.type == TaskType.lecture || t.type == TaskType.studySession) &&
            t.status == TaskStatus.completed)
        .length;

    final totalCourses = courses.length;
    final completedCourses =
        courses.where((t) => t.status == TaskStatus.completed).length;

    // نسبة الحضور التراكمية للعرض في البطاقة الأولى
    final performances = schedule.performances;
    final totalLectures =
        performances.fold(0, (sum, p) => sum + p.totalLectures);
    final totalAttended =
        performances.fold(0, (sum, p) => sum + p.attendedCount);
    final attendancePct = totalLectures > 0
        ? ((totalAttended / totalLectures) * 100).round()
        : null;

    return Row(
      children: [
        Expanded(
          child: _BreakdownCard(
            icon: Icons.school_rounded,
            title: 'المهام الدراسية',
            completed: completedDaily,
            total: totalDaily,
            subtitle: attendancePct != null ? 'حضور كلي $attendancePct%' : null,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BreakdownCard(
            icon: Icons.rocket_launch_rounded,
            title: 'مهام المهارات',
            completed: completedCourses,
            total: totalCourses,
            color: const Color(0xFF6750A4),
          ),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.icon,
    required this.title,
    required this.completed,
    required this.total,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final int completed;
  final int total;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$completed',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: '/$total',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// قسم تقدم المجالات
// ══════════════════════════════════════════════════════════════════════════════

class _FieldsProgressSection extends StatelessWidget {
  const _FieldsProgressSection({required this.learning});
  final GlobalLearningState learning;

  String _levelLabel(String level) {
    switch (level) {
      case 'foundation':   return 'الأساسيات';
      case 'intermediate': return 'المتوسط';
      case 'advanced':     return 'المتقدم';
      case 'expert':       return 'خبير';
      default:             return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!learning.hasUserProfile) return const SizedBox.shrink();

    final primaryId   = learning.primaryField;
    final secondaryId = learning.secondaryField;
    if (primaryId == null) return const SizedBox.shrink();

    final primaryField    = learning.getFieldData(primaryId);
    final primaryProgress = learning.userProfile?.fieldProgress[primaryId];
    final secondaryField    = secondaryId != null ? learning.getFieldData(secondaryId) : null;
    final secondaryProgress = secondaryId != null ? learning.userProfile?.fieldProgress[secondaryId] : null;

    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 4),
          child: Text(
            'تقدمي في المجالات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
          ),
        ),
        if (primaryField != null && primaryProgress != null)
          _FieldProgressCard(
            fieldIcon: primaryField.icon,
            fieldName: primaryField.name,
            levelLabel: _levelLabel(primaryProgress.currentLevel),
            progress: (primaryProgress.overallProgress / 100).clamp(0.0, 1.0),
            badgeLabel: 'أساسي',
            badgeColor: const Color(0xFF6750A4),
            onTap: () => context.push('/field-details/$primaryId'),
          ),
        if (secondaryField != null && secondaryProgress != null) ...[
          const SizedBox(height: 12),
          _FieldProgressCard(
            fieldIcon: secondaryField.icon,
            fieldName: secondaryField.name,
            levelLabel: _levelLabel(secondaryProgress.currentLevel),
            progress: (secondaryProgress.overallProgress / 100).clamp(0.0, 1.0),
            badgeLabel: 'ثانوي',
            badgeColor: const Color(0xFF00796B),
            onTap: () => context.push('/field-details/$secondaryId'),
          ),
        ],
      ],
    );
  }
}

class _FieldProgressCard extends StatelessWidget {
  const _FieldProgressCard({
    required this.fieldIcon,
    required this.fieldName,
    required this.levelLabel,
    required this.progress,
    required this.badgeLabel,
    required this.badgeColor,
    this.onTap,
  });

  final String fieldIcon;
  final String fieldName;
  final String levelLabel;
  final double progress;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = (progress * 100).round();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Text(fieldIcon, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fieldName,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: badgeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    levelLabel,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => LinearProgressIndicator(
                              value: value,
                              minHeight: 7,
                              backgroundColor: cs.surfaceContainerHighest,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(badgeColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_left, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// قسم الـ Gamification
// ══════════════════════════════════════════════════════════════════════════════

class _GamificationSection extends StatelessWidget {
  const _GamificationSection({required this.gamif});
  final GamificationController gamif;

  String _formatPoints(int points) {
    if (points >= 1000) return '${(points / 1000).toStringAsFixed(1)}k';
    return '$points';
  }

  @override
  Widget build(BuildContext context) {
    final data = gamif.data;
    if (data == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 4),
          child: Text(
            'إنجازاتي',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              // Streak + نقاط + مستوى
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _GamifTile(
                        emoji: '🔥',
                        value: '${data.currentStreak}',
                        label: 'يوم متواصل',
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    VerticalDivider(
                        color: cs.outlineVariant.withOpacity(0.5)),
                    Expanded(
                      child: _GamifTile(
                        emoji: '⭐',
                        value: _formatPoints(data.totalPoints),
                        label: 'نقطة',
                        color: const Color(0xFFF9A825),
                      ),
                    ),
                    VerticalDivider(
                        color: cs.outlineVariant.withOpacity(0.5)),
                    Expanded(
                      child: _GamifTile(
                        emoji: '🏅',
                        value: 'المستوى ${data.level}',
                        label: 'الحالي',
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // شريط تقدم المستوى
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التقدم نحو المستوى ${data.level + 1}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        '${data.pointsToNextLevel} نقطة متبقية',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: data.levelProgress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                  ),
                ],
              ),

              // آخر إنجاز مفتوح
              if (data.unlockedAchievements.isNotEmpty) ...[
                const SizedBox(height: 16),
                _LastAchievementTile(
                    achievementId: data.unlockedAchievements.last),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GamifTile extends StatelessWidget {
  const _GamifTile({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LastAchievementTile extends StatelessWidget {
  const _LastAchievementTile({required this.achievementId});
  final String achievementId;

  @override
  Widget build(BuildContext context) {
    final achievement = Achievement.findById(achievementId);
    if (achievement == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخر إنجاز',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                Text(
                  achievement.titleAr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${achievement.pointsReward} ⭐',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}