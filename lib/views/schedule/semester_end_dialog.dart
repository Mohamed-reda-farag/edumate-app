import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/semester_controller.dart';
import '../../controllers/gamification_controller.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/academic_semester_model.dart';

class SemesterEndDialog extends StatefulWidget {
  const SemesterEndDialog._({required this.semester});

  final AcademicSemester semester;

  static Future<void> show(BuildContext context) {
    // [FIX P3-2] نقرأ semester هنا (context موثوق) قبل فتح الـ dialog
    final semester =
        context.read<SemesterController>().activeSemester;

    // إذا لا يوجد فصل نشط لا نعرض الـ dialog أصلاً
    if (semester == null) return Future.value();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SemesterEndDialog._(semester: semester),
    );
  }

  @override
  State<SemesterEndDialog> createState() => _SemesterEndDialogState();
}

class _SemesterEndDialogState extends State<SemesterEndDialog> {
  bool _isArchiving = false;

  Future<void> _handleAction(
    BuildContext context,
    SemesterEndAction action,
  ) async {
    final semesterCtrl     = context.read<SemesterController>();
    final gamificationCtrl = context.read<GamificationController>();
    final scheduleCtrl     = context.read<ScheduleController>();

    switch (action) {
      // ── تأجيل ──────────────────────────────────────────────────────────────
      case SemesterEndAction.snooze:
        await semesterCtrl.snoozeEndDialog();
        if (context.mounted) Navigator.of(context).pop();
        return;

      // ── بدء فصل جديد أو صيفي ─────────────────────────────────────────────
      case SemesterEndAction.startNew:
      case SemesterEndAction.startSummer:
        setState(() => _isArchiving = true);
        try {
          final gamificationData = gamificationCtrl.data;
          if (gamificationData == null) {
            if (context.mounted) {
              setState(() => _isArchiving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'لم تُحمَّل بيانات النقاط بعد — انتظر لحظة وحاول مجدداً',
                  ),
                ),
              );
            }
            return;
          }

          await semesterCtrl.archiveAndEndSemester(
            currentGamification: gamificationData,
            performances: scheduleCtrl.performances,
          );

          gamificationCtrl.resetSemesterBaseline();

          if (context.mounted) {
            Navigator.of(context).pop();
            context.push(
              '/subjects-setup',
              extra: {'isSummer': action == SemesterEndAction.startSummer},
            );
          }
        } catch (e) {
          if (context.mounted) {
            setState(() => _isArchiving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('حدث خطأ: $e')),
            );
          }
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // [FIX P3-2] نستخدم widget.semester مباشرةً — لا context.watch هنا
    final semester = widget.semester;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.school_outlined, size: 40),
        title: Text(
          'انتهى ${semester.type.labelAr}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: _isArchiving
            ? const _ArchivingProgress()
            : _DialogContent(semester: semester),
        actions: _isArchiving
            ? null
            : [
                TextButton(
                  onPressed: () =>
                      _handleAction(context, SemesterEndAction.snooze),
                  child: const Text('لاحقاً'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _handleAction(context, SemesterEndAction.startSummer),
                  icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                  label: const Text('فصل صيفي'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      _handleAction(context, SemesterEndAction.startNew),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('فصل جديد'),
                ),
              ],
      ),
    );
  }
}

// ── _DialogContent ────────────────────────────────────────────────────────────

class _DialogContent extends StatelessWidget {
  const _DialogContent({required this.semester});
  final AcademicSemester semester;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'أنهيت ${semester.type.labelAr} بنجاح 🎉\n'
          'حان وقت البداية الجديدة!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _StatRow(
                icon: Icons.book_outlined,
                label: 'عدد المواد',
                value: '${semester.subjects.length} مادة',
              ),
              const SizedBox(height: 6),
              _StatRow(
                icon: Icons.calendar_today_outlined,
                label: 'المدة',
                value: '${semester.totalWeeks} أسبوع',
              ),
              const SizedBox(height: 6),
              _StatRow(
                icon: Icons.school_outlined,
                label: 'الفصل',
                value: '${semester.type.labelAr} ${semester.academicYear}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ستُحفظ إنجازاتك وإحصائياتك تلقائياً',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── _ArchivingProgress ────────────────────────────────────────────────────────

class _ArchivingProgress extends StatelessWidget {
  const _ArchivingProgress();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('جاري حفظ إنجازات الفصل...', textAlign: TextAlign.center),
      ],
    );
  }
}

// ── _StatRow ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}