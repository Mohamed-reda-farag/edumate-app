// ============================================================
// step3_experience.dart  — الخطوة 3: الخبرات العملية
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';
import '../../../widgets/cv_field.dart';
import '../../../widgets/cv_date_field.dart';
import '../../../widgets/cv_bullet_list.dart';

class Step3Experience extends StatelessWidget {
  const Step3Experience({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();

    return Obx(() {
      final cv = ctrl.cvModel.value;
      final isArabic = cv?.language == CVLanguage.arabic;
      final experiences = cv?.experiences ?? [];

      return Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isArabic ? 'الخبرات العملية' : 'Work Experience',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: ctrl.addExperience,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(isArabic ? 'إضافة' : 'Add'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          if (experiences.isEmpty)
            _EmptyState(isArabic: isArabic)
          else
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: experiences.length,
                onReorder: ctrl.reorderExperiences,
                itemBuilder: (context, i) {
                  return _ExperienceCard(
                    key: ValueKey(experiences[i].id),
                    exp: experiences[i],
                    isArabic: isArabic,
                    ctrl: ctrl,
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_history_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'لا توجد خبرات بعد\nاضغط "إضافة" لإضافة خبرتك الأولى'
                  : 'No experience added yet\nTap "Add" to add your first job',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatefulWidget {
  const _ExperienceCard({
    super.key,
    required this.exp,
    required this.isArabic,
    required this.ctrl,
  });

  final CVExperience exp;
  final bool isArabic;
  final CVController ctrl;

  @override
  State<_ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<_ExperienceCard> {
  late final TextEditingController _jobTitle;
  late final TextEditingController _company;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  late bool _isCurrent;
  late List<String> _responsibilities;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final exp = widget.exp;
    _jobTitle  = TextEditingController(text: exp.jobTitle);
    _company   = TextEditingController(text: exp.company);
    _city      = TextEditingController(text: exp.city);
    _country   = TextEditingController(text: exp.country);
    _startDate = TextEditingController(text: exp.startDate);
    _endDate   = TextEditingController(text: exp.endDate ?? '');
    _isCurrent = exp.isCurrent;
    _responsibilities = List.from(exp.responsibilities);
  }

  void _save() {
    widget.ctrl.updateExperience(
      CVExperience(
        id: widget.exp.id,
        jobTitle: _jobTitle.text.trim(),
        company: _company.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        startDate: _startDate.text.trim(),
        endDate: _isCurrent ? null : _endDate.text.trim(),
        isCurrent: _isCurrent,
        responsibilities: _responsibilities.where((r) => r.isNotEmpty).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _save();
    _jobTitle.dispose(); _company.dispose();
    _city.dispose(); _country.dispose();
    _startDate.dispose(); _endDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Card header
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.drag_handle, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _jobTitle.text.isEmpty
                          ? (isAr ? 'خبرة جديدة' : 'New Experience')
                          : '${_jobTitle.text}${_company.text.isNotEmpty ? " — ${_company.text}" : ""}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => widget.ctrl.removeExperience(widget.exp.id),
                    iconSize: 20,
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CVField(
                    ctrl: _jobTitle,
                    label: isAr ? 'المسمى الوظيفي *' : 'Job Title *',
                    hint: isAr ? 'مطور Flutter' : 'Flutter Developer',
                    icon: Icons.work_outline,
                    onChanged: (_) { _save(); setState(() {}); },
                  ),
                  const SizedBox(height: 10),
                  CVField(
                    ctrl: _company,
                    label: isAr ? 'اسم الشركة *' : 'Company Name *',
                    hint: isAr ? 'شركة التقنية' : 'Tech Company',
                    icon: Icons.business_outlined,
                    onChanged: (_) { _save(); setState(() {}); },
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
                          label: isAr ? 'تاريخ البداية' : 'Start Date',
                          hint: 'MM/YYYY',
                          onChanged: (_) => _save(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.green.shade200),
                                ),
                                child: Text(
                                  isAr ? 'حتى الآن' : 'Present',
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600),
                                ),
                              )
                            : CVDateField(
                                ctrl: _endDate,
                                label: isAr ? 'تاريخ الانتهاء' : 'End Date',
                                hint: 'MM/YYYY',
                                onChanged: (_) => _save(),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    value: _isCurrent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      isAr ? 'أعمل هنا حالياً' : 'I currently work here',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onChanged: (v) {
                      setState(() => _isCurrent = v ?? false);
                      _save();
                    },
                  ),
                  const SizedBox(height: 10),
                  // Responsibilities
                  CVBulletList(
                    items: _responsibilities,
                    label: isAr
                        ? 'المهام والمسؤوليات (نقطة لكل مهمة)'
                        : 'Responsibilities (one per bullet)',
                    hint: isAr
                        ? 'مثال: طورت تطبيق Flutter بأكثر من 50,000 مستخدم'
                        : 'e.g. Built a Flutter app with 50,000+ users',
                    isArabic: isAr,
                    onChanged: (items) {
                      _responsibilities = items;
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
