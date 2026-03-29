import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/subject_performance_model.dart';
import '../../models/study_session_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final schedCtrl = context.read<ScheduleController>();
      final attCtrl   = context.read<AttendanceController>();

      // [FIX P3-3] استُبدل شرط schedule.isEmpty بـ !isInitialized
      //
      // المشكلة القديمة:
      //   if (schedCtrl.schedule.isEmpty) await schedCtrl.init()
      //   schedule.isEmpty ليس مؤشراً موثوقاً للتهيؤ:
      //   • المستخدم قد لا يكون أضاف جدولاً بعد → schedule فارغ دائماً
      //   → init() تُستدعى في كل مرة يفتح AnalyticsScreen
      //   → كل فتح يُعيد التهيؤ الكامل (Firestore round-trip)
      //
      // الإصلاح: استخدام isInitialized flag الصريح
      //   → init() تُستدعى مرة واحدة فقط طوال عمر الـ controller
      if (!schedCtrl.isInitialized) await schedCtrl.init();
      if (!mounted) return;
      if (attCtrl.gamification == null) await attCtrl.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedCtrl  = context.watch<ScheduleController>();
    final attCtrl    = context.watch<AttendanceController>();
    final isLoading  = schedCtrl.isLoading || attCtrl.isLoading;
    final performances = schedCtrl.performances;

    final avgAttendance = performances.isEmpty
        ? 0.0
        : performances.fold(0.0, (sum, p) => sum + p.attendanceRate) /
            performances.length;

    final avgUnderstanding = performances.isEmpty
        ? 0.0
        : performances.fold(0.0, (sum, p) => sum + p.avgUnderstanding) /
            performances.length;

    final weekSessions      = schedCtrl.weekSessions;
    final completedThisWeek =
        weekSessions.where((s) => s.status == SessionStatus.completed).length;
    final totalThisWeek     = weekSessions.length;
    final complianceRate    =
        totalThisWeek == 0 ? 0.0 : completedThisWeek / totalThisWeek;
    final studyHoursThisWeek = weekSessions
            .where((s) => s.status == SessionStatus.completed)
            .fold(0,
                (sum, s) => sum + (s.actualDurationMinutes ?? s.durationMinutes)) /
        60.0;

    return Scaffold(
      appBar: AppBar(title: const Text('تحليل الأداء')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── الأداء العام ─────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الأداء العام',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _OverallStat(
                          label: 'متوسط الحضور',
                          value:
                              '${(avgAttendance * 100).toStringAsFixed(0)}%',
                          progress: avgAttendance,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _OverallStat(
                          label: 'متوسط الفهم',
                          value:
                              '${avgUnderstanding.toStringAsFixed(1)} / 5',
                          progress: avgUnderstanding / 5,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── أداء المواد ───────────────────────────────────────────────
                if (performances.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('لا توجد بيانات أداء بعد')),
                  )
                else ...[
                  Text('أداء المواد',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...performances
                      .map((p) => _SubjectPerformanceCard(perf: p)),
                ],

                const SizedBox(height: 12),

                // ── إحصائيات الأسبوع ──────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إحصائيات الأسبوع',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _WeekStatRow(
                          icon: Icons.timer_outlined,
                          label: 'ساعات المذاكرة',
                          value:
                              '${studyHoursThisWeek.toStringAsFixed(1)} ساعة',
                        ),
                        _WeekStatRow(
                          icon: Icons.check_circle_outline,
                          label: 'جلسات مكتملة',
                          value: '$completedThisWeek / $totalThisWeek',
                        ),
                        _WeekStatRow(
                          icon: Icons.trending_up,
                          label: 'نسبة الالتزام',
                          value:
                              '${(complianceRate * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── _OverallStat ──────────────────────────────────────────────────────────────

class _OverallStat extends StatelessWidget {
  const _OverallStat({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          color: color,
          backgroundColor: color.withOpacity(0.1),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

// ── _SubjectPerformanceCard ───────────────────────────────────────────────────

class _SubjectPerformanceCard extends StatelessWidget {
  const _SubjectPerformanceCard({required this.perf});
  final SubjectPerformance perf;

  @override
  Widget build(BuildContext context) {
    final highPriority = perf.priorityScore > 60;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(perf.subjectName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (highPriority)
                  const Tooltip(
                    message: 'يحتاج انتباهاً',
                    child: Icon(Icons.warning_amber,
                        color: Colors.orange, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'الحضور: ${(perf.attendanceRate * 100).toStringAsFixed(0)}% '
              '(${perf.attendedCount + perf.lateCount}/${perf.totalLectures} محاضرة)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 3),
            LinearProgressIndicator(
              value: perf.attendanceRate.clamp(0.0, 1.0),
              color: Colors.green,
              backgroundColor: Colors.green.withOpacity(0.1),
              minHeight: 5,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 6),
            Text(
              'متوسط فهم: ${perf.avgUnderstanding.toStringAsFixed(1)} / 5',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 3),
            LinearProgressIndicator(
              value: (perf.avgUnderstanding / 5).clamp(0.0, 1.0),
              color: Colors.blue,
              backgroundColor: Colors.blue.withOpacity(0.1),
              minHeight: 5,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 6),
            Text(
              'ساعات المذاكرة: ${perf.studyHoursLogged.toStringAsFixed(1)} ساعة',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (highPriority)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '⚠️ هذه المادة تحتاج مزيداً من الاهتمام',
                  style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _WeekStatRow ──────────────────────────────────────────────────────────────

class _WeekStatRow extends StatelessWidget {
  const _WeekStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}