// ============================================================
// step7_extras.dart  — الخطوة 7: الشهادات واللغات
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';
import '../../../widgets/cv_field.dart';
import '../../../widgets/cv_date_field.dart';

class Step7Extras extends StatelessWidget {
  const Step7Extras({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();

    return Obx(() {
      final cv = ctrl.cvModel.value;
      final isAr = cv?.language == CVLanguage.arabic;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ════════════════════════════════════════════════
            // قسم الشهادات
            // ════════════════════════════════════════════════
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? '📜 الشهادات والدورات' : '📜 Certifications',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: ctrl.addCertificate,
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(isAr ? 'إضافة' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final cert in (cv?.certificates ?? []))
              _CertCard(
                key: ValueKey(cert.id),
                cert: cert,
                isAr: isAr,
                ctrl: ctrl,
              ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ════════════════════════════════════════════════
            // قسم اللغات
            // ════════════════════════════════════════════════
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? '🌐 اللغات' : '🌐 Languages',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: ctrl.addLanguage,
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(isAr ? 'إضافة' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final lang in (cv?.languages ?? []))
              _LangRow(
                key: ValueKey(lang.id),
                lang: lang,
                isAr: isAr,
                ctrl: ctrl,
              ),

            // ── رسالة إذا كلاهما فارغ ───────────────────────
            if ((cv?.certificates ?? []).isEmpty &&
                (cv?.languages ?? []).isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr
                            ? 'أضف شهاداتك ولغاتك\nهذا القسم يُفرق بينك وبين المنافسين'
                            : 'Add your certifications and languages\nThis section sets you apart',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ─── Certificate Card ─────────────────────────────────────────
class _CertCard extends StatefulWidget {
  const _CertCard({
    super.key,
    required this.cert,
    required this.isAr,
    required this.ctrl,
  });

  final CVCertificate cert;
  final bool isAr;
  final CVController ctrl;

  @override
  State<_CertCard> createState() => _CertCardState();
}

class _CertCardState extends State<_CertCard> {
  late final TextEditingController _name;
  late final TextEditingController _issuer;
  late final TextEditingController _issueDate;
  late final TextEditingController _expiryDate;
  late final TextEditingController _credId;
  late final TextEditingController _credUrl;

  @override
  void initState() {
    super.initState();
    final c = widget.cert;
    _name       = TextEditingController(text: c.name);
    _issuer     = TextEditingController(text: c.issuer);
    _issueDate  = TextEditingController(text: c.issueDate);
    _expiryDate = TextEditingController(text: c.expiryDate ?? '');
    _credId     = TextEditingController(text: c.credentialId ?? '');
    _credUrl    = TextEditingController(text: c.credentialUrl ?? '');
  }

  void _save() {
    widget.ctrl.updateCertificate(
      CVCertificate(
        id: widget.cert.id,
        name: _name.text.trim(),
        issuer: _issuer.text.trim(),
        issueDate: _issueDate.text.trim(),
        expiryDate: _expiryDate.text.trim().isEmpty
            ? null
            : _expiryDate.text.trim(),
        credentialId: _credId.text.trim().isEmpty
            ? null
            : _credId.text.trim(),
        credentialUrl: _credUrl.text.trim().isEmpty
            ? null
            : _credUrl.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _save();
    _name.dispose();
    _issuer.dispose();
    _issueDate.dispose();
    _expiryDate.dispose();
    _credId.dispose();
    _credUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // ── اسم الشهادة + حذف ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: CVField(
                    ctrl: _name,
                    label: isAr ? 'اسم الشهادة *' : 'Certificate Name *',
                    hint: isAr
                        ? 'Flutter Development'
                        : 'Flutter Development',
                    icon: Icons.verified_outlined,
                    onChanged: (_) => _save(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () =>
                      widget.ctrl.removeCertificate(widget.cert.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CVField(
              ctrl: _issuer,
              label:
                  isAr ? 'الجهة المانحة *' : 'Issuing Organization *',
              hint: 'Google, Udemy, Coursera...',
              icon: Icons.business_outlined,
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CVDateField(
                    ctrl: _issueDate,
                    label: isAr ? 'تاريخ الإصدار' : 'Issue Date',
                    hint: 'MM/YYYY',
                    onChanged: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CVDateField(
                    ctrl: _expiryDate,
                    label: isAr ? 'تاريخ الانتهاء' : 'Expiry Date',
                    hint: isAr ? 'MM/YYYY أو لا تنتهي' : 'MM/YYYY or N/A',
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CVField(
              ctrl: _credId,
              label: isAr
                  ? 'رقم الاعتماد (اختياري)'
                  : 'Credential ID (optional)',
              hint: 'ABC123XYZ',
              icon: Icons.numbers_outlined,
              onChanged: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Language Row ─────────────────────────────────────────────
class _LangRow extends StatefulWidget {
  const _LangRow({
    super.key,
    required this.lang,
    required this.isAr,
    required this.ctrl,
  });

  final CVLanguageEntry lang;
  final bool isAr;
  final CVController ctrl;

  @override
  State<_LangRow> createState() => _LangRowState();
}

class _LangRowState extends State<_LangRow> {
  late final TextEditingController _langCtrl;
  late LanguageProficiency _proficiency;

  @override
  void initState() {
    super.initState();
    _langCtrl   = TextEditingController(text: widget.lang.language);
    _proficiency = widget.lang.proficiency;
  }

  void _save() {
    widget.ctrl.updateLanguage(
      CVLanguageEntry(
        id: widget.lang.id,
        language: _langCtrl.text.trim(),
        proficiency: _proficiency,
      ),
    );
  }

  @override
  void dispose() {
    _save();
    _langCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final profLabelsAr = [
      'أساسية',
      'محدودة',
      'احترافية',
      'احترافية كاملة',
      'اللغة الأم',
    ];
    final profLabelsEn = [
      'Elementary',
      'Limited',
      'Professional',
      'Full Professional',
      'Native',
    ];
    final profLabels = isAr ? profLabelsAr : profLabelsEn;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // اسم اللغة
            Expanded(
              child: TextField(
                controller: _langCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اللغة' : 'Language',
                  hintText: isAr ? 'العربية' : 'Arabic',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => _save(),
              ),
            ),
            const SizedBox(width: 8),

            // مستوى الإتقان
            Expanded(
              child: DropdownButtonFormField<LanguageProficiency>(
                value: _proficiency,
                decoration: InputDecoration(
                  labelText: isAr ? 'المستوى' : 'Proficiency',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                isExpanded: true,
                items: LanguageProficiency.values
                    .asMap()
                    .entries
                    .map((e) => DropdownMenuItem(
                          value: e.value,
                          child: Text(
                            profLabels[e.key],
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _proficiency = v!);
                  _save();
                },
              ),
            ),
            const SizedBox(width: 4),

            // حذف
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
              onPressed: () =>
                  widget.ctrl.removeLanguage(widget.lang.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
