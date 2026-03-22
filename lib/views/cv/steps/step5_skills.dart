// ============================================================
// step5_skills.dart  — الخطوة 5: المهارات
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';

class Step5Skills extends StatelessWidget {
  const Step5Skills({super.key});

  static const _categoriesEn = [
    'Programming Languages',
    'Frameworks & Libraries',
    'Databases',
    'Cloud & DevOps',
    'Design',
    'Soft Skills',
    'Other',
  ];

  static const _categoriesAr = [
    'لغات البرمجة',
    'الأطر والمكتبات',
    'قواعد البيانات',
    'الحوسبة السحابية',
    'التصميم',
    'المهارات الشخصية',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();

    return Obx(() {
      final cv = ctrl.cvModel.value;
      final isAr = cv?.language == CVLanguage.arabic;
      final skills = cv?.skills ?? [];

      return Column(
        children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'المهارات' : 'Skills',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: ctrl.addSkill,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(isAr ? 'إضافة' : 'Add'),
                ),
              ],
            ),
          ),

          // ── ATS Tip ────────────────────────────────────────
          if (skills.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'نصيحة ATS: اكتب أسماء المهارات كما تظهر في إعلانات الوظائف تماماً'
                            : 'ATS Tip: Write skill names exactly as they appear in job postings',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Empty state ────────────────────────────────────
          if (skills.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAr
                          ? 'لا توجد مهارات\nاضغط "إضافة"'
                          : 'No skills added\nTap "Add"',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: skills.length,
                itemBuilder: (_, i) => _SkillRow(
                  key: ValueKey(skills[i].id),
                  skill: skills[i],
                  isAr: isAr,
                  ctrl: ctrl,
                  categories:
                      isAr ? _categoriesAr : _categoriesEn,
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ─── Skill Row ────────────────────────────────────────────────
class _SkillRow extends StatefulWidget {
  const _SkillRow({
    super.key,
    required this.skill,
    required this.isAr,
    required this.ctrl,
    required this.categories,
  });

  final CVSkill skill;
  final bool isAr;
  final CVController ctrl;
  final List<String> categories;

  @override
  State<_SkillRow> createState() => _SkillRowState();
}

class _SkillRowState extends State<_SkillRow> {
  late final TextEditingController _name;
  late SkillLevel _level;
  late String _category;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.skill.name);
    _level = widget.skill.level;
    _category = widget.skill.category.isEmpty
        ? widget.categories[0]
        : widget.skill.category;
  }

  void _save() {
    widget.ctrl.updateSkill(
      CVSkill(
        id: widget.skill.id,
        name: _name.text.trim(),
        level: _level,
        category: _category,
      ),
    );
  }

  @override
  void dispose() {
    _save();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final levelLabelsAr = ['مبتدئ', 'متوسط', 'متقدم', 'خبير'];
    final levelLabelsEn = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
    final levelLabels = isAr ? levelLabelsAr : levelLabelsEn;

    // تأكد أن الـ category موجود في القائمة
    final safeCategory = widget.categories.contains(_category)
        ? _category
        : widget.categories[0];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ── اسم المهارة + زر الحذف ──────────────────────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اسم المهارة' : 'Skill Name',
                      hintText: isAr ? 'مثال: Flutter' : 'e.g. Flutter',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) {
                      _save();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  onPressed: () =>
                      widget.ctrl.removeSkill(widget.skill.id),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── التصنيف + المستوى ────────────────────────────
            Row(
              children: [
                // Category
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: safeCategory,
                    decoration: InputDecoration(
                      labelText: isAr ? 'التصنيف' : 'Category',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    isExpanded: true,
                    items: widget.categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _category = v!);
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Level
                Expanded(
                  child: DropdownButtonFormField<SkillLevel>(
                    value: _level,
                    decoration: InputDecoration(
                      labelText: isAr ? 'المستوى' : 'Level',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: SkillLevel.values
                        .asMap()
                        .entries
                        .map((e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(
                                levelLabels[e.key],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _level = v!);
                      _save();
                    },
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
