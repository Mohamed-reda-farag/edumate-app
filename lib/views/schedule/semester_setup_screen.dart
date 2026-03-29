import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controllers/semester_controller.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/academic_semester_model.dart';
import '../../models/subject_model.dart';
import '../schedule/exam_management_screen.dart'; // [جديد] showExamDialog المشترك

class SemesterSetupScreen extends StatefulWidget {
  /// المواد القادمة من SubjectsSetupScreen
  final List<Subject> subjects;

  /// هل هذا فصل صيفي؟
  final bool isSummer;

  const SemesterSetupScreen({
    super.key,
    required this.subjects,
    this.isSummer = false,
  });

  @override
  State<SemesterSetupScreen> createState() => _SemesterSetupScreenState();
}

class _SemesterSetupScreenState extends State<SemesterSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // ── Page 1: معلومات الفصل ─────────────────────────────────────────────────
  late SemesterType _semesterType;
  int _weeksAgo          = 0;
  int _totalWeeks        = 16;
  int _lecturesPerSubject = 14;

  // ── Page 2: الامتحانات ────────────────────────────────────────────────────
  // subjectId → list of exams
  final Map<String, List<SemesterExam>> _examsBySubject = {};

  // ── Page 3: تهيئة التقدم ─────────────────────────────────────────────────
  // subjectId → عدد المحاضرات المحضورة حتى الآن
  final Map<String, int> _attendedSoFar = {};

  // [FIX S6] المواد بـ IDs الحقيقية — تُبنى مرة واحدة في initState
  late final List<Subject> _finalSubjects;

  // [FIX S1] semesterId يُوَلَّد مرة واحدة فقط في initState كـ late final.
  // كان داخل _finish() → يتغير عند كل ضغط "حفظ" (خطأ شبكة + إعادة محاولة)
  // مما يُنشئ فصلاً جديداً بـ ID مختلف بدلاً من إعادة حفظ نفس الفصل.
  late final String _semesterId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _semesterType =
        widget.isSummer ? SemesterType.summer : SemesterType.first;
        
    if (widget.isSummer) _totalWeeks = 8;
 
    _semesterId = 'sem_${DateTime.now().millisecondsSinceEpoch}';
 
    _finalSubjects = widget.subjects.map((s) => Subject.create(
          semesterId: _semesterId,
          name: s.name,
          difficulty: s.difficulty,
        )).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ: المستخدم غير مسجل الدخول')),
          );
        }
        return;
      }

      final semesterCtrl = context.read<SemesterController>();
      final schedCtrl    = context.read<ScheduleController>();

      final startDate = DateTime.now().subtract(Duration(days: _weeksAgo * 7));
      final endDate   = startDate.add(Duration(days: _totalWeeks * 7));

      final semesterId   = _semesterId;
      final finalSubjects = _finalSubjects;
      final subjectIdMap = <String, String>{};
      for (var i = 0; i < widget.subjects.length; i++) {
        subjectIdMap[widget.subjects[i].id] = finalSubjects[i].id;
      }

      final allExams = _examsBySubject.entries.expand((entry) {
        final realSubjectId = subjectIdMap[entry.key] ?? entry.key;
        return entry.value.map((exam) => SemesterExam(
              subjectId: realSubjectId,
              subjectName: exam.subjectName,
              type: exam.type,
              examDate: exam.examDate,
            ));
      }).toList();

      final semester = AcademicSemester(
        id: semesterId,
        userId: uid,
        type: _semesterType,
        startDate: startDate,
        endDate: endDate,
        totalLecturesPerSubject: _lecturesPerSubject,
        exams: allExams,
        createdAt: DateTime.now(),
        subjects: finalSubjects,
        academicYear: AcademicSemester.generateAcademicYear(startDate),
      );

      await semesterCtrl.saveSemester(semester);

      if (_weeksAgo > 0) {
        await _initializePastAttendance(schedCtrl, finalSubjects);
      }

      if (mounted) {
        schedCtrl.markUninitialized();
        context.go('/schedule');
      }
    } catch (e) {
      debugPrint('_finish error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  Future<void> _initializePastAttendance(
    ScheduleController schedCtrl,
    List<Subject> subjects,
  ) async {
    for (final subject in subjects) {
      final attended = _attendedSoFar[subject.id] ?? 0;
      if (attended == 0) continue;

      await schedCtrl.initializeSubjectProgress(
        subjectId: subject.id,
        subjectName: subject.name,
        difficulty: subject.difficulty,
        attendedCount: attended,
        totalLectures: _lecturesPerSubject,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد الفصل الدراسي'),
        automaticallyImplyLeading: _currentPage > 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevPage,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            borderRadius: BorderRadius.circular(0),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // ── Page 1 ───────────────────────────────────────────────
                _SemesterInfoPage(
                  semesterType: _semesterType,
                  weeksAgo: _weeksAgo,
                  totalWeeks: _totalWeeks,
                  lecturesPerSubject: _lecturesPerSubject,
                  isSummer: widget.isSummer,
                  onSemesterTypeChanged: (v) =>
                      setState(() => _semesterType = v),
                  onWeeksAgoChanged: (v) => setState(() => _weeksAgo = v),
                  onTotalWeeksChanged: (v) =>
                      setState(() => _totalWeeks = v),
                  onLecturesChanged: (v) =>
                      setState(() => _lecturesPerSubject = v),
                  onNext: _nextPage,
                ),
                // ── Page 2 ───────────────────────────────────────────────
                _ExamsSetupPage(
                  // [FIX S6] نمرر _finalSubjects ذات IDs الحقيقية
                  subjects: _finalSubjects,
                  examsBySubject: _examsBySubject,
                  onExamsChanged: (id, exams) =>
                      setState(() => _examsBySubject[id] = exams),
                  onNext: _nextPage,
                  onBack: _prevPage,
                ),
                // ── Page 3 ───────────────────────────────────────────────
                _ProgressInitPage(
                  subjects: _finalSubjects,
                  weeksAgo: _weeksAgo,
                  totalWeeks: _totalWeeks,
                  attendedSoFar: _attendedSoFar,
                  totalLectures: _lecturesPerSubject,
                  isSummer: widget.isSummer,
                  onAttendedChanged: (id, v) =>
                      setState(() => _attendedSoFar[id] = v),
                  onFinish: _finish,
                  isSaving: _isSaving,
                  onBack: _prevPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 1: معلومات الفصل ────────────────────────────────────────────────────

class _SemesterInfoPage extends StatelessWidget {
  const _SemesterInfoPage({
    required this.semesterType,
    required this.weeksAgo,
    required this.totalWeeks,
    required this.lecturesPerSubject,
    required this.isSummer,
    required this.onSemesterTypeChanged,
    required this.onWeeksAgoChanged,
    required this.onTotalWeeksChanged,
    required this.onLecturesChanged,
    required this.onNext,
  });

  final SemesterType semesterType;
  final int weeksAgo;
  final int totalWeeks;
  final int lecturesPerSubject;
  final bool isSummer;
  final void Function(SemesterType) onSemesterTypeChanged;
  final void Function(int) onWeeksAgoChanged;
  final void Function(int) onTotalWeeksChanged;
  final void Function(int) onLecturesChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('أخبرنا عن فصلك الدراسي',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('هذا يساعدنا على تنظيم جدولك بشكل أفضل',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),

        // نوع الفصل — نُخفيه للصيفي لأنه محدد مسبقاً
        if (!isSummer) ...[
          const Text('أي فصل دراسي؟',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<SemesterType>(
            segments: const [
              ButtonSegment(
                  value: SemesterType.first, label: Text('الفصل الأول')),
              ButtonSegment(
                  value: SemesterType.second, label: Text('الفصل الثاني')),
            ],
            selected: {semesterType},
            onSelectionChanged: (s) => onSemesterTypeChanged(s.first),
          ),
          const SizedBox(height: 24),
        ] else ...[
          // بيج الصيفي: إشارة واضحة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Text('فصل صيفي',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // كم أسبوع مضى
        Text('الفصل بدأ منذ: $weeksAgo أسبوع',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          min: 0,
          max: 12,
          divisions: 12,
          value: weeksAgo.toDouble(),
          label: weeksAgo == 0 ? 'هذا الأسبوع' : '$weeksAgo أسبوع',
          onChanged: (v) => onWeeksAgoChanged(v.toInt()),
        ),
        if (weeksAgo > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'تاريخ البداية المقدر: ${_formatDate(DateTime.now().subtract(Duration(days: weeksAgo * 7)))}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),

        // إجمالي أسابيع الفصل
        Text('إجمالي أسابيع الفصل: $totalWeeks أسبوع',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          min: isSummer ? 6 : 12,
          max: isSummer ? 12 : 20,
          divisions: isSummer ? 6 : 8,
          value: totalWeeks.toDouble().clamp(
                isSummer ? 6.0 : 12.0,
                isSummer ? 12.0 : 20.0,
              ),
          label: '$totalWeeks أسبوع',
          onChanged: (v) => onTotalWeeksChanged(v.toInt()),
        ),
        const SizedBox(height: 16),

        // عدد المحاضرات لكل مادة
        Text(
            'عدد المحاضرات الإجمالي لكل مادة: $lecturesPerSubject محاضرة',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          min: 8,
          max: 30,
          divisions: 22,
          value: lecturesPerSubject.toDouble(),
          label: '$lecturesPerSubject محاضرة',
          onChanged: (v) => onLecturesChanged(v.toInt()),
        ),
        const SizedBox(height: 32),

        FilledButton(
          onPressed: onNext,
          child: const Text('التالي: إعداد الامتحانات'),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ── Page 2: إعداد الامتحانات ─────────────────────────────────────────────────

class _ExamsSetupPage extends StatelessWidget {
  const _ExamsSetupPage({
    required this.subjects,
    required this.examsBySubject,
    required this.onExamsChanged,
    required this.onNext,
    required this.onBack,
  });

  final List<Subject> subjects;
  final Map<String, List<SemesterExam>> examsBySubject;
  final void Function(String, List<SemesterExam>) onExamsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  String _examTypeLabel(ExamType t) {
    switch (t) {
      case ExamType.midterm1:  return 'ميدتيرم 1';
      case ExamType.midterm2:  return 'ميدتيرم 2';
      case ExamType.finalExam: return 'نهائي';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('جدول الامتحانات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('أضف مواعيد امتحاناتك — هذا يؤثر على أولوية المذاكرة',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),

        if (subjects.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد مواد.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...subjects.map((subject) {
            final exams = examsBySubject[subject.id] ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(subject.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        _DifficultyBadge(difficulty: subject.difficulty),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...exams.map((exam) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.event, size: 18),
                          title: Text(_examTypeLabel(exam.type)),
                          subtitle: Text(
                              '${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              final updated =
                                  exams.where((e) => e != exam).toList();
                              onExamsChanged(subject.id, updated);
                            },
                          ),
                        )),
                    TextButton.icon(
                      onPressed: () async {
                        // [جديد] نستخدم showExamDialog المشترك من exam_management_screen
                        // بدلاً من _showAddExamDialog الداخلية — يدعم الآن تحديد الوقت
                        final exam = await showExamDialog(
                            context,
                            subjectId: subject.id,
                            subjectName: subject.name);
                        if (exam != null) {
                          onExamsChanged(subject.id, [...exams, exam]);
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة امتحان'),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),
        FilledButton(
          onPressed: onNext,
          child: const Text('التالي: تهيئة التقدم'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onNext,
          child: const Text('تخطي'),
        ),
      ],
    );
  }
}

// ── Page 3: تهيئة التقدم ─────────────────────────────────────────────────────

class _ProgressInitPage extends StatelessWidget {
  const _ProgressInitPage({
    required this.subjects,
    required this.weeksAgo,
    required this.totalWeeks,
    required this.attendedSoFar,
    required this.totalLectures,
    required this.isSummer,          // [FIX] مطلوب لتحديد معدل المحاضرات
    required this.onAttendedChanged,
    required this.onFinish,
    required this.isSaving,
    required this.onBack,
  });
 
  final List<Subject> subjects;
  final int weeksAgo;
  final int totalWeeks;
  final Map<String, int> attendedSoFar;
  final int totalLectures;
  final bool isSummer;               // [FIX]
  final void Function(String, int) onAttendedChanged;
  final VoidCallback onFinish;
  final bool isSaving;
  final VoidCallback onBack;
 
  // [FIX] حساب الحد الأقصى للمحاضرات المحضورة بناءً على نوع الترم
  int _maxAttendable() {
    // الصيفي: محاضرتان/أسبوع — العادي: محاضرة/أسبوع
    final lecturesPerWeek = isSummer ? 2 : 1;
    return (weeksAgo * lecturesPerWeek).clamp(0, totalLectures);
  }
 
  @override
  Widget build(BuildContext context) {
    final maxAttendable = _maxAttendable();
 
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('تهيئة التقدم الحالي',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          weeksAgo == 0
              ? 'ممتاز! الفصل بدأ للتو — لا تحتاج تهيئة.'
              : 'مضى $weeksAgo أسبوع — كم محاضرة حضرت لكل مادة حتى الآن؟',
          style: const TextStyle(color: Colors.grey),
        ),
        // [FIX] نوضح للمستخدم الحد الأقصى المنطقي
        if (weeksAgo > 0) ...[
          const SizedBox(height: 4),
          Text(
            isSummer
                ? 'الحد الأقصى: $maxAttendable محاضرة ($weeksAgo أسبوع × 2 محاضرة/أسبوع)'
                : 'الحد الأقصى: $maxAttendable محاضرة ($weeksAgo أسبوع × 1 محاضرة/أسبوع)',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 24),
 
        if (weeksAgo > 0 && subjects.isNotEmpty)
          ...subjects.map((subject) {
            // [FIX] نتأكد أن القيمة المخزَّنة لا تتجاوز الحد الأقصى
            final attended =
                (attendedSoFar[subject.id] ?? 0).clamp(0, maxAttendable);
 
            final effectiveTotalWeeks = totalWeeks > 0 ? totalWeeks : 16;
            final expectedSoFar =
                ((weeksAgo / effectiveTotalWeeks) * totalLectures)
                    .round()
                    .clamp(0, maxAttendable);
 
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(subject.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            _DifficultyBadge(difficulty: subject.difficulty),
                          ],
                        ),
                        // [FIX] نعرض الحد الأقصى بوضوح
                        Text(
                          '$attended / $maxAttendable',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المتوقع بعد $weeksAgo أسبوع: ~$expectedSoFar محاضرة',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                    Slider(
                      min: 0,
                      // [FIX] الحد الأقصى = maxAttendable وليس totalLectures
                      max: maxAttendable.toDouble(),
                      divisions: maxAttendable > 0 ? maxAttendable : 1,
                      value: attended.toDouble(),
                      onChanged: (v) =>
                          onAttendedChanged(subject.id, v.toInt()),
                    ),
                  ],
                ),
              ),
            );
          }),
 
        const SizedBox(height: 32),
        FilledButton(
          onPressed: isSaving ? null : onFinish,
          child: isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('ابدأ الفصل الدراسي 🚀'),
        ),
      ],
    );
  }
}

// ── _DifficultyBadge ──────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];
    final color = colors[(difficulty - 1).clamp(0, 4)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '★' * difficulty,
        style: TextStyle(fontSize: 9, color: color),
      ),
    );
  }
}