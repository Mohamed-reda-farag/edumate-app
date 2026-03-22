// ============================================================
// step6_projects.dart  — الخطوة 6: المشاريع
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';
import '../../../widgets/cv_field.dart';
import '../../../widgets/cv_date_field.dart';

class Step6Projects extends StatelessWidget {
  const Step6Projects({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();

    return Obx(() {
      final cv = ctrl.cvModel.value;
      final isAr = cv?.language == CVLanguage.arabic;
      final projects = cv?.projects ?? [];

      return Column(
        children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'المشاريع' : 'Projects',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: ctrl.addProject,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(isAr ? 'إضافة' : 'Add'),
                ),
              ],
            ),
          ),

          // ── Empty state ────────────────────────────────────
          if (projects.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.rocket_launch_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAr
                          ? 'لا توجد مشاريع\nأضف مشاريعك لتبرز أمام المسؤولين'
                          : 'No projects added\nProjects help you stand out!',
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
                itemCount: projects.length,
                itemBuilder: (_, i) => _ProjectCard(
                  key: ValueKey(projects[i].id),
                  project: projects[i],
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

// ─── Project Card ─────────────────────────────────────────────
class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    super.key,
    required this.project,
    required this.isAr,
    required this.ctrl,
  });

  final CVProject project;
  final bool isAr;
  final CVController ctrl;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _link;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  late final TextEditingController _techInput;
  late List<String> _technologies;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _name      = TextEditingController(text: p.name);
    _desc      = TextEditingController(text: p.description);
    _link      = TextEditingController(text: p.link ?? '');
    _startDate = TextEditingController(text: p.startDate ?? '');
    _endDate   = TextEditingController(text: p.endDate ?? '');
    _techInput = TextEditingController();
    _technologies = List.from(p.technologies);
  }

  void _save() {
    widget.ctrl.updateProject(
      CVProject(
        id: widget.project.id,
        name: _name.text.trim(),
        description: _desc.text.trim(),
        technologies: _technologies,
        link: _link.text.trim().isEmpty ? null : _link.text.trim(),
        startDate: _startDate.text.trim().isEmpty
            ? null
            : _startDate.text.trim(),
        endDate: _endDate.text.trim().isEmpty
            ? null
            : _endDate.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _save();
    _name.dispose();
    _desc.dispose();
    _link.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _techInput.dispose();
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
                  const Icon(Icons.folder_outlined, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _name.text.isEmpty
                          ? (isAr ? 'مشروع جديد' : 'New Project')
                          : _name.text,
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
                        widget.ctrl.removeProject(widget.project.id),
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

          // ── Card Body ────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CVField(
                    ctrl: _name,
                    label: isAr ? 'اسم المشروع *' : 'Project Name *',
                    hint: isAr ? 'تطبيق التعلم' : 'Learning App',
                    icon: Icons.folder_outlined,
                    onChanged: (_) {
                      _save();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _desc,
                    maxLines: 3,
                    textDirection:
                        isAr ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'وصف المشروع'
                          : 'Project Description',
                      hintText: isAr
                          ? 'صف المشروع وتأثيره...'
                          : 'Describe the project and its impact...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => _save(),
                  ),
                  const SizedBox(height: 10),

                  // ── Technologies Chips ──────────────────
                  Text(
                    isAr ? 'التقنيات المستخدمة' : 'Technologies Used',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ..._technologies.map(
                        (t) => Chip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 12)),
                          onDeleted: () {
                            setState(() => _technologies.remove(t));
                            _save();
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      ActionChip(
                        label: Text(isAr ? '+ إضافة' : '+ Add'),
                        onPressed: () =>
                            _showAddTechDialog(context, isAr),
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
                          hint: isAr
                              ? 'MM/YYYY أو مستمر'
                              : 'MM/YYYY or Ongoing',
                          onChanged: (_) => _save(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CVField(
                    ctrl: _link,
                    label: isAr
                        ? 'رابط المشروع (اختياري)'
                        : 'Project Link (optional)',
                    hint: 'github.com/user/project',
                    icon: Icons.link,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => _save(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddTechDialog(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'إضافة تقنية' : 'Add Technology'),
        content: TextField(
          controller: _techInput,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isAr ? 'مثال: Flutter' : 'e.g. Flutter',
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              setState(() => _technologies.add(v.trim()));
              _save();
              _techInput.clear();
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_techInput.text.trim().isNotEmpty) {
                setState(
                    () => _technologies.add(_techInput.text.trim()));
                _save();
                _techInput.clear();
                Navigator.pop(context);
              }
            },
            child: Text(isAr ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}
