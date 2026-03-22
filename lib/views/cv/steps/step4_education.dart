// ============================================================
// step4_education.dart  — الخطوة 4: التعليم
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';
import '../../../widgets/cv_field.dart';
import '../../../widgets/cv_date_field.dart';
import '../../../widgets/cv_bullet_list.dart';

class Step4Education extends StatelessWidget {
  const Step4Education({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();

    return Obx(() {
      final cv = ctrl.cvModel.value;
      final isAr = cv?.language == CVLanguage.arabic;
      final educations = cv?.educations ?? [];

      return Column(
        children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'التعليم' : 'Education',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: ctrl.addEducation,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(isAr ? 'إضافة' : 'Add'),
                ),
              ],
            ),
          ),

          // ── Empty state ────────────────────────────────────
          if (educations.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAr
                          ? 'لا يوجد تعليم مضاف\nاضغط "إضافة"'
                          : 'No education added\nTap "Add"',
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
                itemCount: educations.length,
                itemBuilder: (_, i) => _EduCard(
                  key: ValueKey(educations[i].id),
                  edu: educations[i],
                  isAr: isAr,
                  ctrl: ctrl,
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ─── Education Card ───────────────────────────────────────────
class _EduCard extends StatefulWidget {
  const _EduCard({
    super.key,
    required this.edu,
    required this.isAr,
    required this.ctrl,
  });

  final CVEducation edu;
  final bool isAr;
  final CVController ctrl;

  @override
  State<_EduCard> createState() => _EduCardState();
}

class _EduCardState extends State<_EduCard> {
  late final TextEditingController _degree;
  late final TextEditingController _major;
  late final TextEditingController _institution;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  late final TextEditingController _gpa;
  late List<String> _achievements;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final edu = widget.edu;
    _degree      = TextEditingController(text: edu.degree);
    _major       = TextEditingController(text: edu.major);
    _institution = TextEditingController(text: edu.institution);
    _city        = TextEditingController(text: edu.city);
    _country     = TextEditingController(text: edu.country);
    _startDate   = TextEditingController(text: edu.startDate);
    _endDate     = TextEditingController(text: edu.endDate);
    _gpa         = TextEditingController(text: edu.gpa ?? '');
    _achievements = List.from(edu.achievements);
  }

  void _save() {
    widget.ctrl.updateEducation(
      CVEducation(
        id: widget.edu.id,
        degree: _degree.text.trim(),
        major: _major.text.trim(),
        institution: _institution.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        startDate: _startDate.text.trim(),
        endDate: _endDate.text.trim(),
        gpa: _gpa.text.trim().isEmpty ? null : _gpa.text.trim(),
        achievements:
            _achievements.where((a) => a.isNotEmpty).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _save();
    _degree.dispose();
    _major.dispose();
    _institution.dispose();
    _city.dispose();
    _country.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _gpa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // ── Card Header ──────────────────────────────────
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _institution.text.isEmpty
                          ? (isAr ? 'مؤسسة تعليمية جديدة' : 'New Institution')
                          : _institution.text,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    onPressed: () =>
                        widget.ctrl.removeEducation(widget.edu.id),
                    iconSize: 20,
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // ── Card Body ────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CVField(
                    ctrl: _degree,
                    label: isAr ? 'الدرجة العلمية *' : 'Degree *',
                    hint: isAr ? 'بكالوريوس' : 'Bachelor of Science',
                    icon: Icons.menu_book_outlined,
                    onChanged: (_) {
                      _save();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  CVField(
                    ctrl: _major,
                    label: isAr ? 'التخصص *' : 'Major *',
                    hint: isAr ? 'علوم الحاسب' : 'Computer Science',
                    icon: Icons.computer_outlined,
                    onChanged: (_) => _save(),
                  ),
                  const SizedBox(height: 10),
                  CVField(
                    ctrl: _institution,
                    label: isAr
                        ? 'اسم الجامعة / المعهد *'
                        : 'University / Institution *',
                    hint: isAr ? 'جامعة القاهرة' : 'Cairo University',
                    icon: Icons.apartment_outlined,
                    onChanged: (_) {
                      _save();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CVField(
                          ctrl: _city,
                          label: isAr ? 'المدينة' : 'City',
                          hint: isAr ? 'القاهرة' : 'Cairo',
                          icon: Icons.location_on_outlined,
                          onChanged: (_) => _save(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CVField(
                          ctrl: _country,
                          label: isAr ? 'الدولة' : 'Country',
                          hint: isAr ? 'مصر' : 'Egypt',
                          icon: Icons.flag_outlined,
                          onChanged: (_) => _save(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CVDateField(
                          ctrl: _startDate,
                          label: isAr ? 'من' : 'From',
                          hint: 'MM/YYYY',
                          onChanged: (_) => _save(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CVDateField(
                          ctrl: _endDate,
                          label: isAr ? 'إلى' : 'To',
                          hint: 'MM/YYYY',
                          onChanged: (_) => _save(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CVField(
                    ctrl: _gpa,
                    label: isAr
                        ? 'المعدل التراكمي (اختياري)'
                        : 'GPA (optional)',
                    hint: '3.8 / 4.0',
                    icon: Icons.grade_outlined,
                    onChanged: (_) => _save(),
                  ),
                  const SizedBox(height: 10),
                  CVBulletList(
                    items: _achievements,
                    label: isAr
                        ? 'إنجازات أكاديمية (اختياري)'
                        : 'Academic Achievements (optional)',
                    hint: isAr
                        ? 'تخرجت بامتياز، جائزة أفضل مشروع...'
                        : "Graduated with honors, Dean's List...",
                    isArabic: isAr,
                    onChanged: (items) {
                      _achievements = items;
                      _save();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
