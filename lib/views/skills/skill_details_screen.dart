import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/global_learning_state.dart';
import '../../utils/duration_parser.dart';
import '../../models/course_model.dart';
import '../../models/skill_model.dart';
import '../../utils/skill_utils.dart';
import 'skill_assessment_screen.dart';


class SkillDetailsScreen extends StatefulWidget {
  final String fieldId;
  final String skillId;

  const SkillDetailsScreen({
    super.key,
    required this.fieldId,
    required this.skillId,
  });

  @override
  State<SkillDetailsScreen> createState() => _SkillDetailsScreenState();
}

class _SkillDetailsScreenState extends State<SkillDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    final state = context.read<GlobalLearningState>();
    if (state.getFieldData(widget.fieldId) == null) {
      await state.loadField(widget.fieldId);
    }
  }

  /// يُعيد مستوى المستخدم في هذه المهارة من الاستبيان
  String _getUserSkillLevel(GlobalLearningState state) {
    final skillLevels = state.userProfile?.preferences['skillLevels']
        as Map<String, dynamic>? ?? {};
    return skillLevels[widget.skillId] as String? ?? 'foundation';
  }

  /// يُعيد نص التعليمات حسب مستوى المستخدم في المهارة
  /// null = لا يظهر Banner (مستوى foundation)
  ({String message, Color color, IconData icon})? _getLevelGuidance(
      String level) {
    return switch (level) {
      'intermediate' => (
          message:
              'مستواك متوسط في هذه المهارة — ستحتاج تقريباً 60% من أي كورس '
              'لتصل لحد بدء الاختبار. ابدأ من حيث تشعر أنك بحاجة للتعلم.',
          color: const Color(0xFF1565C0),
          icon: Icons.lightbulb_outline,
        ),
      'advanced' => (
          message:
              'مستواك متقدم — تحتاج فقط 25% من أي كورس (الجزء الذي ينقصك) '
              'ثم يمكنك بدء الاختبار متى أردت. '
              'الاختبار صارم ويؤثر على تقدمك، فتأكد من جاهزيتك.',
          color: const Color(0xFF6C63FF),
          icon: Icons.rocket_launch_outlined,
        ),
      'expert' => (
          message:
              'مستواك خبير — يمكنك بدء الاختبار مباشرة دون الحاجة لأي كورس. '
              'كن حذراً: درجة الاختبار ستحدد تقدمك الفعلي في المهارة.',
          color: const Color(0xFFE65100),
          icon: Icons.electric_bolt_outlined,
        ),
      _ => null,
    };
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<GlobalLearningState>(
        builder: (context, state, _) {
          final skill = state.getSkillData(widget.fieldId, widget.skillId);
          final fieldProgress =
              state.userProfile?.fieldProgress[widget.fieldId];
          final skillProgress = fieldProgress?.skillsProgress[widget.skillId];
          final progress = skillProgress?.progressPercentage ?? 0;

          if (state.isLoadingStaticData && skill == null) {
            return const _LoadingPage();
          }
          if (skill == null) {
            return _NotFoundPage(onBack: () => context.pop());
          }

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(
              slivers: [
                _buildSliverHeader(context, skill, progress),
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(_slideAnimation),
                    child: FadeTransition(
                      opacity: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Banner التعليمات حسب المستوى ───────────────
                            _buildLevelGuidanceBanner(state),
                            // ── Meta chips
                            _MetaChipsRow(skill: skill),
                            const SizedBox(height: 16),
                            // ── Progress Card
                            if (skillProgress != null) ...[
                              _ProgressCard(
                                progress: progress,
                                fieldId: widget.fieldId,
                                skillId: widget.skillId,
                                state: state,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── زر الاختبار للخبير (بدون شروط) ─────────────
                            if (_getUserSkillLevel(state) == 'expert' &&
                                (skillProgress?.assessmentAttempts ?? 0) < 3)
                              _buildExpertAssessmentButton(state),

                            // ── زر الاختبار للمستويات الأخرى (عند 80%) ─────
                            if (_getUserSkillLevel(state) != 'expert' &&
                                (skillProgress?.progressPercentage ?? 0) >= 80 &&
                                (skillProgress?.assessmentAttempts ?? 0) < 3)
                              _buildAssessmentButton(state),

                            // ── Description
                            _InfoCard(
                              title: 'وصف المهارة',
                              icon: Icons.description_outlined,
                              child: Text(
                                skill.description,
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  height: 1.6,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── What You Will Learn
                            if (skill.whatYouWillLearn.isNotEmpty) ...[
                              _InfoCard(
                                title: 'ماذا ستتعلم',
                                icon: Icons.lightbulb_outline,
                                child: _BulletList(
                                  items: skill.whatYouWillLearn,
                                  color: const Color(0xFF6C63FF),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // ── Real World Applications
                            if (skill.realWorldApplications.isNotEmpty) ...[
                              _InfoCard(
                                title: 'التطبيقات في الواقع العملي',
                                icon: Icons.rocket_launch_outlined,
                                child: _BulletList(
                                  items: skill.realWorldApplications,
                                  color: const Color(0xFF4ECDC4),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // ── Prerequisites
                            if (skill.prerequisites.isNotEmpty) ...[
                              _ChipsCard(
                                title: 'المتطلبات المسبقة',
                                icon: Icons.lock_open_outlined,
                                items: skill.prerequisites,
                                color: const Color(0xFFFF6B6B),
                                onTap:
                                    (id) => context.push(
                                      '/skill-details/${widget.fieldId}/$id',
                                    ),
                                state: state,
                                fieldId: widget.fieldId,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // ── Learning Paths
                            if (skill.learningPaths.isNotEmpty) ...[
                              _LearningPathsCard(paths: skill.learningPaths),
                              const SizedBox(height: 12),
                            ],

                            // ── Practice Projects
                            if (skill.practiceProjects.isNotEmpty) ...[
                              _ProjectsCard(projects: skill.practiceProjects),
                              const SizedBox(height: 12),
                            ],

                            // ── Courses
                            // ── Courses
                            _CoursesSectionHeader(count: skill.courses.length),
                            const SizedBox(height: 8),
                            _CoursesLazyList(
                              courses: skill.courses,
                              fieldId: widget.fieldId,
                              skillId: widget.skillId,
                              state: state,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpertAssessmentButton(GlobalLearningState state) {
    final skillData = state.getSkillData(widget.fieldId, widget.skillId);
    if (skillData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToAssessment(state, skillData),
        icon: const Icon(Icons.electric_bolt_outlined),
        label: const Text(
          'ابدأ اختبار المهارة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentButton(GlobalLearningState state) {
    final skillData = state.getSkillData(widget.fieldId, widget.skillId);
    if (skillData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToAssessment(state, skillData),
        icon: const Icon(Icons.quiz_outlined),
        label: const Text(
          'ابدأ اختبار المهارة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _navigateToAssessment(GlobalLearningState state, SkillModel skillData) {
    final skillProgress = state.userProfile
        ?.fieldProgress[widget.fieldId]
        ?.skillsProgress[widget.skillId];

    // فحص فترة الانتظار
    final eligibility = state.checkAssessmentEligibility(
      fieldId: widget.fieldId,
      skillId: widget.skillId,
    );

    if (eligibility == AssessmentOutcome.maxAttemptsReached) {
      _showMaxAttemptsDialog(skillData.name);
      return;
    }

    if (eligibility == AssessmentOutcome.waitRequired) {
      final remaining = state.getRemainingWaitMinutes(
        fieldId: widget.fieldId,
        skillId: widget.skillId,
      );
      _showWaitDialog(remaining, skillData.name);
      return;
    }

    // عرض dialog الموافقة قبل الاختبار
    _showAssessmentConsentDialog(state, skillData, skillProgress);
  }

  void _showMaxAttemptsDialog(String skillName) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('🔒 استُنفدت جميع المحاولات',
              textAlign: TextAlign.center),
          content: Text(
            'استنفدت جميع محاولاتك الثلاث لاختبار مهارة "$skillName".\n\n'
            'يمكنك إعادة الاختبار بعد إكمال كورس جديد أو إعادة كورس حالي.',
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWaitDialog(int remainingMinutes, String skillName) {
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    final waitText = hours > 0
        ? (minutes > 0 ? '$hours ساعة و$minutes دقيقة' : '$hours ساعة')
        : '$minutes دقيقة';

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('⏳ يرجى الانتظار',
              textAlign: TextAlign.center),
          content: Text(
            'لا يمكنك إجراء اختبار "$skillName" الآن.\n\n'
            'الوقت المتبقي: $waitText',
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelGuidanceBanner(GlobalLearningState state) {
    final level = _getUserSkillLevel(state);
    final guidance = _getLevelGuidance(level);
    if (guidance == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: guidance.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: guidance.color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(guidance.icon, color: guidance.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              guidance.message,
              style: TextStyle(
                fontSize: 13,
                color: guidance.color,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssessmentConsentDialog(
    GlobalLearningState state,
    SkillModel skillData,
    SkillProgress? skillProgress,
  ) {
    bool agreed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text(
              '📋 قبل بدء الاختبار',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    text: 'حتى 15 سؤالاً بأسلوب محادثة',
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
                        'المحاولات المتبقية: ${3 - (skillProgress?.assessmentAttempts ?? 0)} من 3',
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
                      color: Colors.green),
                  _ConsentGradeRow(
                      range: '50% - 79%',
                      result: 'تقدم الكورس يُعاد جزئياً',
                      color: Colors.orange),
                  _ConsentGradeRow(
                      range: '20% - 49%',
                      result: 'تقدم الكورس يُعاد لنفس النسبة',
                      color: Colors.deepOrange),
                  _ConsentGradeRow(
                      range: '< 20%',
                      result: 'الكورس يُلغى كاملاً ⚠️',
                      color: Colors.red),
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
                    text: 'الخروج من التطبيق أثناء الاختبار يُخفّض درجتك',
                  ),
                  const SizedBox(height: 16),

                  // ── checkbox الموافقة ─────────────────────────────────
                  GestureDetector(
                    onTap: () => setStateLocal(() => agreed = !agreed),
                    child: Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          onChanged: (v) =>
                              setStateLocal(() => agreed = v ?? false),
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
                child: Text('إلغاء',
                    style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton.icon(
                onPressed: agreed
                    ? () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SkillAssessmentScreen(
                              fieldId: widget.fieldId,
                              skillId: widget.skillId,
                              skill: skillData,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('ابدأ الاختبار'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverHeader(
    BuildContext context,
    SkillModel skill,
    int progress,
  ) {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: SkillUtils.levelColor(skill.level),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SkillUtils.levelColor(skill.level),
                SkillUtils.levelColor(skill.level).withOpacity(0.75),
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
                  if (skill.isMandatory)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'مهارة أساسية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    skill.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    skill.nameEn,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.white30,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta Chips — استخدام الحقول الحقيقية فقط من SkillModel:
// level, importance, isMandatory, estimatedDuration, courses.length
// (لا يوجد difficulty أو nextSkills في الموديل الفعلي)
// ─────────────────────────────────────────────────────────────────────────────
class _MetaChipsRow extends StatelessWidget {
  final SkillModel skill;
  const _MetaChipsRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(
          icon: Icons.stairs,
          label: SkillUtils.levelShortLabel(skill.level),
          color: SkillUtils.levelColor(skill.level),
        ),
        _MetaChip(
          icon: Icons.speed,
          label: SkillUtils.difficultyLabel(skill.difficulty),
          color: SkillUtils.difficultyColor(skill.difficulty),
        ),
        _MetaChip(
          icon: Icons.trending_up,
          label: SkillUtils.importanceLabel(skill.importance),
          color: SkillUtils.importanceColor(skill.importance),
        ),
        _MetaChip(
          icon: Icons.access_time,
          label: skill.estimatedDuration,
          color: const Color(0xFF4ECDC4),
        ),
        _MetaChip(
          icon: Icons.school_outlined,
          label: '${skill.courses.length} كورس',
          color: const Color(0xFFFFB347),
        ),
        if (skill.isMandatory)
          _MetaChip(
            icon: Icons.check_circle_outline,
            label: 'إلزامية',
            color: const Color(0xFF2ECC71),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final int progress;
  final String fieldId;
  final String skillId;
  final GlobalLearningState state;

  const _ProgressCard({
    required this.progress,
    required this.fieldId,
    required this.skillId,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final completedCourses =
        state
            .userProfile
            ?.fieldProgress[fieldId]
            ?.skillsProgress[skillId]
            ?.coursesProgress
            .values
            .where((c) => c.isCompleted)
            .length ??
        0;
    final totalCourses =
        state.getSkillData(fieldId, skillId)?.courses.length ?? 0;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تقدمك في المهارة',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '$progress%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                '$completedCourses/$totalCourses',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'كورسات مكتملة',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
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
              Icon(icon, color: const Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bullet List (whatYouWillLearn / realWorldApplications)
// ─────────────────────────────────────────────────────────────────────────────
class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _BulletList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chips Card (prerequisites)
// ─────────────────────────────────────────────────────────────────────────────
class _ChipsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;
  final Function(String) onTap;
  final GlobalLearningState? state;
  final String? fieldId;

  const _ChipsCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
    required this.onTap,
    this.state,
    this.fieldId,
  });

  String _displayLabel(String id) {
    final skillName = state?.getSkillData(fieldId ?? '', id)?.name;
    if (skillName != null && skillName.isNotEmpty) return skillName;
    return id
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items
                    .map(
                      (id) => InkWell(
                        onTap: () => onTap(id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _displayLabel(id),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.open_in_new, size: 12, color: color),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Learning Paths Card — uses LearningPath from skill_model.dart
// fields: order, title, description, topics, estimatedDuration
// ─────────────────────────────────────────────────────────────────────────────
class _LearningPathsCard extends StatefulWidget {
  final List<LearningPath> paths;
  const _LearningPathsCard({required this.paths});

  @override
  State<_LearningPathsCard> createState() => _LearningPathsCardState();
}

class _LearningPathsCardState extends State<_LearningPathsCard> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.route_outlined,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'مسار التعلم',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.paths.length} مرحلة',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...widget.paths.asMap().entries.map((entry) {
            final isExpanded = _expanded == entry.key;
            return _LearningPathTile(
              path: entry.value,
              isExpanded: isExpanded,
              onToggle:
                  () =>
                      setState(() => _expanded = isExpanded ? null : entry.key),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LearningPathTile extends StatelessWidget {
  final LearningPath path;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _LearningPathTile({
    required this.path,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${path.order}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        path.estimatedDuration,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      path.topics
                          .map(
                            (t) => Chip(
                              label: Text(
                                t,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: const Color(
                                0xFF6C63FF,
                              ).withOpacity(0.08),
                              side: const BorderSide(
                                color: Color(0xFF6C63FF),
                                width: 0.5,
                              ),
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Practice Projects Card — uses ProjectIdea from skill_model.dart
// fields: title, description, difficulty, estimatedTime, skillsUsed, steps
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectsCard extends StatelessWidget {
  final List<ProjectIdea> projects;
  const _ProjectsCard({required this.projects});

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
                Icons.build_circle_outlined,
                color: Color(0xFFFFB347),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'مشاريع تطبيقية',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...projects.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < projects.length - 1 ? 12 : 0,
              ),
              child: _ProjectTile(
                project: entry.value,
                diffColor: SkillUtils.difficultyColor(entry.value.difficulty),
                diffLabel: SkillUtils.difficultyLabel(entry.value.difficulty),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final ProjectIdea project;
  final Color diffColor;
  final String diffLabel;

  const _ProjectTile({
    required this.project,
    required this.diffColor,
    required this.diffLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: diffColor.withOpacity(0.4)),
                ),
                child: Text(
                  diffLabel,
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            project.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                project.estimatedTime,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.code, size: 13, color: Color(0xFF6C63FF)),
              const SizedBox(width: 4),
              Text(
                '${project.skillsUsed.length} مهارة',
                style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Courses Lazy List — يعرض أول 3 كورسات ويخفي الباقي حتى الضغط
// ─────────────────────────────────────────────────────────────────────────────
class _CoursesLazyList extends StatefulWidget {
  final List<CourseModel> courses;
  final String fieldId;
  final String skillId;
  final GlobalLearningState state;

  const _CoursesLazyList({
    required this.courses,
    required this.fieldId,
    required this.skillId,
    required this.state,
  });

  @override
  State<_CoursesLazyList> createState() => _CoursesLazyListState();
}

class _CoursesLazyListState extends State<_CoursesLazyList> {
  static const int _initialCount = 3;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final visibleCourses = _showAll
        ? widget.courses
        : widget.courses.take(_initialCount).toList();

    return Column(
      children: [
        ...visibleCourses.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CourseCard(
              course: entry.value,
              fieldId: widget.fieldId,
              skillId: widget.skillId,
              state: widget.state,
              index: entry.key,
            ),
          ),
        ),
        // زر "عرض المزيد" إذا كان عدد الكورسات أكثر من الـ initial
        if (!_showAll && widget.courses.length > _initialCount)
          TextButton.icon(
            onPressed: () => setState(() => _showAll = true),
            icon: const Icon(Icons.expand_more, color: Color(0xFF6C63FF)),
            label: Text(
              'عرض ${widget.courses.length - _initialCount} كورسات إضافية',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_showAll && widget.courses.length > _initialCount)
          TextButton.icon(
            onPressed: () => setState(() => _showAll = false),
            icon: const Icon(Icons.expand_less, color: Colors.grey),
            label: const Text(
              'عرض أقل',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Courses Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _CoursesSectionHeader extends StatelessWidget {
  final int count;
  const _CoursesSectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.play_lesson_outlined,
          color: Color(0xFF6C63FF),
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          'الكورسات المتاحة ($count)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course Card
// ─────────────────────────────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final String fieldId;
  final String skillId;
  final GlobalLearningState state;
  final int index;

  const _CourseCard({
    required this.course,
    required this.fieldId,
    required this.skillId,
    required this.state,
    required this.index,
  });

  CourseProgress? get _cp =>
      state
          .userProfile
          ?.fieldProgress[fieldId]
          ?.skillsProgress[skillId]
          ?.coursesProgress[course.id];

  bool get _isStarted => _cp != null;
  bool get _isCompleted => _cp?.isCompleted ?? false;

  int get _progressPercent {
    final cp = _cp;
    if (cp == null || cp.totalLessons == 0) return 0;
    return ((cp.completedLessons.length / cp.totalLessons) * 100).round();
  }

  Color get _platformColor {
    const c = {
      'YouTube': Color(0xFFFF0000),
      'Udemy': Color(0xFFEC5252),
      'Coursera': Color(0xFF0056D3),
      'edX': Color(0xFF1B1C1B),
      'Pluralsight': Color(0xFFF05A28),
      'LinkedIn Learning': Color(0xFF0A66C2),
    };
    return c[course.platform] ?? const Color(0xFF6C63FF);
  }

  IconData get _platformIcon {
    switch (course.platform) {
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

  Future<void> _openLink(BuildContext context) async {
    try {
      final uri = Uri.parse(course.link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!_isStarted) {
          await state.startCourse(
            fieldId: fieldId,
            skillId: skillId,
            courseId: course.id,
            totalLessons: (DurationParser.parseToHours(course.duration) * 3)
                .round()
                .clamp(5, 40),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border:
            _isCompleted
                ? Border.all(color: const Color(0xFF2ECC71), width: 1.5)
                : null,
      ),
      child: Column(
        children: [
          // Header — tappable → CourseDetailsScreen
          InkWell(
            onTap:
                () => context.push(
                  '/course-details/$fieldId/$skillId/${course.id}',
                ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _platformColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'course_${course.id}',
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _platformColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_platformIcon, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          course.instructor,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2ECC71),
                      size: 22,
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 14,
                    ),
                ],
              ),
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _CourseMeta(
                      icon: Icons.access_time,
                      label: course.duration,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    _CourseMeta(
                      icon: Icons.star,
                      label: course.rating.toStringAsFixed(1),
                      color: Colors.amber,
                    ),
                    _CourseMeta(
                      icon: Icons.language,
                      label:
                          course.language == 'ar'
                              ? '🇦🇪 عربي'
                              : '🇺🇸 إنجليزي',
                      color: const Color(0xFF4ECDC4),
                    ),
                    _CourseMeta(
                      icon: Icons.attach_money,
                      label:
                          course.price == 'free'
                              ? 'مجاني'
                              : course.priceAmount > 0
                              ? '\$${course.priceAmount.toStringAsFixed(2)}'
                              : 'مدفوع',
                      color:
                          course.price == 'free'
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFFF6B6B),
                    ),
                    _CourseMeta(
                      icon: Icons.computer,
                      label: course.platform,
                      color: _platformColor,
                    ),
                  ],
                ),
                if (_isStarted && !_isCompleted) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'تقدمك: $_progressPercent%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressPercent / 100,
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6C63FF),
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openLink(context),
                    icon: Icon(
                      _isCompleted
                          ? Icons.replay
                          : _isStarted
                          ? Icons.play_arrow
                          : Icons.open_in_new,
                      size: 18,
                    ),
                    label: Text(
                      _isCompleted
                          ? 'مراجعة الكورس'
                          : _isStarted
                          ? 'متابعة الكورس'
                          : 'بدء الكورس',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isCompleted
                              ? const Color(0xFF2ECC71)
                              : _isStarted
                              ? const Color(0xFF6C63FF)
                              : _platformColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CourseMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}


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
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
// Loading / Not Found Pages
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFoundPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const Icon(Icons.search_off, size: 64, color: Color(0xFF6C63FF)),
            const SizedBox(height: 16),
            const Text(
              'لم يتم العثور على المهارة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onBack, child: const Text('العودة')),
          ],
        ),
      ),
    );
  }
}
