import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/task_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AddCustomTaskScreen
// ══════════════════════════════════════════════════════════════════════════════

class AddCustomTaskScreen extends StatefulWidget {
  const AddCustomTaskScreen({super.key});

  @override
  State<AddCustomTaskScreen> createState() => _AddCustomTaskScreenState();
}

class _AddCustomTaskScreenState extends State<AddCustomTaskScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController  = TextEditingController();

  DateTime?  _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  // ignore: prefer_final_fields
  bool _isRecurring = false;
  bool _hasReminder = false;
  bool _isSaving    = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة مهمة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── عنوان المهمة ────────────────────────────────────────────────
            const _SectionLabel(label: 'عنوان المهمة *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                hintText: 'مثال: مراجعة ملاحظات الفيزياء',
                prefixIcon: Icons.title,
              ),
              textDirection: TextDirection.rtl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 20),

            // ── الوصف ────────────────────────────────────────────────────────
            const _SectionLabel(label: 'الوصف (اختياري)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              decoration: _inputDecoration(
                hintText: 'أضف تفاصيل إضافية...',
                prefixIcon: Icons.description_outlined,
              ),
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),

            // ── التاريخ ──────────────────────────────────────────────────────
            const _SectionLabel(label: 'التاريخ'),
            const SizedBox(height: 8),
            _DatePickerTile(
              selectedDate: _selectedDate,
              onTap: _pickDate,
              onClear: () => setState(() {
                _selectedDate = null;
                _startTime    = null;
                _endTime      = null;
                _hasReminder  = false;
              }),
            ),
            const SizedBox(height: 16),

            // ── الوقت ────────────────────────────────────────────────────────
            // [FIX] نختار وقت البداية ووقت النهاية بشكل منفصل بدل حساب
            // "H-(H+1)" الذي كان خاطئاً ويُنتج "23-24" عند اختيار الساعة 23
            const _SectionLabel(label: 'الوقت (اختياري)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'من',
                    selectedTime: _startTime,
                    onTap: _pickStartTime,
                    onClear: () => setState(() {
                      _startTime   = null;
                      _endTime     = null;
                      _hasReminder = false;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerTile(
                    label: 'إلى',
                    selectedTime: _endTime,
                    // يُفعَّل فقط إذا تم اختيار وقت البداية
                    onTap: _startTime != null ? _pickEndTime : null,
                    onClear: () => setState(() => _endTime = null),
                  ),
                ),
              ],
            ),

            // عرض المدة المحسوبة إذا تم اختيار الوقتين
            if (_startTime != null && _endTime != null) ...[
              const SizedBox(height: 8),
              _DurationPreview(
                startTime: _startTime!,
                endTime: _endTime!,
              ),
            ],
            const SizedBox(height: 20),

            // ── خيارات ──────────────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  // [FIX] isRecurring معطَّل مؤقتاً — الخيار محفوظ في Firestore
                  // لكن لا يوجد منطق تنفيذي خلفه بعد (تُفعَّل في تحديث قادم).
                  // تعطيله يمنع إيهام المستخدم بوظيفة غير منفَّذة.
                  SwitchListTile(
                    title: const Text('مهمة متكررة'),
                    subtitle: const Text('قريباً — هذه الميزة قيد التطوير'),
                    secondary: Icon(
                      Icons.repeat,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    value: _isRecurring,
                    onChanged: null, // معطَّل حتى يُنفَّذ منطق التكرار
                  ),
                  const Divider(height: 1, indent: 16),
                  SwitchListTile(
                    title: const Text('تذكيرني'),
                    subtitle: const Text('إشعار قبل موعد المهمة'),
                    secondary: Icon(
                      Icons.notifications_outlined,
                      color: _hasReminder
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    value: _hasReminder,
                    // [FIX] التذكير يتطلب وقت بداية محدد
                    onChanged: _startTime != null
                        ? (v) => setState(() => _hasReminder = v)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── زر الحفظ ────────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveTask,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ المهمة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Actions
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _pickDate() async {
    // [FIX] firstDate = اليوم فقط (بدون الأمس) لمنع إنشاء مهمة تظهر كـ missed
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'اختر تاريخ المهمة',
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        // [FIX] حُذف التعيين الصامت لـ _startTime = 12:00 —
        // كان يُعيَّن بدون علم المستخدم مما يجعل المهمة تظهر
        // كـ ongoing أو missed بناءً على الوقت الحالي
      });
    }
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'وقت بداية المهمة',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() {
        _startTime = time;
        // إذا كان وقت النهاية قبل البداية نُعيد ضبطه
        if (_endTime != null &&
            _toMinutes(_endTime!) <= _toMinutes(time)) {
          _endTime = null;
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    // الحد الأدنى = وقت البداية + 15 دقيقة
    final minEnd = _startTime != null
        ? _fromMinutes(_toMinutes(_startTime!) + 15)
        : const TimeOfDay(hour: 13, minute: 0);

    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? minEnd,
      helpText: 'وقت نهاية المهمة',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;

    if (_startTime != null && _toMinutes(time) <= _toMinutes(_startTime!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وقت النهاية يجب أن يكون بعد وقت البداية')),
        );
      }
      return;
    }
    setState(() => _endTime = time);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      DateTime? scheduledDateTime;
      String?   timeSlot;
      int?      durationMinutes;
      DateTime? dueDate;

      if (_selectedDate != null) {
        if (_startTime != null) {
          scheduledDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _startTime!.hour,
            _startTime!.minute,
          );

          // [FIX] timeSlot يُبنى من وقتي البداية والنهاية الحقيقيين
          // بصيغة ScheduleTimeSlot.label: "H:MM-H:MM"
          if (_endTime != null) {
            timeSlot =
                '${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}'
                '-'
                '${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}';

            // [FIX] حساب durationMinutes من وقتي البداية والنهاية —
            // كان غائباً مما يجعل شاشة التفاصيل لا تعرض "المدة"
            // رغم أن المستخدم اختار وقتي البداية والنهاية
            durationMinutes =
                _toMinutes(_endTime!) - _toMinutes(_startTime!);
          }
        } else {
          scheduledDateTime = _selectedDate;
        }

        // [FIX] dueDate = scheduledDate فقط لمهام بدون وقت محدد
        // لمهام بوقت محدد، dueDate = وقت النهاية
        dueDate = _endTime != null
            ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _endTime!.hour,
                _endTime!.minute,
              )
            : _selectedDate;
      }

      await context.read<TaskController>().addCustomTask(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            scheduledDate: scheduledDateTime,
            timeSlot: timeSlot,
            durationMinutes: durationMinutes,
            dueDate: dueDate,
            isRecurring: _isRecurring,
            hasReminder: _hasReminder,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ المهمة'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int m) =>
      TimeOfDay(hour: (m ~/ 60).clamp(0, 23), minute: m % 60);

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.selectedDate,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDate     = selectedDate != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasDate ? colorScheme.primary : colorScheme.outline,
            width: hasDate ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasDate ? colorScheme.primaryContainer.withOpacity(0.3) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: hasDate
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDate
                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : 'اختر التاريخ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasDate
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    size: 18, color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// [FIX] _TimePickerTile تقبل label ("من" / "إلى") وتدعم تعطيل الضغط
class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.selectedTime,
    required this.onTap,
    required this.onClear,
  });

  final String       label;
  final TimeOfDay?   selectedTime;
  final VoidCallback? onTap;
  final VoidCallback  onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTime     = selectedTime != null;
    final isEnabled   = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasTime
                ? colorScheme.primary
                : isEnabled
                    ? colorScheme.outline
                    : colorScheme.outline.withOpacity(0.4),
            width: hasTime ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasTime
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : !isEnabled
                  ? colorScheme.surfaceVariant.withOpacity(0.3)
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: hasTime
                  ? colorScheme.primary
                  : isEnabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withOpacity(0.4),
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
                  Text(
                    hasTime
                        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : '--:--',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: hasTime
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant.withOpacity(0.5),
                          fontWeight:
                              hasTime ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
            if (hasTime)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    size: 16, color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// يعرض المدة المحسوبة بين وقتي البداية والنهاية
class _DurationPreview extends StatelessWidget {
  const _DurationPreview({
    required this.startTime,
    required this.endTime,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startMin    = startTime.hour * 60 + startTime.minute;
    final endMin      = endTime.hour * 60 + endTime.minute;
    final duration    = endMin - startMin;

    if (duration <= 0) return const SizedBox.shrink();

    final h = duration ~/ 60;
    final m = duration % 60;
    final label = h > 0
        ? (m > 0 ? '$h ساعة $m دقيقة' : '$h ساعة')
        : '$m دقيقة';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'المدة: $label',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}