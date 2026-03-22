import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/subject_model.dart';

// ─── SubjectsSetupScreen ──────────────────────────────────────────────────────
//
// الغرض: المستخدم يُدخل مواده + درجة صعوبة كل مادة.
// يُستدعى في سيناريوهين:
//   1. أول تسجيل دخول / لا يوجد فصل نشط  → ثم يُعرض dialog الفصل
//   2. بدء فصل جديد بعد الأرشفة           → نفس الشاشة من الصفر
//
// بعد الحفظ: يذهب إلى SemesterSetupScreen مع تمرير المواد
// ──────────────────────────────────────────────────────────────────────────────

class SubjectsSetupScreen extends StatefulWidget {
  /// إذا كان true فهذا فصل صيفي
  final bool isSummer;

  const SubjectsSetupScreen({super.key, this.isSummer = false});

  @override
  State<SubjectsSetupScreen> createState() => _SubjectsSetupScreenState();
}

class _SubjectsSetupScreenState extends State<SubjectsSetupScreen> {
  // كل مادة: اسم + صعوبة
  final List<_SubjectDraft> _drafts = [_SubjectDraft()];
  bool _isSaving = false;

  void _addRow() {
    setState(() => _drafts.add(_SubjectDraft()));
  }

  void _removeRow(int index) {
    if (_drafts.length == 1) return; // نبقي صفاً واحداً على الأقل
    setState(() => _drafts.removeAt(index));
  }

  bool get _isValid =>
      _drafts.any((d) => d.nameController.text.trim().isNotEmpty);

  Future<void> _continue() async {
    // تحقق أن هناك مادة واحدة على الأقل
    final validDrafts = _drafts
        .where((d) => d.nameController.text.trim().isNotEmpty)
        .toList();

    if (validDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مادة واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('المستخدم غير مسجل الدخول');

      // نحتاج semesterId مؤقت لبناء Subject.id
      // سيُستبدل بـ ID الفصل الحقيقي عند إنشائه في SemesterSetupScreen
      final tempSemesterId = 'pending_${DateTime.now().millisecondsSinceEpoch}';

      final subjects = validDrafts.map((d) {
        return Subject.create(
          semesterId: tempSemesterId,
          name: d.nameController.text.trim(),
          difficulty: d.difficulty,
        );
      }).toList();

      // نمرر المواد لشاشة إعداد الفصل عبر extra
      if (mounted) {
        context.push('/semester-setup', extra: {
          'subjects': subjects,
          'isSummer': widget.isSummer,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.nameController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSummer ? 'مواد الفصل الصيفي' : 'مواد الفصل'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ما هي موادك هذا الفصل؟',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أضف موادك وحدد صعوبة كل منها — هذا يساعد على ترتيب الأولويات',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ── قائمة المواد ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _drafts.length,
              itemBuilder: (context, index) {
                return _SubjectRow(
                  key: ValueKey(_drafts[index].id),
                  draft: _drafts[index],
                  index: index,
                  canDelete: _drafts.length > 1,
                  onDelete: () => _removeRow(index),
                  onChanged: () => setState(() {}),
                );
              },
            ),
          ),

          // ── زر إضافة مادة ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مادة'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),

          // ── زر التالي ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: FilledButton(
              onPressed: (_isValid && !_isSaving) ? _continue : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('التالي: إعداد الفصل'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _SubjectRow ───────────────────────────────────────────────────────────────

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    super.key,
    required this.draft,
    required this.index,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  final _SubjectDraft draft;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── اسم المادة + زر الحذف ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم المادة ${index + 1}',
                      hintText: 'مثال: رياضيات، فيزياء...',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── درجة الصعوبة ─────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'الصعوبة:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (i) {
                  final level = i + 1;
                  final selected = draft.difficulty == level;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () {
                        draft.difficulty = level;
                        onChanged();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selected
                              ? _difficultyColor(level)
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? _difficultyColor(level)
                                : theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$level',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _difficultyLabel(draft.difficulty),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _difficultyColor(draft.difficulty),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

// ── _SubjectDraft ─────────────────────────────────────────────────────────────

class _SubjectDraft {
  final String id = UniqueKey().toString();
  final TextEditingController nameController = TextEditingController();
  int difficulty = 3;
}