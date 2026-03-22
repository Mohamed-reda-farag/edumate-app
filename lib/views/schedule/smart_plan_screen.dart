import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/global_learning_state.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/study_session_model.dart';

class SmartPlanScreen extends StatefulWidget {
  const SmartPlanScreen({super.key});

  @override
  State<SmartPlanScreen> createState() => _SmartPlanScreenState();
}

class _SmartPlanScreenState extends State<SmartPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // init() آمن — يتجاهل النداء الثاني بفضل _initialized flag
      context.read<ScheduleController>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    final schedCtrl    = context.read<ScheduleController>();
    final learningState = context.read<GlobalLearningState>();

    try {
      await schedCtrl.generateAndSavePlan(
        userPreferences: learningState.userProfile?.preferences,
      );
      if (!mounted) return;

      if (schedCtrl.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${schedCtrl.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم توليد الخطة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markSession(String sessionId, SessionStatus status) async {
    if (status == SessionStatus.completed) {
      double? completion;
      await showModalBottomSheet(
        context: context,
        builder: (ctx) => _CompletionSheet(
          onConfirm: (rate) {
            completion = rate;
          },
        ),
      );
      if (!mounted || completion == null) return;
      await context.read<AttendanceController>().updateSessionStatus(
        sessionId,
        SessionStatus.completed,
        completionRate: completion!,
      );
    } else {
      await context.read<AttendanceController>().updateSessionStatus(
        sessionId,
        SessionStatus.skipped,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attCtrl   = context.watch<AttendanceController>();
    final schedCtrl = context.watch<ScheduleController>();
    final isLoading = attCtrl.isLoading || schedCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول المذاكرة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة التوليد',
            onPressed: isLoading ? null : _generatePlan,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'اليوم'),
            Tab(text: 'هذا الأسبوع'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TodayTab(
                  sessions: attCtrl.todaySessions,
                  weekSessions: schedCtrl.weekSessions, // ← أضف هذا
                  onGenerate: _generatePlan,
                  onMark: _markSession,
                ),
                _WeekTab(
                  allSessions: schedCtrl.weekSessions,
                  onGenerate: _generatePlan,
                  onMark: _markSession,
                ),
              ],
            ),
    );
  }
}

// ── Today Tab ─────────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  const _TodayTab({
    required this.sessions,
    required this.weekSessions,
    required this.onGenerate,
    required this.onMark,
  });

  final List<StudySession> sessions;
  final List<StudySession> weekSessions; // ← لمعرفة هل توجد خطة أسبوعية
  final VoidCallback onGenerate;
  final Future<void> Function(String, SessionStatus) onMark;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      // هل توجد خطة أسبوعية مُولَّدة؟
      final hasWeekPlan = weekSessions.isNotEmpty;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasWeekPlan
                    ? Icons.check_circle_outline
                    : Icons.event_note_outlined,
                size: 72,
                color: hasWeekPlan ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                hasWeekPlan
                    ? 'لا توجد جلسات مذاكرة اليوم 🎉'
                    : 'لا توجد خطة مذاكرة بعد',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                hasWeekPlan
                    ? 'استغل وقتك في تعلم مهارة جديدة أو الاستمتاع بيومك ☀️'
                    : 'ولّد خطة مذاكرة أسبوعية ذكية بناءً على أولويات مواد',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (!hasWeekPlan) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('توليد خطة جديدة'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (_, i) =>
          _SessionCard(session: sessions[i], onMark: onMark),
    );
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onMark});
  final StudySession session;
  final Future<void> Function(String, SessionStatus) onMark;

  String _typeLabel(SessionType t) {
    switch (t) {
      case SessionType.explain:  return 'شرح';
      case SessionType.practice: return 'تمارين';
      case SessionType.review:   return 'مراجعة';
      case SessionType.activate: return 'تفعيل';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final isDone    = session.status == SessionStatus.completed;
    final isSkipped = session.status == SessionStatus.skipped;
    final isPlanned = session.status == SessionStatus.planned;

    return Dismissible(
      key: Key(session.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.close, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (!isPlanned) return false;
        if (direction == DismissDirection.startToEnd) {
          await onMark(session.id, SessionStatus.completed);
        } else {
          await onMark(session.id, SessionStatus.skipped);
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: isDone
            ? cs.surfaceVariant.withOpacity(0.5)
            : isSkipped
                ? cs.errorContainer.withOpacity(0.3)
                : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: Icon(
              isDone    ? Icons.check_circle :
              isSkipped ? Icons.cancel       : Icons.book_outlined,
              color: isDone    ? Colors.green :
                     isSkipped ? cs.error     : cs.primary,
            ),
          ),
          title: Text(
            session.subjectName,
            style: TextStyle(
              decoration:
                  isDone || isSkipped ? TextDecoration.lineThrough : null,
              color: isDone || isSkipped ? Colors.grey : null,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${session.timeSlot} • ${session.durationMinutes} دقيقة'
            ' • ${_typeLabel(session.sessionType)}',
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${session.priorityScore}',
                style: TextStyle(
                  color: session.priorityScore > 60
                      ? Colors.orange
                      : cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('أولوية', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Week Tab ──────────────────────────────────────────────────────────────────

class _WeekTab extends StatelessWidget {
  const _WeekTab({
    required this.allSessions,
    required this.onGenerate,
    required this.onMark,
  });
  final List<StudySession> allSessions;
  final VoidCallback onGenerate;
  final Future<void> Function(String, SessionStatus) onMark;

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSaturday = today.weekday == 6
        ? 0
        : today.weekday == 7
            ? 1
            : today.weekday + 1;
    final weekStart = today.subtract(Duration(days: daysSinceSaturday));
    final weekEnd   = weekStart.add(const Duration(days: 7));

    final weekSessions = allSessions.where((s) {
      final d = DateTime(
          s.scheduledDate.year, s.scheduledDate.month, s.scheduledDate.day);
      return !d.isBefore(weekStart) && d.isBefore(weekEnd);
    }).toList();

    if (weekSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('لا توجد خطة أسبوعية بعد'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('توليد خطة جديدة'),
            ),
          ],
        ),
      );
    }

    const dayOrder = [
      'السبت', 'الأحد', 'الاثنين', 'الثلاثاء',
      'الأربعاء', 'الخميس', 'الجمعة',
    ];

    final Map<String, List<StudySession>> byDay = {};
    for (final s in weekSessions) {
      byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }

    final sortedDays =
        dayOrder.where((d) => byDay.containsKey(d)).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: sortedDays.map((day) {
        final daySessions = byDay[day]!;
        final completed   = daySessions
            .where((s) => s.status == SessionStatus.completed)
            .length;
        final progress =
            daySessions.isEmpty ? 0.0 : completed / daySessions.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(day,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$completed/${daySessions.length}',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            ...daySessions
                .map((s) => _SessionCard(session: s, onMark: onMark)),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}

// ── Completion Sheet ──────────────────────────────────────────────────────────

class _CompletionSheet extends StatefulWidget {
  const _CompletionSheet({required this.onConfirm});
  final void Function(double) onConfirm;

  @override
  State<_CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<_CompletionSheet> {
  double _rate = 0.8;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('نسبة الإنجاز: ${(_rate * 100).toInt()}%',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Slider(
            min: 0, max: 1, divisions: 10,
            value: _rate,
            onChanged: (v) => setState(() => _rate = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              widget.onConfirm(_rate);
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}