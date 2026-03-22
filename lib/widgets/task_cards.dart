// ══════════════════════════════════════════════════════════════════════════════
// task_cards.dart — جميع أنواع Task Cards في ملف واحد
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../models/task_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LectureTaskCard
// ══════════════════════════════════════════════════════════════════════════════

class LectureTaskCard extends StatelessWidget {
  const LectureTaskCard({
    super.key,
    required this.task,
    this.onAttendance,
  });

  final TaskModel task;
  // [FIX] nullable — null يعني الأزرار معطَّلة (قبل الموعد أو بعد الإكمال)
  final void Function(LectureAttendanceStatus)? onAttendance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = task.status == TaskStatus.completed;
    final isMissed = task.status == TaskStatus.missed;
    final isOngoing = task.status == TaskStatus.ongoing;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOngoing ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOngoing
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                _SessionTypeIcon(sessionType: task.sessionType ?? 'lec'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: (isCompleted || isMissed)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.sessionTypeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: task.status),
              ],
            ),
            const SizedBox(height: 12),

            // ── معلومات الوقت ──
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  task.timeSlot ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (task.durationMinutes != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.timer_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${task.durationMinutes} دقيقة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),

            // ── حالة الحضور إذا سُجّلت ──
            if (task.attendanceStatus != null) ...[
              const SizedBox(height: 8),
              _AttendanceChip(status: task.attendanceStatus!),
            ],

            // ── أزرار الحضور (تظهر فقط إذا كان onAttendance مُمرَّراً) ──
            // onAttendance == null يعني: قبل الموعد أو مكتملة → لا تُعرض الأزرار
            if (onAttendance != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'حضرت',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      onTap: () =>
                          onAttendance!(LectureAttendanceStatus.attended),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'غبت',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      onTap: () =>
                          onAttendance!(LectureAttendanceStatus.absent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'تأخرت',
                      icon: Icons.schedule,
                      color: Colors.orange,
                      onTap: () =>
                          onAttendance!(LectureAttendanceStatus.late),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// StudySessionTaskCard
// ══════════════════════════════════════════════════════════════════════════════

class StudySessionTaskCard extends StatelessWidget {
  const StudySessionTaskCard({
    super.key,
    required this.task,
    this.onStarted,
    this.onCompleted,
  });

  final TaskModel task;
  // [FIX] nullable — null يعني الزر معطَّل (قبل الموعد أو بعد الإكمال)
  final VoidCallback? onStarted;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = task.status == TaskStatus.completed;
    final isStarted =
        task.studySessionStatus == StudySessionTaskStatus.started;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isStarted ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isStarted
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_stories,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.subjectName ?? task.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                      ),
                      Text(
                        _sessionTypeFromTitle(task.title),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: task.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(task.timeSlot ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${task.durationMinutes ?? 120} دقيقة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
            // ── أزرار الجلسة (تظهر فقط إذا كان الـ callback مُمرَّراً) ──
            // null يعني: قبل الموعد أو مكتملة → لا تُعرض الأزرار
            if (onStarted != null || onCompleted != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  if (!isStarted && onStarted != null)
                    Expanded(
                      child: _ActionButton(
                        label: 'بدأت',
                        icon: Icons.play_circle_outline,
                        color: Colors.blue,
                        onTap: onStarted!,
                      ),
                    ),
                  if (isStarted) const SizedBox(width: 8),
                  if (onCompleted != null)
                    Expanded(
                      child: _ActionButton(
                        label: 'أكملت',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        onTap: onCompleted!,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sessionTypeFromTitle(String title) {
    if (title.contains('شرح')) return '📖 جلسة شرح';
    if (title.contains('تمارين')) return '✏️ جلسة تمارين';
    if (title.contains('مراجعة')) return '🔄 جلسة مراجعة';
    if (title.contains('تفعيل')) return '⚡ جلسة تفعيل';
    return '📚 جلسة مذاكرة';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SkillCourseTaskCard
// ══════════════════════════════════════════════════════════════════════════════

class SkillCourseTaskCard extends StatelessWidget {
  const SkillCourseTaskCard({
    super.key,
    required this.task,
    required this.onStart,
    required this.onComplete,
  });

  final TaskModel task;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (task.progressPercentage ?? 0) / 100;
    final current = task.currentLesson ?? 1;
    final total = task.totalLessons ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.school,
                      color: colorScheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.courseTitle ?? task.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📝 الدرس $current من $total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Progress Bar ──
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('ابدأ الآن'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('أكملت'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CustomTaskCard
// ══════════════════════════════════════════════════════════════════════════════

class CustomTaskCard extends StatelessWidget {
  const CustomTaskCard({
    super.key,
    required this.task,
    required this.onDetails,
    required this.onComplete,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onDetails;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCompleted
            ? BorderSide(color: Colors.green.shade300, width: 1)
            : BorderSide.none,
      ),
      color: isCompleted
          ? Colors.green.shade50
          : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.task_alt : Icons.push_pin_outlined,
                  color: isCompleted ? Colors.green : colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? colorScheme.onSurfaceVariant
                                  : null,
                            ),
                  ),
                ),
                if (task.isRecurring)
                  Icon(Icons.repeat,
                      size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.scheduledDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.scheduledDate!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (task.timeSlot != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.access_time,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      task.timeSlot!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('تفاصيل'),
                ),
                const Spacer(),
                if (!isCompleted)
                  IconButton(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                    tooltip: 'أكملت',
                  ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    final diff = taskDay.difference(today).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == -1) return 'أمس';
    if (diff > 1 && diff <= 7) return 'بعد $diff أيام';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _SessionTypeIcon extends StatelessWidget {
  const _SessionTypeIcon({required this.sessionType});
  final String sessionType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = sessionType == 'lec'
        ? colorScheme.primary
        : sessionType == 'sec'
            ? colorScheme.tertiary
            : Colors.orange;

    final icon = sessionType == 'lec'
        ? Icons.menu_book_outlined
        : sessionType == 'sec'
            ? Icons.group_outlined
            : Icons.science_outlined;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color color;

    switch (status) {
      case TaskStatus.upcoming:
        label = 'قادمة';
        color = Colors.blue;
        break;
      case TaskStatus.ongoing:
        label = 'جارية';
        color = Colors.orange;
        break;
      case TaskStatus.completed:
        label = 'مكتملة ✓';
        color = Colors.green;
        break;
      case TaskStatus.missed:
        label = 'فائتة';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  const _AttendanceChip({required this.status});
  final LectureAttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color color;
    late IconData icon;

    switch (status) {
      case LectureAttendanceStatus.attended:
        label = 'حضرت';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case LectureAttendanceStatus.absent:
        label = 'غبت';
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case LectureAttendanceStatus.late:
        label = 'تأخرت';
        color = Colors.orange;
        icon = Icons.schedule;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}