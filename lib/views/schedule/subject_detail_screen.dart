import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/schedule_controller.dart';
import '../../controllers/semester_controller.dart';
import '../../models/academic_semester_model.dart';
import '../../models/subject_performance_model.dart';
import '../../models/attendance_record_model.dart';

// [FIX 2-3-4] ملاحظة مهمة على السبب الجذري:
//
// المشاكل الثلاث (سجل الحضور فارغ، الإنجازات لا تُفتح، عداد الحضور 0%)
// لها سببان محتملان:
//
// السبب أ — subjectId غير متطابق:
//   المواد المضافة يدوياً قديماً (قبل إصلاح _CellEditorSheet) لها
//   entry.subjectId = '' → ScheduleScreen تُمرر subjectId مشتق من الاسم
//   → يختلف عن subjectId في AttendanceRecord و SubjectPerformance
//   → لا تطابق → بيانات فارغة.
//   الحل: مسح الجدول القديم وإعادة إنشائه بعد تطبيق إصلاح _CellEditorSheet.
//
// السبب ب — _preloadAllSubjectRecords لا تُحمِّل بيانات المادة الجديدة:
//   عند فتح SubjectDetailScreen تُستدعى loadSubjectRecords(widget.subjectId)
//   لكن إذا كان AttendanceController لم يُهيَّأ بعد (init لم يُستدعَ)
//   فـ getSubjectRecords ترجع [] دائماً حتى بعد loadSubjectRecords.
//   الإصلاح: نستدعي attCtrl.init() أولاً إذا لم يُهيَّأ.

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  final String subjectId;
  final String subjectName;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final attCtrl = context.read<AttendanceController>();

      // [FIX 2] نتأكد من تهيئة AttendanceController أولاً —
      // إذا لم يُهيَّأ فـ _recordsBySubject فارغة ولن تظهر أي سجلات
      // حتى بعد loadSubjectRecords.
      if (attCtrl.gamification == null) {
        await attCtrl.init();
      }
      if (!mounted) return;

      await attCtrl.loadSubjectRecords(widget.subjectId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attCtrl  = context.watch<AttendanceController>();
    final schedCtrl = context.watch<ScheduleController>();
    final semester  = context.watch<SemesterController>().activeSemester;

    // [FIX 2] البحث عن الأداء بـ subjectId أولاً، ثم بالاسم كـ fallback —
    // يحل مشكلة المواد التي لها subjectId مختلف في الـ performances
    SubjectPerformance? perf =
        schedCtrl.performances.where((p) => p.subjectId == widget.subjectId).firstOrNull;

    // fallback: ابحث بالاسم إذا لم تجد بالـ id
    perf ??= schedCtrl.performances
        .where((p) =>
            p.subjectName.trim().toLowerCase() ==
            widget.subjectName.trim().toLowerCase())
        .firstOrNull;

    final records = attCtrl.getSubjectRecords(widget.subjectId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الأداء'),
            Tab(text: 'سجل الحضور'),
          ],
        ),
      ),
      body: attCtrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _PerformanceTab(
                  perf: perf,
                  records: records,
                  semester: semester,
                ),
                _HistoryTab(records: records),
              ],
            ),
    );
  }
}

// ── Tab 1: الأداء ─────────────────────────────────────────────────────────────

class _PerformanceTab extends StatelessWidget {
  const _PerformanceTab({
    required this.perf,
    required this.records,
    required this.semester,
  });

  final SubjectPerformance? perf;
  final List<AttendanceRecord> records;
  final AcademicSemester? semester;

  @override
  Widget build(BuildContext context) {
    if (perf == null && records.isEmpty) {
      return const Center(child: Text('لا توجد بيانات أداء بعد'));
    }

    final cs = Theme.of(context).colorScheme;

    final lectureRecords = records
        .where((r) => r.sessionType == 'lec')
        .toList();

    // [FIX 4+5] نحسب attended و elapsed مع مراعاة الـ baseline
    // (المحاضرات المُدخَّلة في إعداد الفصل قبل بدء التسجيل)
    final int attended;
    final int elapsed;

    // الـ baseline = initialAttendedCount من إعداد الفصل
    // يمثل المحاضرات المحضورة قبل بدء استخدام التطبيق
    final baseline = perf?.initialAttendedCount ?? 0;

    if (lectureRecords.isNotEmpty) {
      // من السجلات الفعلية + الـ baseline
      final recordAttended = lectureRecords
          .where((r) =>
              r.status == AttendanceStatus.attended ||
              r.status == AttendanceStatus.late)
          .length;

      // [FIX 5] attended = السجلات الجديدة + baseline
      attended = recordAttended + baseline;

      // [FIX 5] elapsed = عدد السجلات الجديدة + baseline
      // لأن كل محاضرة في الـ baseline كانت منقضية بالفعل
      elapsed = lectureRecords.length + baseline;
    } else if (perf != null) {
      // لا توجد سجلات بعد — نعتمد على SubjectPerformance كاملاً
      // perf.attendedCount يشمل الـ baseline بالفعل (بعد PATCH 1C)
      attended = perf!.attendedCount + perf!.lateCount;
      elapsed  = _estimateElapsed(perf!);
    } else {
      attended = 0;
      elapsed  = 0;
    }

    final missed = (elapsed - attended).clamp(0, elapsed);
    final totalLectures = perf?.totalLectures ?? elapsed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إحصائيات',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _StatRow(
                  label: 'نسبة الحضور',
                  value: elapsed == 0
                      ? '-'
                      : '${(attended / elapsed * 100).toStringAsFixed(0)}%',
                ),
                _StatRow(
                  label: 'المحاضرات المحضورة',
                  value: '$attended من $elapsed',
                ),
                _StatRow(
                  label: 'المحاضرات الفائتة',
                  value: '$missed من $elapsed',
                ),
                _StatRow(
                  label: 'المحاضرات المنقضية',
                  value: '$elapsed من $totalLectures',
                ),
                const Divider(height: 20),
                _StatRow(
                  label: 'متوسط الفهم',
                  value: perf != null
                      ? '${perf!.avgUnderstanding.toStringAsFixed(1)} / 5'
                      : '-',
                ),
                _StatRow(
                  label: 'ساعات المذاكرة',
                  value: perf != null
                      ? '${perf!.studyHoursLogged.toStringAsFixed(1)} ساعة'
                      : '-',
                ),
                _StatRow(
                  label: 'درجة الصعوبة',
                  value: perf != null ? '${perf!.difficulty} / 5' : '-',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (perf != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مؤشر الأولوية للمذاكرة',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (perf!.priorityScore / 100).clamp(0.0, 1.0),
                    color: perf!.priorityScore > 60
                        ? Colors.orange
                        : cs.primary,
                    backgroundColor: cs.surfaceVariant,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${perf!.priorityScore.toStringAsFixed(0)} / 100',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('توصيات',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  ..._buildRecommendations(context, perf!, missed, elapsed),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildRecommendations(
    BuildContext context,
    SubjectPerformance perf,
    int missed,
    int elapsed,
  ) {
    final recs = <String>[];
    final attendanceRate =
        elapsed == 0 ? 0.0 : (perf.attendedCount + perf.lateCount) / elapsed;

    if (attendanceRate < 0.75 && elapsed > 0) {
      recs.add('⚠️ نسبة حضورك منخفضة — فاتتك $missed محاضرة حتى الآن');
    }
    if (perf.avgUnderstanding < 2.5) {
      recs.add('📖 مستوى الفهم منخفض — راجع المحاضرات أو اطلب مساعدة');
    } else if (perf.avgUnderstanding < 3.5) {
      recs.add('✏️ تدرب على مسائل إضافية لتحسين مستوى الفهم');
    }
    final recommendedHours = perf.difficulty * 2.0;
    if (perf.studyHoursLogged < recommendedHours) {
      final needed = (recommendedHours - perf.studyHoursLogged).ceil();
      recs.add('⏱️ خصص $needed ساعات إضافية لهذه المادة هذا الأسبوع');
    }
    if (perf.priorityScore > 75) {
      recs.add(
          '🎯 هذه المادة تحتاج اهتماماً عاجلاً — ضعها في أول جدول مذاكرتك');
    }
    if (recs.isEmpty) {
      recs.add('✅ أداؤك ممتاز في هذه المادة — استمر!');
    }

    return recs
        .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(r, style: Theme.of(context).textTheme.bodySmall),
            ))
        .toList();
  }

  int _estimateElapsed(SubjectPerformance perf) {
    if (semester == null) return perf.attendedCount + perf.lateCount;
    final totalWeeks    = semester!.totalWeeks;
    final currentWeek   = semester!.currentWeek;
    final totalLectures = perf.totalLectures;
    if (totalWeeks == 0) return 0;
    return (currentWeek / totalWeeks * totalLectures)
        .round()
        .clamp(0, totalLectures);
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
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
      );
}

// ── Tab 2: سجل الحضور ────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.records});
  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('لا توجد سجلات حتى الآن'));
    }

    final sorted = List<AttendanceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) => _RecordTile(record: sorted[i]),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final AttendanceRecord record;

  Color _statusColor() {
    switch (record.status) {
      case AttendanceStatus.attended: return Colors.green;
      case AttendanceStatus.late:     return Colors.orange;
      case AttendanceStatus.absent:   return Colors.red;
    }
  }

  String _statusLabel() {
    switch (record.status) {
      case AttendanceStatus.attended: return 'حضور';
      case AttendanceStatus.late:     return 'تأخر';
      case AttendanceStatus.absent:   return 'غياب';
    }
  }

  String _sessionTypeLabel() {
    switch (record.sessionType) {
      case 'lec': return 'محاضرة';
      case 'sec': return 'سيكشن';
      case 'lab': return 'معمل';
      default:    return 'جلسة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            record.lectureNumber.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _sessionTypeLabel(),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_statusLabel(),
                style: TextStyle(color: color, fontSize: 12)),
          ),
          const SizedBox(width: 6),
          if (record.understandingRating != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                record.understandingRating!,
                (_) => const Icon(Icons.star, size: 12, color: Colors.amber),
              ),
            ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${record.date.year}/${record.date.month}/${record.date.day}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (record.notes != null)
              Text(record.notes!,
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}