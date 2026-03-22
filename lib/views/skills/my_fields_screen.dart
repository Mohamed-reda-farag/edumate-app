import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/field_model.dart';
import '../../utils/skill_utils.dart';


class MyFieldsScreen extends StatefulWidget {
  final bool embedded;
  
  const MyFieldsScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<MyFieldsScreen> createState() => _MyFieldsScreenState();
}

class _MyFieldsScreenState extends State<MyFieldsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final state = context.read<GlobalLearningState>();
    final selectedFields = state.selectedFields;
    if (selectedFields.isNotEmpty) {
      await state.loadFieldsBatch(selectedFields);
    }
  }

  Future<void> _onRefresh() async {
    final state = context.read<GlobalLearningState>();
    final selectedFields = state.selectedFields;
    if (selectedFields.isNotEmpty) {
      await state.loadFieldsBatch(selectedFields);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // الوضع المدمج - محتوى فقط بدون Scaffold
      return _buildContent();
    }
    
    // الوضع المستقل - مع Scaffold كامل
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<GlobalLearningState>(
      builder: (context, state, _) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF6C63FF),
          child: CustomScrollView(
            slivers: [
              if (!widget.embedded) _buildSliverAppBar(context, state),
              if (state.isLoadingStaticData)
                const SliverFillRemaining(
                  child: _ShimmerFieldsList(),
                )
              else if (state.lastError != null &&
                  state.selectedFields.isEmpty)
                SliverFillRemaining(
                  child: _ErrorState(
                    error: state.lastError!,
                    onRetry: _loadData,
                  ),
                )
              else if (state.selectedFields.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyFieldsState(),
                )
              else ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, widget.embedded ? 24 : 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _OverallProgressCard(state: state),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'مجالاتي',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final fieldId = state.selectedFields[index];
                        final field = state.getFieldData(fieldId);
                        final isPrimary = fieldId == state.primaryField;
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: field == null
                                ? _FieldCardShimmer()
                                : _FieldCard(
                                    field: field,
                                    state: state,
                                    isPrimary: isPrimary,
                                    onTap: () => context.push(
                                        '/field-details/$fieldId'),
                                  ),
                          ),
                        );
                      },
                      childCount: state.selectedFields.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, GlobalLearningState state) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF6C63FF),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'مجالاتي 🎯',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تابع تقدمك في ${state.selectedFields.length} مجال',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
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
// Overall Progress Card
// ─────────────────────────────────────────────────────────────────────────────
class _OverallProgressCard extends StatelessWidget {
  final GlobalLearningState state;
  const _OverallProgressCard({required this.state});

  int _calcOverallProgress() {
    return state.getOverallProgressPercentage().round();
  }

  int _countActiveSkills() {
    return state.getActiveSkills().length;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calcOverallProgress();
    final activeSkills = _countActiveSkills();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'نظرة عامة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.school,
                  value: '$activeSkills',
                  label: 'مهارة نشطة',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.analytics,
                  value: '$progress%',
                  label: 'التقدم الإجمالي',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Card
// ─────────────────────────────────────────────────────────────────────────────
class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final GlobalLearningState state;
  final bool isPrimary;
  final VoidCallback onTap;

  const _FieldCard({
    required this.field,
    required this.state,
    required this.isPrimary,
    required this.onTap,
  });

@override
  Widget build(BuildContext context) {
    final fieldProgress = state.userProfile?.fieldProgress[field.id];
    final progressPct = fieldProgress?.overallProgress ?? 0;
    final currentLevel = fieldProgress?.currentLevel ?? 'foundation';

    // ── حساب الإحصائيات من skillsProgress مباشرة بدون 3 iterates منفصلة ──
    int activeSkillsCount = 0;
    int learnedSkillsCount = 0;
    int activeCoursesCount = 0;

    if (fieldProgress != null) {
      for (final skillProgress in fieldProgress.skillsProgress.values) {
        final pct = skillProgress.progressPercentage;

        if (pct >= 80) {
          learnedSkillsCount++;
        } else {
          // المهارة نشطة إذا كانت دون 80% ومستواها مناسب
          final skillData = state.getSkillData(field.id, skillProgress.skillId);
          if (skillData != null) {
            final skillLevelIdx = SkillUtils.levelIndex(skillData.level);
            final userLevelIdx = SkillUtils.levelIndex(currentLevel);
            if (skillLevelIdx <= userLevelIdx + 1) {
              activeSkillsCount++;
            }
          }
        }

        // عدد الكورسات النشطة في هذه المهارة
        activeCoursesCount += skillProgress.coursesProgress.values
            .where((c) => !c.isCompleted)
            .length;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? Border.all(color: const Color(0xFF6C63FF), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPrimary
                            ? [Color(0xFF6C63FF), Color(0xFF4ECDC4)]
                            : [Color(0xFF4ECDC4), Color(0xFF95E1D3)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        field.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                field.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPrimary
                                    ? const Color(0xFF6C63FF)
                                    : const Color(0xFF4ECDC4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPrimary ? 'أساسي' : 'ثانوي',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          field.description,
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
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 14,
                      color: isPrimary ? const Color(0xFF6C63FF) : const Color(0xFF4ECDC4)),
                  const SizedBox(width: 4),
                  Text(
                    'المستوى: ${SkillUtils.levelLabel(currentLevel)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? const Color(0xFF6C63FF) : const Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SkillCountBadge(
                    icon: Icons.play_circle_outline,
                    count: activeSkillsCount,
                    label: 'مهارة نشطة',
                    color: const Color(0xFF6C63FF),
                  ),
                  const SizedBox(width: 12),
                  _SkillCountBadge(
                    icon: Icons.school_outlined,
                    count: activeCoursesCount,
                    label: 'كورس جارٍ',
                    color: const Color(0xFFFFB347),
                  ),
                  const SizedBox(width: 12),
                  _SkillCountBadge(
                    icon: Icons.check_circle_outline,
                    count: learnedSkillsCount,
                    label: 'متعلمة',
                    color: const Color(0xFF4ECDC4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'التقدم',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A7A7A),
                        ),
                      ),
                      Text(
                        '$progressPct%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPrimary
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFF4ECDC4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPct / 100,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        isPrimary
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF4ECDC4),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'عرض التفاصيل',
                    style: TextStyle(
                      color: isPrimary
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF4ECDC4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_back_ios,
                    size: 12,
                    color: isPrimary
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF4ECDC4),
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

class _SkillCountBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _SkillCountBadge({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          '$count $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Loading
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerFieldsList extends StatelessWidget {
  const _ShimmerFieldsList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _FieldCardShimmer(),
      ),
    );
  }
}

class _FieldCardShimmer extends StatefulWidget {
  @override
  State<_FieldCardShimmer> createState() => _FieldCardShimmerState();
}

class _FieldCardShimmerState extends State<_FieldCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final shimmerHighlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(-1 + _anim.value * 2, 0),
            end: Alignment(1 + _anim.value * 2, 0),
            colors: [
              shimmerBase,
              shimmerHighlight,
              shimmerBase,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error States
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyFieldsState extends StatelessWidget {
  const _EmptyFieldsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 48,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لم تختر مجالاً بعد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أكمل الاستبيان لاختيار مجالك المفضل\nوابدأ رحلتك التعليمية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/survey'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('اختيار المجال'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}