import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/schedule_time_settings.dart';

class TimeSlotsEditorScreen extends StatefulWidget {
  const TimeSlotsEditorScreen({super.key});
  @override
  State<TimeSlotsEditorScreen> createState() => _TimeSlotsEditorScreenState();
}

class _TimeSlotsEditorScreenState extends State<TimeSlotsEditorScreen> {
  List<ScheduleTimeSlot> _slots = [];
  bool _isLoading  = true;
  bool _isSaving   = false;
  bool _hasChanges = false;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _load();
  }

  Future<void> _load() async {
    final slots = await ScheduleTimeSettings.instance.load(_userId);
    if (mounted) setState(() { _slots = List.from(slots); _isLoading = false; });
  }

  String? _validate() {
    for (int i = 0; i < _slots.length; i++) {
      // [FIX TS1] كانت _validate تتحقق فقط من التعارض بين الفترات المتتالية
      // لكن لا تتحقق من أن endTime > startTime داخل نفس الفترة.
      // ممكن تسجيل فترة "10:00-8:00" بدون أي خطأ.
      final slot    = _slots[i];
      final startMs = slot.startHour * 60 + slot.startMinute;
      final endMs   = slot.endHour   * 60 + slot.endMinute;
      if (endMs <= startMs) {
        return 'الفترة ${i + 1}: وقت النهاية يجب أن يكون بعد وقت البداية';
      }
      if (_slots[i].durationMinutes < 30) return 'الفترة ${i+1}: المدة أقل من 30 دقيقة';
      if (i > 0) {
        final prev = _slots[i-1];
        final prevEnd = prev.endHour * 60 + prev.endMinute;
        final curSt  = _slots[i].startHour * 60 + _slots[i].startMinute;
        if (curSt < prevEnd) return 'الفترة ${i+1} تتعارض مع الفترة السابقة';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) { _snack(err, isError: true); return; }
    setState(() => _isSaving = true);
    await ScheduleTimeSettings.instance.save(_userId, _slots);
    if (mounted) {
      setState(() { _isSaving = false; _hasChanges = false; });
      _snack('✅ تم حفظ الأوقات');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resetToDefault() async {
    final ok = await _confirm('إعادة الضبط', 'ستعود الأوقات للإعدادات الافتراضية.');
    if (!ok) return;
    await ScheduleTimeSettings.instance.reset(_userId);
    await _load();
    setState(() => _hasChanges = true);
  }

  void _addSlot() {
    final last  = _slots.last;
    final newSt = last.endHour * 60 + last.endMinute;
    final newEn = newSt + 90;
    if (newEn > 23 * 60) { _snack('لا يمكن إضافة فترة — تجاوز الساعة 23:00', isError: true); return; }
    setState(() {
      _slots.add(ScheduleTimeSlot(
        startHour: newSt ~/ 60, startMinute: newSt % 60,
        endHour:   newEn ~/ 60, endMinute:   newEn % 60,
      ));
      _hasChanges = true;
    });
  }

  void _removeSlot(int i) {
    if (_slots.length <= 1) return;
    setState(() { _slots.removeAt(i); _hasChanges = true; });
  }

  Future<void> _editSlot(int i) async {
    final r = await showDialog<ScheduleTimeSlot>(
      context: context,
      builder: (_) => _SlotDialog(slot: _slots[i], index: i),
    );
    if (r != null) setState(() { _slots[i] = r; _hasChanges = true; });
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<bool> _confirm(String title, String body) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title), content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    return r ?? false;
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    return _confirm('تجاهل التغييرات؟', 'لديك تغييرات غير محفوظة.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // [FIX S10] WillPopScope مهجور منذ Flutter 3.12 → PopScope
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تخصيص أوقات المحاضرات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: 'إعادة الضبط',
              onPressed: _isLoading ? null : _resetToDefault,
            ),
            TextButton.icon(
              onPressed: (_isLoading || _isSaving || !_hasChanges) ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.35),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'اضغط على فترة لتعديل وقتها  •  اسحب لإعادة الترتيب',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: _slots.length,
                      onReorder: (o, n) {
                        setState(() {
                          if (n > o) n--;
                          final item = _slots.removeAt(o);
                          _slots.insert(n, item);
                          _hasChanges = true;
                        });
                      },
                      itemBuilder: (ctx, i) {
                        final slot = _slots[i];
                        final dur  = slot.durationMinutes;
                        final durTxt = dur >= 60
                            ? '${dur ~/ 60}س${dur % 60 > 0 ? " ${dur % 60}د" : ""}'
                            : '$durد';
                        return Card(
                          key: ValueKey('${slot.startHour}_${slot.startMinute}_${slot.endHour}_${slot.endMinute}'),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => _editSlot(i),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text('${i+1}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            title: Text(slot.label,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Text('المدة: $durTxt', style: theme.textTheme.bodySmall),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                              if (_slots.length > 1) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeSlot(i),
                                  child: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                ),
                              ],
                              const SizedBox(width: 4),
                              ReorderableDragStartListener(
                                index: i,
                                child: const Icon(Icons.drag_handle, color: Colors.grey),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: OutlinedButton.icon(
                      onPressed: _slots.length >= 12 ? null : _addSlot,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة فترة'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── _SlotDialog ───────────────────────────────────────────────────────────────

class _SlotDialog extends StatefulWidget {
  const _SlotDialog({required this.slot, required this.index});
  final ScheduleTimeSlot slot;
  final int index;
  @override
  State<_SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<_SlotDialog> {
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _start = TimeOfDay(hour: widget.slot.startHour, minute: widget.slot.startMinute);
    _end   = TimeOfDay(hour: widget.slot.endHour,   minute: widget.slot.endMinute);
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;
  String _fmt(TimeOfDay t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_toMin(_end) <= _toMin(_start)) {
          final ne = _toMin(_start) + 90;
          _end = TimeOfDay(hour: ne ~/ 60, minute: ne % 60);
        }
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final duration = _toMin(_end) - _toMin(_start);
    final isValid  = duration >= 30;

    return AlertDialog(
      title: Text('تعديل الفترة ${widget.index + 1}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _PickRow(label: 'وقت البداية', value: _fmt(_start), onTap: () => _pick(true)),
        const SizedBox(height: 12),
        _PickRow(label: 'وقت النهاية', value: _fmt(_end),   onTap: () => _pick(false)),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isValid
                ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                : theme.colorScheme.errorContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              isValid ? Icons.access_time : Icons.warning_amber,
              size: 16,
              color: isValid ? theme.colorScheme.primary : theme.colorScheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              isValid ? 'المدة: ${duration ~/ 60}س ${duration % 60}د' : 'المدة أقل من 30 دقيقة',
              style: TextStyle(
                color: isValid ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: isValid
              ? () => Navigator.pop(context, ScheduleTimeSlot(
                    startHour: _start.hour, startMinute: _start.minute,
                    endHour:   _end.hour,   endMinute:   _end.minute,
                  ))
              : null,
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(width: 8),
          Icon(Icons.access_time, size: 18, color: theme.colorScheme.primary),
        ]),
      ),
    );
  }
}