import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/semester_controller.dart';
import '../../controllers/schedule_controller.dart';
import '../../controllers/attendance_controller.dart';
import '../../models/academic_semester_model.dart';
import '../../models/subject_model.dart';
import 'exam_management_screen.dart'; // showExamDialog المشترك

// ─── SubjectManagementScreen ──────────────────────────────────────────────────
//
// شاشة موحَّدة تجمع:
//   1. إدارة المواد  — إضافة مادة جديدة + حذف مادة موجودة (مع cascade delete)
//   2. إدارة الامتحانات — إضافة / تعديل / حذف امتحانات لكل مادة
//
// تحل محل ExamManagementScreen السابقة.
// Route: /schedule/subjects

class SubjectManagementScreen extends StatelessWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semCtrl  = context.watch<SemesterController>();
    final semester = semCtrl.activeSemester;

    if (semester == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إدارة المواد والامتحانات')),
        body: const Center(child: Text('لا يوجد فصل دراسي نشط')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المواد والامتحانات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context, semester),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مادة'),
      ),
      body: semester.subjects.isEmpty
          ? _EmptySubjectsView(
              onAdd: () => _showAddSubjectDialog(context, semester),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  '${semester.type.labelAr} — ${semester.academicYear}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اضغط + لإضافة امتحان • اضغط 🗑 لحذف المادة بالكامل',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                ...semester.subjects.map((subject) {
                  final subjectExams = semester.exams
                      .where((e) => e.subjectId == subject.id)
                      .toList()
                    ..sort((a, b) => a.examDate.compareTo(b.examDate));

                  return _SubjectCard(
                    subject: subject,
                    exams: subjectExams,
                    onExamsChanged: (updatedExams) async {
                      final otherExams = semester.exams
                          .where((e) => e.subjectId != subject.id)
                          .toList();
                      await context.read<SemesterController>().saveSemester(
                            semester.copyWith(
                              exams: [...otherExams, ...updatedExams],
                            ),
                          );
                    },
                    onDeleteSubject: () =>
                        _confirmDeleteSubject(context, subject, semester),
                  );
                }),
              ],
            ),
    );
  }

  // ── إضافة مادة جديدة ───────────────────────────────────────────────────────

  Future<void> _showAddSubjectDialog(
    BuildContext context,
    AcademicSemester semester,
  ) async {
    final result = await showDialog<_NewSubjectData>(
      context: context,
      builder: (_) => const _AddSubjectDialog(),
    );
    if (result == null || !context.mounted) return;

    final newSubject = Subject.create(
      semesterId: semester.id,
      name: result.name,
      difficulty: result.difficulty,
    );

    final alreadyExists = semester.subjects.any(
      (s) => s.name.trim().toLowerCase() == newSubject.name.toLowerCase(),
    );
    if (alreadyExists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('المادة "${newSubject.name}" موجودة بالفعل'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // [FIX] سؤال عن الحضور السابق إذا مضى وقت على الفصل
    int attendedSoFar = 0;
    if (semester.currentWeek > 1 && context.mounted) {
      attendedSoFar = await showDialog<int>(
            context: context,
            builder: (_) => _AttendanceInitDialog(
              subjectName: newSubject.name,
              totalLectures: semester.totalLecturesPerSubject,
              currentWeek: semester.currentWeek,
            ),
          ) ??
          0;
    }

    if (!context.mounted) return;
    await context.read<SemesterController>().addSubject(newSubject);

    // [FIX] إنشاء SubjectPerformance فوراً لتلتقطه analytics
    if (context.mounted) {
      await context.read<ScheduleController>().initializeSubjectProgress(
        subjectId: newSubject.id,
        subjectName: newSubject.name,
        difficulty: newSubject.difficulty,
        attendedCount: attendedSoFar,
        totalLectures: semester.totalLecturesPerSubject,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة "${newSubject.name}" ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ── حذف مادة مع Cascade ────────────────────────────────────────────────────

  Future<void> _confirmDeleteSubject(
    BuildContext context,
    Subject subject,
    AcademicSemester semester,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.red, size: 36),
        title: const Text('حذف المادة؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'سيُحذف '),
                  TextSpan(
                    text: '"${subject.name}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' نهائياً مع جميع بياناتها:'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _ConsequenceRow(Icons.grid_view,    'إزالتها من الجدول الدراسي'),
            const _ConsequenceRow(Icons.bar_chart,    'حذف سجلات الحضور والأداء'),
            const _ConsequenceRow(Icons.event,        'حذف جميع امتحاناتها'),
            const _ConsequenceRow(Icons.book_outlined,'حذف جلسات المذاكرة الخاصة بها'),
            const _ConsequenceRow(Icons.emoji_events_outlined,
                                                      'خصم تأثيرها من حسابات الإنجازات'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لا يمكن التراجع عن هذه العملية',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await _deleteSubjectCascade(context, subject, semester);
  }

  Future<void> _deleteSubjectCascade(
    BuildContext context,
    Subject subject,
    AcademicSemester semester,
  ) async {
    try {
      final semCtrl   = context.read<SemesterController>();
      final schedCtrl = context.read<ScheduleController>();
      final attCtrl   = context.read<AttendanceController>();

      // 1. حذف المادة من الفصل — removeSubject يحذف المادة فقط
      await semCtrl.removeSubject(subject.id);

      // 2. حذف امتحانات هذه المادة صراحةً
      //    (removeSubject لا يحذفها — هي في قائمة منفصلة)
      final examsToDelete = semester.exams
          .where((e) => e.subjectId == subject.id)
          .toList();
      for (final exam in examsToDelete) {
        await semCtrl.removeExam(exam.subjectId, exam.type);
      }

      // 3. حذف خلايا الجدول الخاصة بالمادة
      final updatedSchedule = schedCtrl.schedule
          .where((e) => e.subjectId != subject.id)
          .toList();
      if (updatedSchedule.length != schedCtrl.schedule.length) {
        await schedCtrl.saveSchedule(updatedSchedule);
      }

      // 4. حذف بيانات الأداء
      await schedCtrl.deleteSubjectPerformance(subject.id);

      // 5. حذف جلسات المذاكرة للأسبوع الحالي
      await attCtrl.deleteSessionsBySubject(subject.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف "${subject.name}" وجميع بياناتها 🗑'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─── _SubjectCard ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.exams,
    required this.onExamsChanged,
    required this.onDeleteSubject,
  });

  final Subject subject;
  final List<SemesterExam> exams;
  final Future<void> Function(List<SemesterExam>) onExamsChanged;
  final VoidCallback onDeleteSubject;

  String _examTypeLabel(ExamType t) {
    switch (t) {
      case ExamType.midterm1:  return 'ميدتيرم 1';
      case ExamType.midterm2:  return 'ميدتيرم 2';
      case ExamType.finalExam: return 'نهائي';
    }
  }

  String _formatDateTime(DateTime dt) {
    final date = '${dt.day}/${dt.month}/${dt.year}';
    if (dt.hour == 0 && dt.minute == 0) return date;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$date — $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── رأس المادة ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DifficultyBadge(difficulty: subject.difficulty),
                    ],
                  ),
                ),
                // زر إضافة امتحان
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  tooltip: 'إضافة امتحان',
                  onPressed: () async {
                    final exam = await showExamDialog(
                      context,
                      subjectId: subject.id,
                      subjectName: subject.name,
                    );
                    if (exam != null) await onExamsChanged([...exams, exam]);
                  },
                ),
                // زر حذف المادة
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'حذف المادة',
                  onPressed: onDeleteSubject,
                ),
              ],
            ),

            // ── امتحانات المادة ───────────────────────────────────────────
            if (exams.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  'لم تُضف أي امتحانات بعد',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              )
            else
              ...exams.map((exam) {
                final isUrgent = exam.isUrgent;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.event,
                    size: 20,
                    color: isUrgent ? Colors.orange : null,
                  ),
                  title: Text(
                    _examTypeLabel(exam.type),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isUrgent ? Colors.orange : null,
                    ),
                  ),
                  subtitle: Text(_formatDateTime(exam.examDate)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // تعديل الامتحان
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Colors.blue),
                        tooltip: 'تعديل',
                        onPressed: () async {
                          final updated = await showExamDialog(
                            context,
                            subjectId: subject.id,
                            subjectName: subject.name,
                            existing: exam,
                          );
                          if (updated != null) {
                            await onExamsChanged(
                              exams.map((e) => e == exam ? updated : e).toList(),
                            );
                          }
                        },
                      ),
                      // حذف الامتحان
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        tooltip: 'حذف الامتحان',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('حذف الامتحان؟'),
                              content: Text(
                                'سيُحذف ${_examTypeLabel(exam.type)} من القائمة.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('إلغاء'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await onExamsChanged(
                              exams.where((e) => e != exam).toList(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ─── _AddSubjectDialog ────────────────────────────────────────────────────────

class _NewSubjectData {
  final String name;
  final int difficulty;
  const _NewSubjectData({required this.name, required this.difficulty});
}

class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final _nameCtrl = TextEditingController();
  int _difficulty = 3;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('إضافة مادة جديدة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم المادة
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اسم المادة',
              hintText: 'مثال: رياضيات، فيزياء...',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: canSave
                ? (_) => Navigator.pop(
                      context,
                      _NewSubjectData(
                        name: _nameCtrl.text.trim(),
                        difficulty: _difficulty,
                      ),
                    )
                : null,
          ),
          const SizedBox(height: 16),

          // درجة الصعوبة
          Text(
            'الصعوبة:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final level = i + 1;
              final selected = _difficulty == level;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _difficulty = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? _difficultyColor(level)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? _difficultyColor(level)
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$level',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _difficultyLabel(_difficulty),
            style: TextStyle(
              color: _difficultyColor(_difficulty),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: canSave
              ? () => Navigator.pop(
                    context,
                    _NewSubjectData(
                      name: _nameCtrl.text.trim(),
                      difficulty: _difficulty,
                    ),
                  )
              : null,
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  Color _difficultyColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 4: return Colors.deepOrange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _difficultyLabel(int level) {
    switch (level) {
      case 1: return 'سهلة';
      case 2: return 'متوسطة';
      case 3: return 'صعبة';
      case 4: return 'صعبة جداً';
      case 5: return 'قاتلة 🔥';
      default: return '';
    }
  }
}

// ─── Widgets مساعدة ──────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Colors.green, Colors.lightGreen, Colors.orange,
      Colors.deepOrange, Colors.red,
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

class _ConsequenceRow extends StatelessWidget {
  const _ConsequenceRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _AttendanceInitDialog extends StatefulWidget {
  const _AttendanceInitDialog({
    required this.subjectName,
    required this.totalLectures,
    required this.currentWeek,
  });
  final String subjectName;
  final int totalLectures;
  final int currentWeek;

  @override
  State<_AttendanceInitDialog> createState() => _AttendanceInitDialogState();
}

class _AttendanceInitDialogState extends State<_AttendanceInitDialog> {
  late int _attended;

  @override
  void initState() {
    super.initState();
    // قيمة افتراضية معقولة بناءً على الأسابيع المنقضية
    _attended = ((widget.currentWeek - 1) / 16 * widget.totalLectures)
        .round()
        .clamp(0, widget.totalLectures);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('حضور "${widget.subjectName}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'كم محاضرة حضرت حتى الآن؟',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_attended / ${widget.totalLectures}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Slider(
            min: 0,
            max: widget.totalLectures.toDouble(),
            divisions: widget.totalLectures,
            value: _attended.toDouble(),
            onChanged: (v) => setState(() => _attended = v.toInt()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: const Text('تخطي'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _attended),
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}

class _EmptySubjectsView extends StatelessWidget {
  const _EmptySubjectsView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.book_outlined, size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          const Text('لا توجد مواد في هذا الفصل'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('إضافة مادة'),
          ),
        ],
      ),
    );
  }
}