import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controllers/schedule_controller.dart';
import '../../controllers/semester_controller.dart';
import '../../models/academic_semester_model.dart';
import '../../models/schedule_time_settings.dart';
import '../../models/subject_schedule_entry_model.dart';
import '../schedule/semester_end_dialog.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const List<String> _kDays = [
  'السبت',
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
];

// ── Subject Color Palette ─────────────────────────────────────────────────────

const List<Color> _kSubjectBg = [
  Color(0xFFBBDEFB),
  Color(0xFFC8E6C9),
  Color(0xFFFFCCBC),
  Color(0xFFE1BEE7),
  Color(0xFFFFF9C4),
  Color(0xFFB2EBF2),
  Color(0xFFFFCDD2),
  Color(0xFFD7CCC8),
  Color(0xFFC5CAE9),
  Color(0xFFDCEDC8),
  Color(0xFFFFE0B2),
  Color(0xFFF8BBD0),
];

const List<Color> _kSubjectFg = [
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFBF360C),
  Color(0xFF6A1B9A),
  Color(0xFFF57F17),
  Color(0xFF00838F),
  Color(0xFFC62828),
  Color(0xFF4E342E),
  Color(0xFF283593),
  Color(0xFF33691E),
  Color(0xFFE65100),
  Color(0xFFAD1457),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

String _normalise(String name) => name.trim().toLowerCase();

Map<String, int> _buildColorIndex(List<SubjectScheduleEntry> entries) {
  final unique =
      entries.map((e) => _normalise(e.subjectName)).toSet().toList()..sort();
  return {
    for (var i = 0; i < unique.length; i++) unique[i]: i % _kSubjectBg.length,
  };
}

// ── ScheduleScreen ────────────────────────────────────────────────────────────

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _endDialogShown = false;

  // [FIX M1] لا نضع kDefaultTimeSlots كقيمة أولية هنا —
  // بدلاً من ذلك نستخدم null للتمييز بين "لم تُحمَّل بعد" و"الافتراضية".
  // هذا يمنع عرض الافتراضية في أي لحظة قبل اكتمال التحميل.
  List<ScheduleTimeSlot>? _timeSlots;

  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // [FIX M1] نُحمِّل الـ timeSlots أولاً قبل أي شيء آخر —
      // بهذا نضمن أن أول build بعد التهيئة يستخدم الأوقات الصحيحة
      // لا الافتراضية، حتى لو أطلق init() → notifyListeners() مبكراً.
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        final slots = await ScheduleTimeSettings.instance.load(uid);
        if (!mounted) return;
        setState(() => _timeSlots = slots);
      } else {
        setState(() => _timeSlots = List.from(kDefaultTimeSlots));
      }

      await context.read<SemesterController>().init();
      if (!mounted) return;
      final schedCtrl = context.read<ScheduleController>();
      await schedCtrl.init();
      if (!mounted) return;

      setState(() => _isBootstrapping = false);
      _checkSemesterEnd();
    });
  }

  // [FIX M1] دالة مستقلة لإعادة تحميل الـ slots —
  // تُستدعى بعد العودة من edit screen أو time slots editor.
  Future<void> _reloadTimeSlots() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final slots = await ScheduleTimeSettings.instance.load(uid);
    if (mounted) setState(() => _timeSlots = slots);
  }

  void _checkSemesterEnd() {
    if (_endDialogShown) return;
    final semCtrl = context.read<SemesterController>();
    if (semCtrl.isLoading) return;
    if (semCtrl.shouldShowEndDialog) {
      _endDialogShown = true;
      SemesterEndDialog.show(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isBootstrapping) return;
    _checkSemesterEnd();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl    = context.watch<ScheduleController>();
    final semCtrl = context.watch<SemesterController>();

    if (_isBootstrapping || semCtrl.isLoading || _timeSlots == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (semCtrl.needsSetup) {
      return _SetupGuardView(onSetup: () => context.push('/subjects-setup'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('جدولي'),
            if (semCtrl.activeSemester != null)
              Text(
                '${semCtrl.activeSemester!.type.labelAr} — '
                '${semCtrl.activeSemester!.academicYear}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'حساب GPA',
            onPressed: () => context.push('/schedule/gpa'),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'تحليل الأداء',
            onPressed: () => context.push('/schedule/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'الإنجازات',
            onPressed: () => context.push('/schedule/achievements'),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'إدارة المواد والامتحانات',
            onPressed: () => context.push('/schedule/subjects'),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'الجدول الذكي',
            onPressed: () => context.push('/schedule/plan'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // [FIX M1] بعد العودة من edit نُعيد تحميل الـ slots
        onPressed: () async {
          await context.push('/schedule/edit');
          if (!mounted) return;
          await _reloadTimeSlots();
        },
        icon: const Icon(Icons.edit),
        label: const Text('تعديل الجدول'),
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ctrl.error != null
              ? _ErrorView(error: ctrl.error!, onRetry: () => ctrl.init())
              : ctrl.schedule.isEmpty
                  ? _EmptyView(
                      onCreateSchedule: () async {
                        await context.push('/schedule/edit');
                        if (!mounted) return;
                        await _reloadTimeSlots();
                      },
                    )
                  : _ScheduleGrid(ctrl: ctrl, timeSlots: _timeSlots!),
    );
  }
}

// ── _SetupGuardView ───────────────────────────────────────────────────────────

class _SetupGuardView extends StatelessWidget {
  const _SetupGuardView({required this.onSetup});
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'مرحباً! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ابدأ بإعداد فصلك الدراسي لتتمكن من استخدام نظام الجدول',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onSetup,
                icon: const Icon(Icons.add),
                label: const Text('إعداد الفصل الدراسي'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 52)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _ScheduleGrid ─────────────────────────────────────────────────────────────

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({required this.ctrl, required this.timeSlots});
  final ScheduleController ctrl;
  final List<ScheduleTimeSlot> timeSlots;

  @override
  Widget build(BuildContext context) {
    final entryMap = <String, SubjectScheduleEntry>{
      for (final e in ctrl.schedule) '${e.row}_${e.col}': e,
    };

    final perfMap = <String, dynamic>{
      for (final p in ctrl.performances) _normalise(p.subjectName): p,
    };

    final colorIndex = _buildColorIndex(ctrl.schedule);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
            defaultColumnWidth: const FixedColumnWidth(100),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                children: [
                  const _HeaderCell(text: 'الوقت'),
                  ..._kDays.map((d) => _HeaderCell(text: d)),
                ],
              ),
              ...timeSlots.asMap().entries.map((slotEntry) {
                final row  = slotEntry.key;
                final slot = slotEntry.value;
                return TableRow(
                  children: [
                    _TimeCell(slot: slot.label),
                    ..._kDays.asMap().entries.map((dayEntry) {
                      final col   = dayEntry.key;
                      final entry = entryMap['${row}_$col'];
                      if (entry == null) return const _EmptyCell();

                      final norm = _normalise(entry.subjectName);
                      final perf = perfMap[norm];
                      final idx  = colorIndex[norm] ?? 0;

                      return _SubjectCell(
                        entry: entry,
                        bg: _kSubjectBg[idx],
                        fg: _kSubjectFg[idx],
                        priorityScore: perf?.priorityScore,
                        onTap: () {
                          final subjectId = entry.subjectId.isNotEmpty
                              ? entry.subjectId
                              : perf?.subjectId ?? norm.replaceAll(' ', '_');
                          final subjectName =
                              perf?.subjectName ?? entry.subjectName.trim();
                          context.push(
                            '/subject-details',
                            extra: {
                              'subjectId': subjectId,
                              'subjectName': subjectName,
                            },
                          );
                        },
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cells ─────────────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.slot});
  final String slot;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Text(
          slot,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 64);
}

class _SubjectCell extends StatelessWidget {
  const _SubjectCell({
    required this.entry,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.priorityScore,
  });

  final SubjectScheduleEntry entry;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final double? priorityScore;

  String _typeLabel(String t) {
    switch (t) {
      case 'lec': return 'محاضرة';
      case 'sec': return 'سيكشن';
      case 'lab': return 'معمل';
      default:    return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highPriority = (priorityScore ?? 0) > 60;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: highPriority
              ? Border.all(color: Colors.orange, width: 1.5)
              : Border.all(color: fg.withOpacity(0.25), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.subjectName.trim(),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _typeLabel(entry.sessionType),
              style: TextStyle(color: fg.withOpacity(0.75), fontSize: 9),
            ),
            if (highPriority)
              const Icon(Icons.warning_amber, size: 10, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreateSchedule});
  final VoidCallback onCreateSchedule;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('لا يوجد جدول بعد',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onCreateSchedule,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء جدول'),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
}