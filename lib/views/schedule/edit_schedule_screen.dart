import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controllers/schedule_controller.dart';
import '../../controllers/semester_controller.dart';
import '../../models/subject_schedule_entry_model.dart';
import '../../models/schedule_time_settings.dart';
import '../../models/subject_model.dart';
import '../../utils/stable_hash.dart';

const List<String> _kDays = [
  'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
];

class EditScheduleScreen extends StatefulWidget {
  const EditScheduleScreen({super.key});
  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late List<SubjectScheduleEntry> _entries;
  List<ScheduleTimeSlot> _timeSlots = List.from(kDefaultTimeSlots);
  bool _hasChanges  = false;
  bool _initialized = false;
  bool _isSaving    = false; // [FIX P3-1] flag لمنع double-tap على حفظ
  late final String _userId;

  int _entryCounter = 0;

  String _newEntryId() {
    _entryCounter++;
    return 'entry_${DateTime.now().millisecondsSinceEpoch}_$_entryCounter';
  }

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_userId.isNotEmpty) _loadTimeSlots();
  }

  Future<void> _loadTimeSlots() async {
    final slots = await ScheduleTimeSettings.instance.load(_userId);
    if (mounted) setState(() => _timeSlots = slots);
  }

  Future<void> _openTimeSlotsEditor() async {
    final changed = await context.push<bool>('/schedule/time-slots');
    if (changed == true) {
      await _loadTimeSlots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم تحديث أوقات المحاضرات'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _entries = List.from(context.read<ScheduleController>().schedule);
      _initialized = true;
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تجاهل التغييرات؟'),
        content: const Text('لديك تغييرات غير محفوظة. هل تريد الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('خروج')),
        ],
      ),
    );
    return result ?? false;
  }

  void _onCellTap(int row, int col) {
    final existing = _entries.cast<SubjectScheduleEntry?>().firstWhere(
      (e) => e?.row == row && e?.col == col,
      orElse: () => null,
    );
    if (existing != null) return;

    final subjects = context.read<SemesterController>().subjects;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CellEditorSheet(
        initial: SubjectScheduleEntry(
          id: _newEntryId(),
          subjectName: '',
          subjectId: '',
          row: row,
          col: col,
          sessionType: 'lec',
        ),
        subjects: subjects,
        onSave: (updated) {
          setState(() {
            _entries.removeWhere((e) => e.row == row && e.col == col);
            if (updated.subjectName.isNotEmpty) _entries.add(updated);
            _hasChanges = true;
          });
        },
        onClear: () {
          setState(() {
            _entries.removeWhere((e) => e.row == row && e.col == col);
            _hasChanges = true;
          });
        },
      ),
    );
  }

  void _onCellLongPress(int row, int col) {
    final existing = _entries.cast<SubjectScheduleEntry?>().firstWhere(
      (e) => e?.row == row && e?.col == col,
      orElse: () => null,
    );
    if (existing == null) return;

    final subjects = context.read<SemesterController>().subjects;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx2) => _CellEditorSheet(
                    initial: existing,
                    subjects: subjects,
                    onSave: (updated) {
                      setState(() {
                        _entries.removeWhere(
                            (e) => e.row == row && e.col == col);
                        if (updated.subjectName.isNotEmpty) {
                          _entries.add(updated);
                        }
                        _hasChanges = true;
                      });
                    },
                    onClear: () {
                      setState(() {
                        _entries.removeWhere(
                            (e) => e.row == row && e.col == col);
                        _hasChanges = true;
                      });
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
                  const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _entries.removeWhere(
                      (e) => e.row == row && e.col == col);
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // [FIX P3-1] إضافة try/catch لـ _save()
  //
  // المشكلة القديمة:
  //   await ctrl.saveSchedule(_entries);  ← إذا رمت exception
  //   context.pop();  ← يُنفَّذ دائماً!
  //   → المستخدم يخرج وكأن الحفظ نجح بينما البيانات لم تُحفظ
  //
  // الإصلاح:
  //   • try/catch يمنع context.pop() عند الفشل
  //   • _isSaving يمنع double-tap أثناء الحفظ
  //   • رسالة خطأ واضحة للمستخدم
  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await context.read<ScheduleController>().saveSchedule(_entries);
      if (!mounted) return;
      setState(() {
        _hasChanges = false;
        _isSaving   = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حفظ الجدول')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // لا نخرج من الشاشة — المستخدم يستطيع إعادة المحاولة
    }
  }

  void _showQuickCreateDialog() {
    final subjects = context.read<SemesterController>().subjects;
    if (subjects.isEmpty) {
      _showManualQuickAdd();
      return;
    }
    _showSubjectQuickAssign(subjects);
  }

  void _showManualQuickAdd() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة سريعة'),
        content: TextField(
          controller: textCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'أدخل المواد (سطر لكل مادة)\nمثال:\nرياضيات\nفيزياء',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final names = textCtrl.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              setState(() {
                for (final name in names) {
                  _assignToFirstFreeSlot(subjectName: name, subjectId: '');
                }
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showSubjectQuickAssign(List<Subject> subjects) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعيين مواد للجدول'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subjects.length,
            itemBuilder: (_, i) {
              final subject = subjects[i];
              final isAssigned =
                  _entries.any((e) => e.subjectId == subject.id);
              return ListTile(
                dense: true,
                title: Text(subject.name),
                trailing: isAssigned
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 18)
                    : const Icon(Icons.add_circle_outline, size: 18),
                onTap: isAssigned
                    ? null
                    : () {
                        setState(() {
                          _assignToFirstFreeSlot(
                            subjectName: subject.name,
                            subjectId: subject.id,
                          );
                          _hasChanges = true;
                        });
                        Navigator.pop(context);
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _assignToFirstFreeSlot({
    required String subjectName,
    required String subjectId,
  }) {
    outer:
    for (int r = 0; r < _timeSlots.length; r++) {
      for (int c = 0; c < _kDays.length; c++) {
        final occupied = _entries.any((e) => e.row == r && e.col == c);
        if (!occupied) {
          _entries.add(SubjectScheduleEntry(
            id: _newEntryId(),
            subjectName: subjectName,
            subjectId: subjectId,
            row: r,
            col: c,
            sessionType: 'lec',
          ));
          break outer;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScheduleController>();

    final entryMap = <String, SubjectScheduleEntry>{};
    for (final e in _entries) {
      entryMap['${e.row}_${e.col}'] = e;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الجدول'),
          actions: [
            IconButton(
              icon: const Icon(Icons.schedule),
              tooltip: 'تخصيص الأوقات',
              onPressed: _openTimeSlotsEditor,
            ),
            // [FIX P3-1] زر الحفظ معطَّل أثناء _isSaving أيضاً
            TextButton.icon(
              onPressed: (ctrl.isLoading || _isSaving) ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showQuickCreateDialog,
          icon: const Icon(Icons.flash_on),
          label: const Text('إنشاء سريع'),
        ),
        body: ctrl.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Table(
                      border: TableBorder.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                        width: 0.5,
                      ),
                      defaultColumnWidth: const FixedColumnWidth(100),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant,
                          ),
                          children: [
                            const _HeaderCell(text: 'الوقت'),
                            ..._kDays.map((d) => _HeaderCell(text: d)),
                          ],
                        ),
                        ..._timeSlots.asMap().entries.map((slotEntry) {
                          final row  = slotEntry.key;
                          final slot = slotEntry.value;
                          return TableRow(
                            children: [
                              _TimeCell(label: slot.label),
                              ..._kDays.asMap().entries.map((dayEntry) {
                                final col   = dayEntry.key;
                                final entry = entryMap['${row}_$col'];
                                return _EditableCell(
                                  entry: entry,
                                  onTap: () => _onCellTap(row, col),
                                  onLongPress: () =>
                                      _onCellLongPress(row, col),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Cell Widgets ──────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Text(label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 9)),
      );
}

class _EditableCell extends StatelessWidget {
  const _EditableCell({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });
  final SubjectScheduleEntry? entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  Color _bgColor(BuildContext context, String? type) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case 'lec': return cs.primaryContainer;
      case 'sec': return cs.tertiaryContainer;
      case 'lab': return const Color(0xFFFFE0B2);
      default:    return cs.surfaceVariant.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: entry != null ? onLongPress : null,
      child: Container(
        height: 64,
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _bgColor(context, entry?.sessionType),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: entry != null
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: entry != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry!.subjectName,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text(entry!.sessionType,
                      style: const TextStyle(fontSize: 9)),
                ],
              )
            : const Center(
                child: Icon(Icons.add, size: 16, color: Colors.grey),
              ),
      ),
    );
  }
}

// ── _CellEditorSheet ──────────────────────────────────────────────────────────

class _CellEditorSheet extends StatefulWidget {
  const _CellEditorSheet({
    required this.initial,
    required this.subjects,
    required this.onSave,
    required this.onClear,
  });

  final SubjectScheduleEntry initial;
  final List<Subject> subjects;
  final void Function(SubjectScheduleEntry) onSave;
  final VoidCallback onClear;

  @override
  State<_CellEditorSheet> createState() => _CellEditorSheetState();
}

class _CellEditorSheetState extends State<_CellEditorSheet> {
  late String _sessionType;
  Subject? _selectedSubject;
 
  @override
  void initState() {
    super.initState();
    _sessionType = widget.initial.sessionType.isEmpty
        ? 'lec'
        : widget.initial.sessionType;
 
    if (widget.initial.subjectId.isNotEmpty) {
      _selectedSubject = widget.subjects
          .cast<Subject?>()
          .firstWhere(
            (s) => s?.id == widget.initial.subjectId,
            orElse: () => null,
          );
    }
  }
 
  void _onSubjectSelected(Subject? subject) {
    setState(() => _selectedSubject = subject);
  }
 
  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'لا توجد مواد مضافة بعد',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف موادك الدراسية أولاً من شاشة إدارة المواد،\n'
              'ثم عد لتعيينها في الجدول.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    }
 
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تعديل الخلية',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
 
          DropdownButtonFormField<Subject>(
            value: _selectedSubject,
            decoration: const InputDecoration(
              labelText: 'اختر مادة',
              border: OutlineInputBorder(),
            ),
            items: widget.subjects
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Row(children: [
                        Text(s.name),
                        const SizedBox(width: 8),
                        _MiniDifficulty(difficulty: s.difficulty),
                      ]),
                    ))
                .toList(),
            onChanged: _onSubjectSelected,
          ),
          const SizedBox(height: 12),
 
          DropdownButtonFormField<String>(
            value: _sessionType,
            decoration: const InputDecoration(
              labelText: 'نوع الجلسة',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'lec', child: Text('محاضرة')),
              DropdownMenuItem(value: 'sec', child: Text('سيكشن')),
              DropdownMenuItem(value: 'lab', child: Text('معمل')),
            ],
            onChanged: (v) => setState(() => _sessionType = v ?? 'lec'),
          ),
          const SizedBox(height: 16),
 
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: const Text('مسح'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _selectedSubject == null
                      ? null
                      : () {
                          final entry = SubjectScheduleEntry(
                            id: widget.initial.id.isNotEmpty
                                ? widget.initial.id
                                : 'entry_${DateTime.now().millisecondsSinceEpoch}'
                                  '_${stableHash(_selectedSubject!.name)}',
                            subjectName: _selectedSubject!.name,
                            subjectId: _selectedSubject!.id,
                            row: widget.initial.row,
                            col: widget.initial.col,
                            sessionType: _sessionType,
                          );
                          widget.onSave(entry);
 
                          context
                              .read<ScheduleController>()
                              .updatePerformanceDifficulty(
                                _selectedSubject!.id,
                                _selectedSubject!.difficulty,
                                subjectName: _selectedSubject!.name,
                              );
                          Navigator.pop(context);
                        },
                  child: const Text('حفظ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── _MiniDifficulty ───────────────────────────────────────────────────────────

class _MiniDifficulty extends StatelessWidget {
  const _MiniDifficulty({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Colors.green, Colors.lightGreen, Colors.orange,
      Colors.deepOrange, Colors.red,
    ];
    final color = colors[(difficulty - 1).clamp(0, 4)];
    return Text(
      '★' * difficulty,
      style: TextStyle(fontSize: 10, color: color),
    );
  }
}