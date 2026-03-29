import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/semester_controller.dart';
import '../../models/gpa_model.dart';

// ─── نظام تقديرات GPA ────────────────────────────────────────────────────────

enum GpaScale { scale4, scale5 }

extension GpaScaleLabel on GpaScale {
  String get label => this == GpaScale.scale4 ? 'نظام 4.0' : 'نظام 5.0';
}

const String _kGpaPrevHoursSuffix = 'gpa_prev_hours';
const String _kGpaPrevGpaSuffix   = 'gpa_prev_gpa';
const String _kGpaScaleSuffix     = 'gpa_scale';

// نموذج مادة داخلي للشاشة
class _SubjectRow {
  String name;
  int hours;
  String? gradeLetter;

  _SubjectRow({required this.name, required this.hours});
}

// ─── GpaScreen ────────────────────────────────────────────────────────────────

class GpaScreen extends StatefulWidget {
  const GpaScreen({super.key});

  @override
  State<GpaScreen> createState() => _GpaScreenState();
}

class _GpaScreenState extends State<GpaScreen> {
  GpaScale _scale = GpaScale.scale4;
  List<_SubjectRow> _rows = [];

  bool _showCumulative = false;
  final _prevHoursCtrl = TextEditingController();
  final _prevGpaCtrl   = TextEditingController();

  // [FIX P3-5] uid يُقرأ مرة واحدة في initState ويُستخدم في كل عمليات الـ cache
  late final String _uid;
  Timer? _saveDebounce;

  // [FIX P3-5] مفاتيح الـ cache مع uid prefix
  String get _kPrevHours => '${_uid}_$_kGpaPrevHoursSuffix';
  String get _kPrevGpa   => '${_uid}_$_kGpaPrevGpaSuffix';
  String get _kScale     => '${_uid}_$_kGpaScaleSuffix';

  @override
  void initState() {
    super.initState();
    // [FIX P3-5] قراءة uid في initState — قبل أي عملية cache
    // fallback لـ 'anonymous' إذا لم يكن المستخدم مسجلاً (حالة نادرة)
    _uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    _loadSubjects();
    _loadPersistedData();

    _prevHoursCtrl.addListener(_persistData);
    _prevGpaCtrl.addListener(_persistData);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _prevHoursCtrl.removeListener(_persistData);
    _prevGpaCtrl.removeListener(_persistData);
    _prevHoursCtrl.dispose();
    _prevGpaCtrl.dispose();
    super.dispose();
  }

  // [FIX P3-5] استخدام المفاتيح المُعرَّفة بـ uid prefix
  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final savedHours = prefs.getString(_kPrevHours) ?? '';
      final savedGpa   = prefs.getString(_kPrevGpa)   ?? '';
      final savedScale = prefs.getInt(_kScale);

      if (savedHours.isNotEmpty) _prevHoursCtrl.text = savedHours;
      if (savedGpa.isNotEmpty)   _prevGpaCtrl.text   = savedGpa;
      if (savedScale != null) {
        _scale = savedScale == 5 ? GpaScale.scale5 : GpaScale.scale4;
      }
      if (savedHours.isNotEmpty) _showCumulative = true;
    });
  }

  void _persistData() {
    // debounce: ننتظر 500ms بعد آخر تغيير قبل الحفظ
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrevHours, _prevHoursCtrl.text);
      await prefs.setString(_kPrevGpa,   _prevGpaCtrl.text);
      await prefs.setInt(_kScale, _scale == GpaScale.scale5 ? 5 : 4);
    });
  }

  void _loadSubjects() {
    final subjects = context.read<SemesterController>().subjects;
    setState(() {
      _rows = subjects
          .map((s) => _SubjectRow(name: s.name, hours: 3))
          .toList();
      if (_rows.isEmpty) {
        _rows = [_SubjectRow(name: 'مادة 1', hours: 3)];
      }
    });
  }

  // ── حساب GPA الفصل ───────────────────────────────────────────────────────

  double? _calcSemesterGpa() {
    double totalPoints = 0;
    int    totalHours  = 0;
    for (final row in _rows) {
      if (row.gradeLetter == null) continue;
      final grade = gradeByLetter(row.gradeLetter!);
      if (grade == null) continue;
      totalPoints += grade.points(_scale) * row.hours;
      totalHours  += row.hours;
    }
    if (totalHours == 0) return null;
    return totalPoints / totalHours;
  }

  // ── حساب GPA التراكمي ────────────────────────────────────────────────────

  double? _calcCumulativeGpa() {
    final semGpa = _calcSemesterGpa();
    if (semGpa == null) return null;

    final prevHoursText = _prevHoursCtrl.text.trim();
    final prevGpaText   = _prevGpaCtrl.text.trim();
    if (prevHoursText.isEmpty || prevGpaText.isEmpty) return null;

    final prevHours = int.tryParse(prevHoursText);
    final prevGpa   = double.tryParse(prevGpaText);
    if (prevHours == null || prevGpa == null || prevHours < 0) return null;

    final semHours = _rows.fold<int>(
        0, (sum, r) => r.gradeLetter != null ? sum + r.hours : sum);
    if (semHours == 0) return null;

    final maxGpa         = _scale == GpaScale.scale4 ? 4.0 : 5.0;
    final clampedPrevGpa = prevGpa.clamp(0.0, maxGpa);

    return ((clampedPrevGpa * prevHours) + (semGpa * semHours)) /
        (prevHours + semHours);
  }

  int get _semesterTotalHours =>
      _rows.fold(0, (s, r) => s + r.hours);

  int get _gradedHours =>
      _rows.fold(0, (s, r) => r.gradeLetter != null ? s + r.hours : s);

  Color _gradeColor(String? letter) {
    if (letter == null) return Colors.grey.shade300;
    if (letter.startsWith('A')) return const Color(0xFF43A047);
    if (letter.startsWith('B')) return const Color(0xFF1E88E5);
    if (letter.startsWith('C')) return const Color(0xFFFB8C00);
    if (letter.startsWith('D')) return const Color(0xFFE53935);
    return const Color(0xFFB71C1C); // F
  }

  String _gpaLabel(double gpa) {
    final max = _scale == GpaScale.scale4 ? 4.0 : 5.0;
    final pct = gpa / max;
    if (pct >= 0.93) return 'ممتاز';
    if (pct >= 0.80) return 'جيد جداً';
    if (pct >= 0.67) return 'جيد';
    if (pct >= 0.50) return 'مقبول';
    return 'ضعيف';
  }

  void _addRow() {
    setState(() {
      _rows.add(_SubjectRow(name: 'مادة ${_rows.length + 1}', hours: 3));
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final semGpa   = _calcSemesterGpa();
    final cumGpa   = _showCumulative ? _calcCumulativeGpa() : null;
    final maxScale = _scale == GpaScale.scale4 ? 4.0 : 5.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب GPA'),
        actions: [
          PopupMenuButton<GpaScale>(
            initialValue: _scale,
            onSelected: (s) {
              setState(() => _scale = s);
              _persistData();
            },
            itemBuilder: (_) => GpaScale.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_scale.label, style: theme.textTheme.labelLarge),
                const Icon(Icons.arrow_drop_down, size: 20),
              ]),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── بطاقة النتيجة ─────────────────────────────────────────────
          _ResultCard(
            semGpa:      semGpa,
            cumGpa:      cumGpa,
            maxScale:    maxScale,
            gpaLabel:    semGpa != null ? _gpaLabel(semGpa) : null,
            cumLabel:    cumGpa != null ? _gpaLabel(cumGpa) : null,
            gradedHours: _gradedHours,
            totalHours:  _semesterTotalHours,
          ),
          const SizedBox(height: 20),

          // ── عنوان المواد ──────────────────────────────────────────────
          Row(children: [
            Text('مواد الفصل الحالي',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة مادة'),
            ),
          ]),
          const SizedBox(height: 8),

          // ── جدول المواد ───────────────────────────────────────────────
          ..._rows.asMap().entries.map((entry) {
            final i   = entry.key;
            final row = entry.value;
            return _SubjectRowCard(
              key: ValueKey('row_$i'),
              row: row,
              scale: _scale,
              gradeColor: _gradeColor(row.gradeLetter),
              onGradeChanged: (g) =>
                  setState(() => _rows[i].gradeLetter = g),
              onHoursChanged: (h) =>
                  setState(() => _rows[i].hours = h),
              onNameChanged: (n) =>
                  setState(() => _rows[i].name = n),
              onDelete: _rows.length > 1
                  ? () => setState(() => _rows.removeAt(i))
                  : null,
            );
          }),

          const SizedBox(height: 24),

          // ── GPA التراكمي ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.history_edu,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('GPA التراكمي (اختياري)',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Switch(
                      value: _showCumulative,
                      onChanged: (v) =>
                          setState(() => _showCumulative = v),
                    ),
                  ]),
                  if (_showCumulative) ...[
                    const SizedBox(height: 12),
                    Text(
                      'أدخل بيانات الفصول السابقة لحساب المعدل التراكمي',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _prevHoursCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ساعات سابقة',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _prevGpaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'GPA السابق',
                            hintText: 'مثال: 3.5',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixText: '/ ${maxScale.toStringAsFixed(1)}',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── _ResultCard ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.semGpa,
    required this.cumGpa,
    required this.maxScale,
    required this.gpaLabel,
    required this.cumLabel,
    required this.gradedHours,
    required this.totalHours,
  });

  final double? semGpa;
  final double? cumGpa;
  final double  maxScale;
  final String? gpaLabel;
  final String? cumLabel;
  final int gradedHours;
  final int totalHours;

  Color _gpaColor(double gpa) {
    final pct = gpa / maxScale;
    if (pct >= 0.93) return const Color(0xFF2E7D32);
    if (pct >= 0.80) return const Color(0xFF1565C0);
    if (pct >= 0.67) return const Color(0xFFF57F17);
    if (pct >= 0.50) return const Color(0xFFE53935);
    return const Color(0xFFB71C1C);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // ── GPA الفصل ────────────────────────────────────────────
          Column(children: [
            Text('GPA الفصل',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withOpacity(0.7))),
            const SizedBox(height: 4),
            Text(
              semGpa != null ? semGpa!.toStringAsFixed(2) : '—',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: semGpa != null
                    ? _gpaColor(semGpa!)
                    : theme.colorScheme.outline,
              ),
            ),
            if (gpaLabel != null)
              Text(gpaLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: _gpaColor(semGpa!),
                      fontWeight: FontWeight.w600)),
          ]),

          // ── GPA التراكمي ──────────────────────────────────────────
          if (cumGpa != null) ...[
            Container(
              width: 1,
              height: 60,
              color: theme.colorScheme.outline.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Column(children: [
              Text('GPA التراكمي',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withOpacity(0.7))),
              const SizedBox(height: 4),
              Text(
                cumGpa!.toStringAsFixed(2),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _gpaColor(cumGpa!),
                ),
              ),
              if (cumLabel != null)
                Text(cumLabel!,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: _gpaColor(cumGpa!),
                        fontWeight: FontWeight.w600)),
            ]),
          ],
        ]),

        if (semGpa != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: semGpa! / maxScale,
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.outline.withOpacity(0.2),
              valueColor:
                  AlwaysStoppedAnimation(_gpaColor(semGpa!)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'مكتمل $gradedHours من $totalHours ساعة',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer
                    .withOpacity(0.7)),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'اختر تقدير لكل مادة لحساب المعدل',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer
                      .withOpacity(0.6)),
            ),
          ),
      ]),
    );
  }
}

// ─── _SubjectRowCard ──────────────────────────────────────────────────────────

class _SubjectRowCard extends StatefulWidget {
  const _SubjectRowCard({
    super.key,
    required this.row,
    required this.scale,
    required this.gradeColor,
    required this.onGradeChanged,
    required this.onHoursChanged,
    required this.onNameChanged,
    required this.onDelete,
  });

  final _SubjectRow row;
  final GpaScale    scale;
  final Color       gradeColor;
  final void Function(String?) onGradeChanged;
  final void Function(int)     onHoursChanged;
  final void Function(String)  onNameChanged;
  final VoidCallback?          onDelete;

  @override
  State<_SubjectRowCard> createState() => _SubjectRowCardState();
}

class _SubjectRowCardState extends State<_SubjectRowCard> {
  late final TextEditingController _nameCtrl;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.row.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(children: [
          // ── اسم المادة ────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: _editingName
                ? TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                    ),
                    onSubmitted: (v) {
                      widget.onNameChanged(
                          v.trim().isEmpty ? widget.row.name : v.trim());
                      setState(() => _editingName = false);
                    },
                  )
                : GestureDetector(
                    onTap: () => setState(() => _editingName = true),
                    child: Row(children: [
                      Flexible(
                        child: Text(widget.row.name,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined,
                          size: 12, color: Colors.grey),
                    ]),
                  ),
          ),
          const SizedBox(width: 8),

          // ── عدد الساعات ───────────────────────────────────────────
          Container(
            width: 68,
            decoration: BoxDecoration(
              border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: widget.row.hours > 1
                    ? () => widget.onHoursChanged(widget.row.hours - 1)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.remove,
                      size: 14,
                      color: widget.row.hours > 1
                          ? theme.colorScheme.primary
                          : Colors.grey),
                ),
              ),
              Expanded(
                child: Text('${widget.row.hours}س',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                onTap: widget.row.hours < 10
                    ? () => widget.onHoursChanged(widget.row.hours + 1)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.add,
                      size: 14,
                      color: widget.row.hours < 10
                          ? theme.colorScheme.primary
                          : Colors.grey),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),

          // ── اختيار التقدير ────────────────────────────────────────
          Container(
            width: 90,
            decoration: BoxDecoration(
              color: widget.gradeColor.withOpacity(0.15),
              border:
                  Border.all(color: widget.gradeColor.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.row.gradeLetter,
                hint: Text('تقدير',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline)),
                isExpanded: true,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.gradeColor),
                items: [
                  const DropdownMenuItem<String>(
                      value: null,
                      child: Text('—',
                          style: TextStyle(fontSize: 12))),
                  ...kGrades.map((g) => DropdownMenuItem(
                        value: g.letter,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g.letter,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                              g.points(widget.scale).toStringAsFixed(2),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      )),
                ],
                onChanged: widget.onGradeChanged,
              ),
            ),
          ),

          // ── حذف ──────────────────────────────────────────────────
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.close,
                  size: 16, color: Colors.red),
              onPressed: widget.onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                  minWidth: 28, minHeight: 28),
            ),
        ]),
      ),
    );
  }
}