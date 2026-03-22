import 'package:flutter/material.dart';

import '../../models/academic_semester_model.dart';

Future<SemesterExam?> showExamDialog(
  BuildContext context, {
  required String subjectId,
  required String subjectName,
  SemesterExam? existing,
}) async {
  ExamType selectedType =
      existing?.type ?? ExamType.midterm1;
  DateTime selectedDate =
      existing?.examDate ?? DateTime.now().add(const Duration(days: 14));

  return showDialog<SemesterExam>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final hasTime = selectedDate.hour != 0 || selectedDate.minute != 0;
        final timeLabel = hasTime
            ? '${selectedDate.hour.toString().padLeft(2, '0')}:'
              '${selectedDate.minute.toString().padLeft(2, '0')}'
            : 'غير محدد';

        return AlertDialog(
          title: Text(
            existing == null
                ? 'إضافة امتحان — $subjectName'
                : 'تعديل امتحان — $subjectName',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── نوع الامتحان ───────────────────────────────────────────────
              DropdownButtonFormField<ExamType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع الامتحان',
                  border: OutlineInputBorder(),
                ),
                items: ExamType.values.map((t) {
                  String label;
                  switch (t) {
                    case ExamType.midterm1:  label = 'ميدتيرم 1';      break;
                    case ExamType.midterm2:  label = 'ميدتيرم 2';      break;
                    case ExamType.finalExam: label = 'امتحان نهائي';   break;
                  }
                  return DropdownMenuItem(value: t, child: Text(label));
                }).toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedType = v ?? ExamType.midterm1),
              ),
              const SizedBox(height: 12),

              // ── تاريخ الامتحان ─────────────────────────────────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('تاريخ الامتحان'),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 1)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        ));
                  }
                },
              ),

              // ── وقت البدء (اختياري) ────────────────────────────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('وقت البدء (اختياري)'),
                subtitle: Text(timeLabel),
                trailing: hasTime
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'مسح الوقت',
                        onPressed: () => setDialogState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                          );
                        }),
                      )
                    : null,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay(
                      hour: selectedDate.hour,
                      minute: selectedDate.minute,
                    ),
                    builder: (ctx, child) => MediaQuery(
                      data: MediaQuery.of(ctx)
                          .copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          picked.hour,
                          picked.minute,
                        ));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                SemesterExam(
                  subjectId: subjectId,
                  subjectName: subjectName,
                  type: selectedType,
                  examDate: selectedDate,
                  completed: existing?.completed ?? false,
                ),
              ),
              child: Text(existing == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        );
      },
    ),
  );
}